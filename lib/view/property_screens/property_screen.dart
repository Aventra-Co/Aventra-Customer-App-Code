import 'dart:convert';
import 'dart:developer';
import 'dart:ui' as ui;
import '/controller/app_color.dart';
import '/controller/app_constant.dart';
import '/controller/app_font.dart';
import '/controller/app_image.dart';
import '/controller/app_language.dart';
import '/model/sort_model.dart';
import 'package:flutter/material.dart';
import '/view/property_screens/property_detail_screen.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../authentication/login_screen.dart';

class PropertyScreen extends StatefulWidget {
  final int propertyAdId;
  final int cityId;
  final String cityName;
  final String toOpen;
  const PropertyScreen(
      {super.key,
      required this.propertyAdId,
      required this.cityId,
      required this.cityName,
      required this.toOpen});

  @override
  State<PropertyScreen> createState() => _PropertyScreenState();
}

class _PropertyScreenState extends State<PropertyScreen> {
  String selectedView = AppLanguage.listtext[language];
  List<dynamic> properties = [];
  List<dynamic> searchProperties = [];
  int userId = 0;
  dynamic userDetails;
  bool isApiCalling = false;
  bool isLoading = true;
  int selectedPropTypeId = 0;
  String selectedSort = '';
  bool searchStatus = false;
  List<dynamic> amenities = [
    {"name": "WiFi"},
    {"name": "Coffee"},
    {"name": "AC"},
  ];
  bool isPetFriendlty = false;
  int maxAdult = 0;
  int maxChild = 0;
  DateTime? selectedDate;
  String date = '';
  var sendDate = "";
  String sendAddress = '';
  int sendPropertyId = 0;
  List<int> sendAmmenities = [];
  int isToggle = 2;

  //! MAP
  double longitudex = 77.4126;
  double latitudex = 23.2599;
  GoogleMapController? mapController;
  LatLng initialPosition = const LatLng(23.2599, 77.4126);
  List<dynamic> locationsList = [];
  List<Map<String, dynamic>> beaches = [];

  Set<Marker> get beachMarkers {
    return beaches.asMap().entries.map((entry) {
      if (widget.toOpen.isNotEmpty) {
        // Highlight the selected beach marker differently
        if (entry.value['name'] == widget.toOpen) {
          return Marker(
            markerId: MarkerId('beach_${entry.key}'),
            position: entry.value['position'],
            infoWindow: InfoWindow(title: entry.value['name']),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure), // Different color
          );
        }
      }
      return Marker(
        markerId: MarkerId('beach_${entry.key}'),
        position: entry.value['position'],
        infoWindow: InfoWindow(title: entry.value['name']),
      );
    }).toSet();
  }

  // ── Search ────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> propertyTypeList = [];

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userDetails = prefs.getString("userDetails");
    setState(() => isApiCalling = true);
    if (userDetails != null) {
      dynamic data = json.decode(userDetails);
      userId = data['user_id'];
    }
    isApiCalling = false;
    getAllAdvertisementApi(userId, widget.propertyAdId, "", "", "", "", "");
    getPickUpsApi(userId, widget.propertyAdId);
    propertyTypesApiCall(userId);
    getAmmenitiesApi(userId);
    setState(() {});
  }

  Future<void> getAllAdvertisementApi(userId, propTypeId, String ammenitiesIds,
      maxAdult, maxChild, String sendDate, String address) async {
    setState(() {
      isApiCalling = true;
    });
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_advertisement_city_property_type?user_id=$userId&property_type=$propTypeId&city_id=${widget.cityId}&amenities_id=$ammenitiesIds&max_adult=$maxAdult&max_child=$maxChild&checkin_date=$sendDate&pet_friendly=$isToggle&address=$address");
    print("url $url");
    String token = AppConstant.token;
    Map<String, String> headers = {'Authorization': 'Bearer $token'};
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        if (res['success'] == true) {
          var item = res['favourite_arr'];
          properties = (item != "NA") ? item : [];
          searchProperties = (item != "NA") ? item : [];
          _sortProperties(notify: false);
          setState(() => isApiCalling = false);
        } else {
          properties = [];
          searchProperties = [];
          setState(() => isApiCalling = false);
        }
      } else {
        properties = [];
        searchProperties = [];
        setState(() => isApiCalling = false);
      }
    } catch (e) {
      properties = [];
      searchProperties = [];
      setState(() => isApiCalling = false);
    }
  }

  String get _sortRatingHighToLow =>
      "${AppLanguage.ratingText[language]}: ${AppLanguage.highToLowText[language]}";
  String get _sortCostHighToLow =>
      "${AppLanguage.costText[language]}: ${AppLanguage.highToLowText[language]}";
  String get _sortCostLowToHigh =>
      "${AppLanguage.costText[language]}: ${AppLanguage.lowToHighText[language]}";

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(',', '').trim();
      return double.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  void _sortProperties({bool notify = true}) {
    if (selectedSort.isEmpty || properties.isEmpty) return;

    if (selectedSort == _sortRatingHighToLow) {
      properties.sort((a, b) {
        final bRating = _toDouble(b['rating']);
        final aRating = _toDouble(a['rating']);
        return bRating.compareTo(aRating);
      });
    } else if (selectedSort == _sortCostHighToLow) {
      properties.sort((a, b) {
        final bPrice = _toDouble(b['starting_price']);
        final aPrice = _toDouble(a['starting_price']);
        return bPrice.compareTo(aPrice);
      });
    } else if (selectedSort == _sortCostLowToHigh) {
      properties.sort((a, b) {
        final aPrice = _toDouble(a['starting_price']);
        final bPrice = _toDouble(b['starting_price']);
        return aPrice.compareTo(bPrice);
      });
    }

    if (notify) {
      setState(() {});
    }
  }

  void _applySort(String sort) {
    setState(() {
      selectedSort = sort;
      _sortProperties(notify: false);
    });
  }

  deeplinkingProp(BuildContext context, propertyAdId) async {
    var shareUrl =
        "${AppConfigProvider.apiUrl}deepLink?link=aventra://property_ad_id/${Uri.encodeComponent(propertyAdId.toString())}/entity/${Uri.encodeComponent(1.toString())}";
    final RenderBox box = context.findRenderObject() as RenderBox;
    await Share.share("Aventra App! $shareUrl",
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
  }

  //------------------------PropType API CALL--------------------------------//
  Future<void> propertyTypesApiCall(
    userId,
  ) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_all_property_type?user_id=$userId");
    print("url $url");
    setState(() {
      isLoading = true;
    });
    String token = AppConstant.token;

    if (token.isEmpty) {
      print("Token is missing!");
      // return;
    }

    Map<String, String> headers = {
      'Authorization': 'Bearer $token', // Use 'Bearer' if required
    };

    print("headers $headers");

    try {
      final response = await http.get(url, headers: headers);
      print("response $response");

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print("res $res");

        if (res['success'] == true) {
          var item = res['data'];
          propertyTypeList = (item != "NA") ? item : [];

          setState(() {
            isLoading = false;
          });
        } else {
          propertyTypeList = [];
          setState(() {
            isLoading = false;
          });
          // ignore: use_build_context_synchronously
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          }
        }
      } else {
        propertyTypeList = [];
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      propertyTypeList = [];
      setState(() {
        isLoading = false;
      });
    }
  }

//=============add favorite trip API================//
  Future<void> addFavoriteApiCall(index, tripId, int entity) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}add_favourite");
    setState(() {
      isApiCalling = false;
    });
    String token = AppConstant.token;
    try {
      var headers = {
        'Authorization': 'Bearer $token',
      };

      var body = {
        'user_id': userId.toString(),
        'trip_id': tripId.toString(),
        'entity_type': entity.toString(),
      };

      log("body==== $body $index");

      http.Response response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      var res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (res['success'] == true) {
          setState(() {
            properties[index]['favourite_status'] = res['favourite_status'];
          });

          SnackBarToastMessage.showSnackBar(context, res['message'][language]);
          setState(() {
            isApiCalling = false;
          });
        } else {
          setState(() {
            isApiCalling = false;
          });
          // ignore: use_build_context_synchronously
          SnackBarToastMessage.showSnackBar(context, res['message'][language]);
          if (res['active_flag'] == 0) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Login()));
          }
        }
      } else {
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (e) {
      setState(() {
        isApiCalling = false;
      });
    }
  }

  //---------------------SEARCH FUNCTION Trips--------------------///
  searchProperty(String query) {
    var results1 = searchProperties
        .where((value) => value['property_name_english']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    properties = [];

    properties = results1;

    setState(() {});
  }

  //=============================GET Pickups===================================//
  Future<void> getPickUpsApi(userId, int propertyId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_all_property_pickup_points?user_id=$userId&property_type_id=$propertyId&city_id=${widget.cityId}");
    print("URL: $url");

    String token = AppConstant.token;

    if (token.isEmpty) {}

    Map<String, String> headers = {
      'Authorization': 'Bearer $token', // Use 'Bearer' if required
    };

    setState(() {
      isApiCalling = true;
    });

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);

        if (res['success'] == true) {
          var item = res['data'];
          locationsList = (item != "NA") ? item : [];

          // pickUpList = locationsList;
          if (locationsList.isNotEmpty) {
            beaches = convertApiDataToBeaches(locationsList);
          }
          setState(() {
            isApiCalling = false;
          });
        } else {
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }
          setState(() {
            isApiCalling = false;
          });
        }
      } else {
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (e) {
      setState(() {
        isApiCalling = false;
      });
    }
  }

  //=============================GET Ammenities===================================//
  Future<void> getAmmenitiesApi(userId) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}get_all_amenities_list");
    print("URL: $url");

    String token = AppConstant.token;

    if (token.isEmpty) {}

    Map<String, String> headers = {
      'Authorization': 'Bearer $token', // Use 'Bearer' if required
    };

    setState(() {
      isApiCalling = true;
    });

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);

        if (res['success'] == true) {
          var item = res['data'];
          amenities = (item != "NA") ? item : [];
          setState(() {
            isApiCalling = false;
          });
        } else {
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }
          setState(() {
            isApiCalling = false;
          });
        }
      } else {
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (e) {
      setState(() {
        isApiCalling = false;
      });
    }
  }

  LatLng _getInitialTarget() {
    if (widget.toOpen.isNotEmpty) {
      // Find the beach matching toOpen name
      final selectedBeach = beaches.firstWhere(
        (beach) => beach['name'] == widget.toOpen,
        orElse: () => beaches[0],
      );
      return selectedBeach['position'];
    }
    return beaches[0]['position']; // Default to first beach
  }

  List<Map<String, dynamic>> convertApiDataToBeaches(List<dynamic> apiData) {
    return apiData.map((item) {
      final positionString = item['position']
          .replaceAll("LatLng(", "")
          .replaceAll(")", "")
          .split(',');

      final double latitude = double.parse(positionString[0].trim());
      final double longitude = double.parse(positionString[1].trim());

      return {
        "name": item['name'],
        "position": LatLng(latitude, longitude),
      };
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
        inAsyncCall: isApiCalling,
        opacity: 0.5,
        child: _buildUIScreen(context));
  }

  Widget _buildUIScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;

    double screenWidth = MediaQuery.of(context).size.width;
    final topInset = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Directionality(
          textDirection:
              language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: Scaffold(
            backgroundColor: AppColor.secondaryColor,
            extendBodyBehindAppBar: true,
            body: Column(
              children: [
                // Header
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(AppImage.propertyHomeImage),

                    // Back and Search buttons
                    Positioned(
                      top: topInset + 10,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: size.width * 0.09,
                            height: size.width * 0.09,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Transform.rotate(
                                  angle: language == 1 ? 3.1416 : 0,
                                  child: Image.asset(AppImage.bgBackArrow)),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          SizedBox(
                            width: size.width * 0.1,
                            height: size.width * 0.1,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Image.asset(AppImage.searchicon2),
                              onPressed: () {
                                setState(() {
                                  searchStatus = !searchStatus;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (searchStatus)
                      Positioned(
                        left: screenWidth * 20 / 100,
                        top: screenWidth * 12 / 100,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 60 / 100,
                          height: MediaQuery.of(context).size.height * 6 / 100,
                          child: TextFormField(
                            readOnly: false,
                            style: const TextStyle(
                                color: AppColor.secondaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppFont.fontFamily),
                            textAlignVertical: TextAlignVertical.center,
                            keyboardType: TextInputType.name,
                            //controller: controller,
                            onChanged: (value) {
                              setState(() {
                                if (value.isNotEmpty) {
                                  searchProperty(value);
                                } else {
                                  properties = searchProperties;
                                }
                              });
                            },
                            decoration: InputDecoration(
                              prefixIcon: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    child: Image.asset(
                                      AppImage.searchIcon1,
                                      color: AppColor.secondaryColor,
                                      height: screenWidth > 600
                                          ? MediaQuery.of(context).size.width *
                                              3 /
                                              100
                                          : MediaQuery.of(context).size.width *
                                              5 /
                                              100,
                                      width: screenWidth > 600
                                          ? MediaQuery.of(context).size.width *
                                              3 /
                                              100
                                          : MediaQuery.of(context).size.width *
                                              5 /
                                              100,
                                    ),
                                  ),
                                ],
                              ),
                              border: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColor.secondaryColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25)),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColor.secondaryColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColor.secondaryColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 15),
                              filled: false,
                              counterText: '',
                              hintText: AppLanguage.searchInputText[language],
                              hintStyle: const TextStyle(
                                  color: AppColor.secondaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: AppFont.fontFamily),
                            ),
                          ),
                        ),
                      ),

                    // Property title
                    Positioned(
                      bottom: 38,
                      left: language == 0 ? 24 : null,
                      right: language == 1 ? 24 : null,
                      child: Text(
                        widget.cityName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 25,
                          color: AppColor.secondaryColor,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppFont.fontFamily,
                        ),
                      ),
                    ),

                    // View toggle buttons
                    Positioned(
                      bottom: -22,
                      left: 50,
                      right: 50,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColor.secondaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColor.primaryColor.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                child: _viewButton(
                                    AppLanguage.listtext[language],
                                    AppImage.activelistImageIcon,
                                    AppImage.deactivelistImageIcon)),
                            Expanded(
                                child: _viewButton(
                                    AppLanguage.gridtext[language],
                                    AppImage.activegridImageIcon,
                                    AppImage.deactivegridImageIcon)),
                            Expanded(
                                child: _viewButton(
                                    AppLanguage.maptext[language],
                                    AppImage.activemapImageIcon,
                                    AppImage.deactivemapImageIcon)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 45),
                // Property list (only list/grid scrolls)
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewButton(String label, String activeImage, String inactiveImage) {
    final isSelected = selectedView == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedView = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              isSelected ? activeImage : inactiveImage,
              width: 18,
              height: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: AppFont.fontFamily,
                color: isSelected
                    ? AppColor.secondaryColor
                    : AppColor.textLightColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _propertyCard(Map<String, dynamic> property, int index, screenWidth) {
    final size = MediaQuery.of(context).size;
    final double iconSize = size.width * 0.07;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailsScreen(
              propertyAdId: property['property_ad_id'],
            ),
          ),
        );
      },
      child: Container(
        // margin: const EdgeInsets.only(bottom: 16),
        width: MediaQuery.of(context).size.width * 90 / 100,
        height: MediaQuery.of(context).size.height * 20 / 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(
                "${AppConfigProvider.imageURL}${property['image_path']}"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.2),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            // Favorite button
            Positioned(
              top: 11,
              right: language == 0 ? 42 : null,
              left: language == 1 ? 42 : null,
              child: GestureDetector(
                onTap: () {
                  addFavoriteApiCall(index, property['property_ad_id'], 1);
                },
                child: Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: const BoxDecoration(
                    color: AppColor.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    property['favourite_status'] == 1
                        ? AppImage.removeFavouriteIcon
                        : AppImage.addFavouriteIcons,
                    width: MediaQuery.of(context).size.width * 7 / 100,
                    height: MediaQuery.of(context).size.width * 7 / 100,
                  ),
                ),
              ),
            ),

            Positioned(
              top: 11,
              left: language == 1 ? 12 : null,
              right: language == 0 ? 12 : null,
              child: GestureDetector(
                onTap: () {
                  deeplinkingProp(context, property['property_ad_id']);
                },
                child: Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: const BoxDecoration(
                    color: AppColor.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    AppImage.favShareICon,
                    width: MediaQuery.of(context).size.width * 7 / 100,
                    height: MediaQuery.of(context).size.width * 7 / 100,
                  ),
                ),
              ),
            ),

            // Property info
            Positioned(
              bottom: 8,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 80 / 100,
                    child: Text(
                      property['property_name_english'][0] ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFont.fontFamily,
                        color: AppColor.secondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 80 / 100,
                    child: Text(
                      "${AppLanguage.cityText[language]} \u2022 ${property['city_name'][language] ?? ""}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFont.fontFamily,
                        color: AppColor.secondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 80 / 100,
                    child: Text(
                      "${AppLanguage.propertyTypeText[language]} \u2022 ${property['property_type_name'][language] ?? ""}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFont.fontFamily,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (property['rating'] != 0)
                        Container(
                          width: screenWidth > 600
                              ? MediaQuery.of(context).size.width * 10 / 100
                              : MediaQuery.of(context).size.width * 14 / 100,
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 2),
                          decoration: BoxDecoration(
                              color: AppColor.secondaryColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(25)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: screenWidth > 600
                                    ? MediaQuery.of(context).size.width *
                                        2 /
                                        100
                                    : MediaQuery.of(context).size.width *
                                        4 /
                                        100,
                                height: screenWidth > 600
                                    ? MediaQuery.of(context).size.width *
                                        2 /
                                        100
                                    : MediaQuery.of(context).size.width *
                                        4 /
                                        100,
                                child: Image.asset(AppImage.ratingIcon),
                              ),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      1 /
                                      100),
                              Text(
                                property['rating'].toString(),
                                style: const TextStyle(
                                    color: AppColor.secondaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: AppFont.fontFamily),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 2 / 100),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 5),
                        decoration: BoxDecoration(
                          color: AppColor.secondaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          "${((property['max_adult'] ?? 0) + (property['max_child'] ?? 0))} ${AppLanguage.guestsext[language]}",
                          style: const TextStyle(
                              color: AppColor.secondaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: language == 1 ? 0 : null,
              right: language == 0 ? 0 : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColor.themeColor,
                    borderRadius: language == 1
                        ? const BorderRadius.only(
                            bottomLeft: Radius.circular(17),
                            topRight: Radius.circular(4))
                        : const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            bottomRight: Radius.circular(17))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppLanguage.startingFromText[language],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFont.fontFamily,
                        color: AppColor.secondaryColor,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text:
                                "${property['starting_price']?.toString() ?? 0} KWD",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily,
                              color: AppColor.secondaryColor,
                            ),
                          ),
                          // const TextSpan(
                          //   text: '/Day',
                          //   style: TextStyle(
                          //     fontSize: 10,
                          //     fontWeight: FontWeight.w400,
                          //     fontFamily: AppFont.fontFamily,
                          //     color: AppColor.secondaryColor,
                          //   ),
                          // ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

            if (property['discount_percentage'] != null &&
                property['discount_percentage'] > 0) ...[
              Positioned(
                top: language == 0 ? -30 : -30,
                left: language == 0 ? -22 : null,
                right: language == 1 ? -22 : null,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 30 / 100,
                  height: MediaQuery.of(context).size.height * 15 / 100,
                  child: Image.asset(language == 0
                      ? AppImage.discountStrip
                      : AppImage.discountStripInverted),
                ),
              ),
              Positioned(
                top: language == 0 ? 15 : 13,
                left: language == 0 ? -25 : null,
                right: language == 1 ? -27 : null,
                child: Transform.rotate(
                  angle: language == 0 ? -.65 : .65,
                  child: Container(
                    alignment: Alignment.center,
                    // color: Colors.red,
                    width: MediaQuery.of(context).size.width * 30 / 100,
                    child: Text(
                      "${property['discount_percentage']}% ${AppLanguage.offText[language]}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: AppFont.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColor.secondaryColor),
                    ),
                  ),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  // Grid Card
  Widget _propertyGridCard(
      Map<String, dynamic> property, int index, screenWidth) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailsScreen(
              propertyAdId: property['property_ad_id'],
            ),
          ),
        );
      },
      child: Stack(
        children: [
          // Gradient overlay
          Container(
            width: MediaQuery.of(context).size.width * 44 / 100,
            height: MediaQuery.of(context).size.height * 25 / 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(
                    "${AppConfigProvider.imageURL}${property['image_path']}"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.2),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          // Price badge top-left
          Positioned(
            top: 0,
            left: language == 0 ? 0 : null,
            right: language == 1 ? 0 : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColor.themeColor,
                  borderRadius: language == 1
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          topRight: Radius.circular(17))
                      : const BorderRadius.only(
                          topLeft: Radius.circular(17),
                          bottomRight: Radius.circular(4))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLanguage.startingFromText[language],
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFont.fontFamily,
                          color: Colors.white)),
                  Text("${property['starting_price']?.toString() ?? 0} KWD",
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFont.fontFamily,
                          color: Colors.white)),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  property['property_name_english'][0] ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppFont.fontFamily,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  "${AppLanguage.cityText[language]} \u2022 ${property['city_name'][language] ?? ""}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFont.fontFamily,
                    color: AppColor.white,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  "${AppLanguage.propertyTypeText[language]} \u2022 ${property['property_type_name'][language] ?? ""}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFont.fontFamily,
                    color: AppColor.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (property['rating'] != 0)
                      Container(
                        width: screenWidth > 600
                            ? MediaQuery.of(context).size.width * 10 / 100
                            : MediaQuery.of(context).size.width * 11 / 100,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 2),
                        decoration: BoxDecoration(
                            color: AppColor.secondaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(25)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: screenWidth > 600
                                  ? MediaQuery.of(context).size.width * 2 / 100
                                  : MediaQuery.of(context).size.width * 3 / 100,
                              height: screenWidth > 600
                                  ? MediaQuery.of(context).size.width * 2 / 100
                                  : MediaQuery.of(context).size.width * 3 / 100,
                              child: Image.asset(AppImage.ratingIcon),
                            ),
                            SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    1 /
                                    100),
                            Text(
                              property['rating'].toString(),
                              style: const TextStyle(
                                  color: AppColor.secondaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppFont.fontFamily),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 1 / 100),
                    Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width * 15 / 100,
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 5),
                      decoration: BoxDecoration(
                        color: AppColor.secondaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        "${((property['max_adult'] ?? 0) + (property['max_child'] ?? 0))} ${AppLanguage.guestsext[language]}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColor.secondaryColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        addFavoriteApiCall(
                            index, property['property_ad_id'], 1);
                      },
                      child: Image.asset(
                        (property['favourite_status'] ?? 0) == 1
                            ? AppImage.removeFavouriteIcon
                            : AppImage.addFavouriteIcons,
                        width: size.width * 0.06,
                        height: size.width * 0.06,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 1 / 100,
                    ),
                    GestureDetector(
                      onTap: () {
                        deeplinkingProp(context, property['property_ad_id']);
                      },
                      child: Image.asset(
                        AppImage.favShareICon,
                        width: size.width * 0.06,
                        height: size.width * 0.06,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Map View
  Widget _buildMapView() {
    return (locationsList.isNotEmpty)
        ? Stack(
            children: [
              ClipRRect(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  width: MediaQuery.of(context).size.width,
                  child: GoogleMap(
                    mapToolbarEnabled: false,
                    zoomGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: true,
                    initialCameraPosition: CameraPosition(
                      target: _getInitialTarget(),
                      zoom: 10.0,
                    ),
                    onMapCreated: (controller) {
                      setState(() {
                        mapController = controller;
                      });
                    },
                    markers: beachMarkers,
                  ),
                ),
              ),
            ],
          )
        : Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 16 / 100,
              ),
              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width * 90 / 100,
                child: Text(
                  AppLanguage.noLocationText[language],
                  style: const TextStyle(
                      fontFamily: AppFont.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColor.primaryColor),
                ),
              ),
            ],
          );
  }

  Widget _buildContent() {
    final size = MediaQuery.of(context).size;
    double screenWidth = MediaQuery.of(context).size.width;
    if (selectedView == AppLanguage.maptext[language]) {
      return _buildMapView();
    }

    return Column(
      children: [
        // Available count, Filter & Sort
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppLanguage.availabletext[language]}(${properties.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFont.fontFamily,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // showFilterModal(context, screenWidth);
                      filterBottomSheet(context, screenWidth);
                    },
                    child: Row(
                      children: [
                        Image.asset(
                          AppImage.filterSortImage,
                          width: size.width * 0.03,
                          height: size.height * 0.03,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLanguage.filtertext[language],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 15,
                    width: 1,
                    color: AppColor.primaryColor,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  GestureDetector(
                    onTap: () {
                      showSortBottomSheet(
                        context,
                        selectedSort: selectedSort,
                        onSelected: _applySort,
                      );
                    },
                    child: Row(
                      children: [
                        Image.asset(
                          AppImage.filterSortImage,
                          width: size.width * 0.03,
                          height: size.height * 0.03,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLanguage.sorttext[language],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: properties.isEmpty
              ? Column(
                  children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 10 / 100),
                    Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width * 90 / 100,
                      child: Text(
                        AppLanguage.noPropertiesText[language],
                        style: const TextStyle(
                            fontFamily: AppFont.fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColor.primaryColor),
                      ),
                    ),
                  ],
                )
              : selectedView == AppLanguage.gridtext[language]
                  ? GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: properties.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (context, index) {
                        return _propertyGridCard(
                            properties[index], index, screenWidth);
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      itemCount: properties.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            _propertyCard(
                                properties[index], index, screenWidth),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100,
                            ),
                          ],
                        );
                      },
                    ),
        ),
        SizedBox(height: size.height * 0.02),
      ],
    );
  }

  apply() {
    getAllAdvertisementApi(
        userId,
        sendPropertyId == 0 ? widget.propertyAdId : sendPropertyId,
        sendAmmenities.join(","),
        maxAdult == 0 ? "" : maxAdult,
        maxChild == 0 ? "" : maxChild,
        sendDate,
        sendAddress);
  }

  reset() {
    setState(() {
      sendAddress = "";
      selectedDate;
      date = '';
      sendDate = "";
      sendPropertyId = 0;
      sendAmmenities.clear();
      isToggle = 2;
      maxAdult = 0;
      maxChild = 0;
    });
    getAllAdvertisementApi(userId, widget.propertyAdId, "", "", "", "", "");
  }

  void filterBottomSheet(BuildContext context, screenWidth) {
    final size = MediaQuery.of(context).size;
    showModalBottomSheet<void>(
      isScrollControlled: true,
      constraints: BoxConstraints.expand(
          width: screenWidth,
          height: MediaQuery.of(context).size.height * 95 / 100),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            //==========================DATE FUNCTION=======================//
            Future<void> _selectDate(BuildContext context) async {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final DateTime initialDate =
                  (selectedDate != null && !selectedDate!.isBefore(today))
                      ? selectedDate!
                      : today;
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: today,
                lastDate: DateTime(2100),
              );
              if (picked != null && picked != selectedDate) {
                var sendDate1 = DateFormat('yyyy-MM-dd').format(picked);
                var showDate = DateFormat('dd/MM/yyyy').format(picked);
                setState(() {
                  date = showDate.toString();

                  sendDate = sendDate1;
                });
              }
            }

            return Directionality(
              textDirection:
                  language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              child: Container(
                height: MediaQuery.of(context).size.height * 95 / 100,
                width: MediaQuery.of(context).size.width * 100 / 100,
                decoration: const BoxDecoration(
                  color: AppColor.secondaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 2 / 100,
                    ),
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            //reset cancel
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Row(
                                children: [
                                  //cancel image
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          6 /
                                          100,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              6 /
                                              100,
                                      child: Image.asset(
                                        AppImage.filterCancel,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),

                                  //APPLy
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      apply();
                                    },
                                    child: Text(
                                      AppLanguage.applyText[language],
                                      style: const TextStyle(
                                          fontFamily: AppFont.fontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColor.themeColor),
                                    ),
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        4 /
                                        100,
                                    alignment: Alignment.center,
                                    child: const Text(
                                      "|",
                                      style: TextStyle(
                                          fontFamily: AppFont.fontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColor.themeColor),
                                    ),
                                  ),

                                  //reset
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      reset();
                                    },
                                    child: Text(
                                      AppLanguage.resetText[language],
                                      style: const TextStyle(
                                          fontFamily: AppFont.fontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColor.themeColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100,
                            ),

                            //Date text
                            Container(
                              alignment: language == 0
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Text(
                                AppLanguage.dateText[language],
                                style: const TextStyle(
                                    fontFamily: AppFont.fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.primaryColor),
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100,
                            ),

                            //-----------DOB field---------------
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              height:
                                  MediaQuery.of(context).size.height * 6 / 100,
                              child: TextFormField(
                                readOnly: true,
                                onTap: () => _selectDate(context),
                                decoration: InputDecoration(
                                  suffixIcon: Image.asset(
                                    AppImage.calenderIcon,
                                    scale: 3.5,
                                  ),
                                  hintText: date != ''
                                      ? date.replaceAll('-', '/')
                                      : AppLanguage.chooseDateText[language],
                                  hintStyle: const TextStyle(
                                      color: AppColor.themeColor,
                                      fontFamily: AppFont.fontFamily,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14),
                                  border: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: AppColor.textColor),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(16)),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: AppColor.textColor),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(16)),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: AppColor.textColor),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(16)),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100),

                            //pickup text
                            if (locationsList.isNotEmpty)
                              Container(
                                alignment: language == 0
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                child: Text(
                                  AppLanguage.locationText[language],
                                  style: const TextStyle(
                                      fontFamily: AppFont.fontFamily,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.primaryColor),
                                ),
                              ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100,
                            ),

                            //pickup list
                            Container(
                              alignment: language == 0
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 15,
                                runSpacing: 10,
                                children: List.generate(locationsList.length,
                                    (index) {
                                  return (GestureDetector(
                                    onTap: () {
                                      if (sendAddress ==
                                          locationsList[index]["name"]) {
                                        setState(() {
                                          sendAddress = "";
                                        });
                                        log(sendAddress);
                                      } else {
                                        setState(() {
                                          sendAddress =
                                              locationsList[index]["name"];
                                        });
                                        log(sendAddress);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                          color: sendAddress ==
                                                  locationsList[index]["name"]
                                              ? AppColor.themeColor
                                              : AppColor.secondaryColor,
                                          border: Border.all(
                                              width: 1,
                                              color: sendAddress ==
                                                      locationsList[index]
                                                          ["name"]
                                                  ? AppColor.themeColor
                                                  : AppColor.primaryColor),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 12.0),
                                        child: Text(
                                          locationsList[index]['name'] ?? "",
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                              color: sendAddress ==
                                                      locationsList[index]
                                                          ["name"]
                                                  ? AppColor.secondaryColor
                                                  : AppColor.themeColor,
                                              fontFamily: AppFont.fontFamily,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ));
                                }),
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 3 / 100,
                            ),

                            //property type text
                            if (propertyTypeList.isNotEmpty)
                              Container(
                                alignment: language == 0
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                child: Text(
                                  AppLanguage.propertyTypeText[language],
                                  style: const TextStyle(
                                      fontFamily: AppFont.fontFamily,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.primaryColor),
                                ),
                              ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100,
                            ),

                            //property type list
                            Container(
                              alignment: language == 0
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 15,
                                runSpacing: 10,
                                children: List.generate(propertyTypeList.length,
                                    (index) {
                                  return (GestureDetector(
                                    onTap: () {
                                      if (sendPropertyId ==
                                          propertyTypeList[index]
                                              ['property_type_id']) {
                                        setState(() {
                                          sendPropertyId = 0;
                                        });
                                        log("$sendPropertyId");
                                      } else {
                                        setState(() {
                                          sendPropertyId =
                                              propertyTypeList[index]
                                                  ['property_type_id'];
                                        });
                                        log("$sendPropertyId");
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                          color: sendPropertyId ==
                                                  propertyTypeList[index]
                                                      ['property_type_id']
                                              ? AppColor.themeColor
                                              : AppColor.secondaryColor,
                                          border: Border.all(
                                              width: 1,
                                              color: sendPropertyId ==
                                                      propertyTypeList[index]
                                                          ['property_type_id']
                                                  ? AppColor.themeColor
                                                  : AppColor.primaryColor),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 12.0),
                                        child: Text(
                                          propertyTypeList[index]
                                                      ['property_type_label']
                                                  [language] ??
                                              "",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: sendPropertyId ==
                                                      propertyTypeList[index]
                                                          ['property_type_id']
                                                  ? AppColor.secondaryColor
                                                  : AppColor.themeColor,
                                              fontFamily: AppFont.fontFamily,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ));
                                }),
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 3 / 100,
                            ),

                            //ammenities text
                            if (amenities.isNotEmpty)
                              Container(
                                alignment: language == 0
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                child: Text(
                                  AppLanguage.whatPropertyOfferText[language],
                                  style: const TextStyle(
                                      fontFamily: AppFont.fontFamily,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.primaryColor),
                                ),
                              ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100,
                            ),

                            //ammenities list
                            Container(
                              alignment: language == 0
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 15,
                                runSpacing: 10,
                                children:
                                    List.generate(amenities.length, (index) {
                                  return (GestureDetector(
                                    onTap: () {
                                      if (sendAmmenities.contains(
                                          amenities[index]['amenity_id'])) {
                                        setState(() {
                                          sendAmmenities.remove(
                                              amenities[index]['amenity_id']);
                                        });
                                      } else {
                                        setState(() {
                                          sendAmmenities.add(
                                              amenities[index]['amenity_id']);
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                          color: sendAmmenities.contains(
                                                  amenities[index]
                                                      ['amenity_id'])
                                              ? AppColor.themeColor
                                              : AppColor.secondaryColor,
                                          border: Border.all(
                                              width: 1,
                                              color: sendAmmenities.contains(
                                                      amenities[index]
                                                          ['amenity_id'])
                                                  ? AppColor.themeColor
                                                  : AppColor.primaryColor),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 12.0),
                                        child: Text(
                                          amenities[index]['amenity_name'] ??
                                              "",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: sendAmmenities.contains(
                                                      amenities[index]
                                                          ['amenity_id'])
                                                  ? AppColor.secondaryColor
                                                  : AppColor.themeColor,
                                              fontFamily: AppFont.fontFamily,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ));
                                }),
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 3 / 100,
                            ),

                            //ammenities text
                            if (amenities.isNotEmpty)
                              Container(
                                alignment: language == 0
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                child: Text(
                                  AppLanguage.petFriendlyText[language],
                                  style: const TextStyle(
                                      fontFamily: AppFont.fontFamily,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.primaryColor),
                                ),
                              ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 3 / 100,
                            ),

                            //! Pet Friendly
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isToggle == 1) {
                                          isToggle = 2;
                                        } else {
                                          isToggle = 1;
                                        }
                                      });
                                    },
                                    child: SizedBox(
                                      width: size.width * 8 / 100,
                                      height: size.width * 8 / 100,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Image.asset(
                                          isToggle == 1
                                              ? AppImage.activeRadio
                                              : AppImage.deactiveRadio,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: size.width * 0.02),

                                  /// YES
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isToggle == 1) {
                                          isToggle = 2;
                                        } else {
                                          isToggle = 1;
                                        }
                                      });
                                    },
                                    child: Text(
                                      AppLanguage.yesText[language],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: AppFont.fontFamily,
                                        fontWeight: FontWeight.w400,
                                        color: AppColor.themeColor,
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: size.width * 0.1),

                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isToggle == 0) {
                                          isToggle = 2;
                                        } else {
                                          isToggle = 0;
                                        }
                                      });
                                    },
                                    child: SizedBox(
                                      width: size.width * 8 / 100,
                                      height: size.width * 8 / 100,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Image.asset(
                                          isToggle == 0
                                              ? AppImage.activeRadio
                                              : AppImage.deactiveRadio,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: size.width * 0.02),

                                  /// NO
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isToggle == 0) {
                                          isToggle = 2;
                                        } else {
                                          isToggle = 0;
                                        }
                                      });
                                    },
                                    child: Text(
                                      AppLanguage.noText[language],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: AppFont.fontFamily,
                                        fontWeight: FontWeight.w400,
                                        color: AppColor.themeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 3 / 100,
                            ),

                            //! Adult Child Counter
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Column(
                                children: [
                                  Container(
                                    alignment: language == 0
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    width: MediaQuery.of(context).size.width *
                                        90 /
                                        100,
                                    child: Text(
                                      AppLanguage
                                          .numberofMaxPeopleText[language],
                                      style: const TextStyle(
                                          fontFamily: AppFont.fontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.primaryColor),
                                    ),
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        2 /
                                        100,
                                  ),
                                  _guestCounterRow(context, maxAdult, 100000,
                                      label: AppLanguage.adultText[language],
                                      count: maxAdult, onDecrement: () {
                                    if (maxAdult > 0) {
                                      setState(() => maxAdult--);
                                    }
                                  }, onIncrement: () {
                                    if (maxAdult < 100000) {
                                      setState(() => maxAdult++);
                                    }
                                  }),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        2 /
                                        100,
                                  ),
                                  _guestCounterRow(context, maxChild, 100000,
                                      label: AppLanguage.childText[language],
                                      count: maxChild, onDecrement: () {
                                    if (maxChild > 0) {
                                      setState(() => maxChild--);
                                    }
                                  }, onIncrement: () {
                                    if (maxChild < 100000) {
                                      setState(() => maxChild++);
                                    }
                                  }),
                                ],
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 3 / 100,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _guestCounterRow(BuildContext context, int value, int max,
      {required String label,
      required int count,
      required VoidCallback onDecrement,
      required VoidCallback onIncrement}) {
    final size = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                fontFamily: AppFont.fontFamily,
                color: AppColor.themeColor)),
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: AppColor.primaryColor, width: 1),
              borderRadius: BorderRadius.circular(5)),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onDecrement,
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Image.asset(value == 0
                          ? AppImage.disableDecreamentIcon
                          : AppImage.decreamentIcon)),
                ),
                SizedBox(width: size.width * 0.04),
                Text('$count',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFont.fontFamily,
                        color: Colors.black)),
                SizedBox(width: size.width * 0.04),
                GestureDetector(
                  onTap: onIncrement,
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Image.asset(max == value
                          ? AppImage.disableIncreamentIcon
                          : AppImage.increamentIcon)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
