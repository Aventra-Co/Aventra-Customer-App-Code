import 'dart:convert';
import 'dart:developer';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_shimmers.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../authentication/login_screen.dart';
import 'privateBookingFlow/private_trip_details.dart';
import 'publicBookingFlow/public_trip_details.dart';
import 'dart:ui' as ui;

class Beaches extends StatefulWidget {
  static String routeName = './Beaches';
  final String activityId;
  final String destinationId;
  final int status;
  final String toOpen;
  const Beaches(
      {super.key,
      required this.status,
      required this.activityId,
      required this.destinationId,
      required this.toOpen});

  @override
  State<Beaches> createState() => _BeachesState();
}

class _BeachesState extends State<Beaches> {
  int selectItemView = 1;
  bool searchStatus = false;
  List oceanExploreList = [];
  List searchOceanExploreList = [];
  int selectedFilterOption = -1;
  List sortList = [
    {
      "id": 0,
      "text": "Rating: High To Low",
    },
    {
      "id": 1,
      "text": "Cost : High To Low",
    },
  ];
  List<dynamic> pickUpList = [];
  List<dynamic> destinationList = [];
  List<dynamic> advertisementList = [
    {"id": 1, "title": AppLanguage.privateText[language]},
    {"id": 2, "title": AppLanguage.publicText[language]}
  ];
  List<dynamic> addOnsList = [];
  List<dynamic> activityList = [];
  int advertisementId = 0;
  DateTime? selectedDate;
  String date = '';
  var sendDate = "";
  bool isApiCalling = false;
  bool isLoading = true;
  String destination = "";
  dynamic rating;
  List<int> sendAddons = [];
  String sendPickUp = "";
  List<int> sendActivity = [];
  double longitudex = 77.4126;
  double latitudex = 23.2599;
  GoogleMapController? mapController;
  LatLng initialPosition = const LatLng(23.2599, 77.4126);
  List<dynamic> locationsList = [];
  List<Map<String, dynamic>> beaches = [];
  String selectedToOpen = "";
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

  @override
  void initState() {
    super.initState();
    selectItemView = widget.status == 1 ? 3 : 1;
    log("${widget.activityId} and ${widget.destinationId}");
    getUserDetails();
  }

  int userId = 0;
  dynamic userDetails;

//--------------------GET USER DETAILS-----------------------//
  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userDetails = prefs.getString("userDetails");

    // print("userDetails $userDetails");
    if (userDetails != null) {
      dynamic data = json.decode(userDetails);
      userId = data['user_id'];
    }
    List<int> sendActivity =
        widget.activityId.split(',').map((e) => int.parse(e.trim())).toList();
    log("sendafdasdfasfd$sendActivity");
    setState(() {
      isApiCalling = false;
    });
    getTripsApi(
      userId,
      sendDate,
      sendPickUp,
      advertisementId == 1
          ? 0
          : advertisementId == 2
              ? 1
              : "",
      sendAddons.join(','),
      sendActivity.join(','),
    );
    getAddonsApi(userId);
    getActivityApi(userId);
    getPickUpsApi(userId);
    getLatLongsApi(userId, widget.destinationId);
    setState(() {});
  }

  //=============================GET Trips DETAILS===================================//
  Future<void> getTripsApi(userId, String date, String pickUp,
      advertisementType, String addOnsIds, String activityIds) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}fetch_trip_according_destination_activity?user_id=$userId&activity_id=$activityIds&destination_id=${widget.destinationId}&pickup_location=$pickUp&advertisement_type=$advertisementType&addone_id=$addOnsIds&date=$date");

    String token = AppConstant.token;

    if (token.isEmpty) {}

    Map<String, String> headers = {
      'Authorization': 'Bearer $token', // Use 'Bearer' if required
    };

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);

        if (res['success'] == true) {
          var item = res['trip_arr'];
          oceanExploreList = (item != "NA") ? item : [];
          searchOceanExploreList = (item != "NA") ? item : [];

          destination = res['destination_arr'][language];
          rating = res['destinationRating'].toString();

          setState(() {
            isLoading = false;
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
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  //=============================GET addons DETAILS===================================//
  Future<void> getAddonsApi(userId) async {
    Uri url =
        Uri.parse("${AppConfigProvider.apiUrl}get_addons?user_id=$userId");

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
          var item = res['addonCategoryArray'];
          addOnsList = (item != "NA") ? item : [];

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

  //=============================GET Activity DETAILS===================================//
  Future<void> getActivityApi(userId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_activity?user_id=$userId&destination_id=${widget.destinationId}");

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
          var item = res['activity_arr'];
          activityList = (item != "NA") ? item : [];

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

  //=============================GET Pickups===================================//
  Future<void> getPickUpsApi(userId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_all_pickup_points?user_id=$userId&destination_id=${widget.destinationId}");

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
          pickUpList = locationsList;
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

  //---------------------SEARCH FUNCTION Trips--------------------///
  searchResultCountry(String query) {
    var results1 = searchOceanExploreList
        .where((value) => value['boat_name']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    oceanExploreList = [];

    oceanExploreList = results1;

    setState(() {});
  }

  //=============================GET Map Locations DETAILS===================================//
  Future<void> getLatLongsApi(userId, destinationId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_all_pickup_points?user_id=$userId&destination_id=$destinationId");

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
          var item = res['activity_arr'];
          activityList = (item != "NA") ? item : [];

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

  var refreshKey = GlobalKey<RefreshIndicatorState>();

  //--------------------REFRESH FUNCION-----------------------//
  Future<Null> _refreshPage() async {
    refreshKey.currentState?.show(atTop: false);
    await Future.delayed(const Duration(seconds: 1));
    // getTopStories(0);
    getUserDetails();
    return null;
  }

  void applySorting() {
    if (selectedFilterOption == 0) {
      return;
    }

    setState(() {
      oceanExploreList = List.from(oceanExploreList);

      switch (selectedFilterOption) {
        case 0: // Highly Rated
          oceanExploreList.sort((a, b) {
            dynamic ratingA = a['rating'] ?? 0;
            dynamic ratingB = b['rating'] ?? 0;

            double numA = ratingA is String
                ? double.tryParse(ratingA) ?? 0
                : (ratingA as num).toDouble();
            double numB = ratingB is String
                ? double.tryParse(ratingB) ?? 0
                : (ratingB as num).toDouble();

            return numB.compareTo(numA); // high to low
          });
          break;

        case 1: // Price High To Low
          oceanExploreList.sort((a, b) {
            dynamic priceA = a['price_per_hour'] ?? 0;
            dynamic priceB = b['price_per_hour'] ?? 0;

            double numA = priceA is String
                ? double.tryParse(priceA) ?? 0
                : (priceA as num).toDouble();
            double numB = priceB is String
                ? double.tryParse(priceB) ?? 0
                : (priceB as num).toDouble();

            return numB.compareTo(numA);
          });
          break;
      }

      for (var i = 0;
          i < (oceanExploreList.length > 3 ? 3 : oceanExploreList.length);
          i++) {
        var item = oceanExploreList[i];
      }
    });
  }

  //=============add favorite trip API================//
  Future<void> addFavoriteApiCall(index, tripId) async {
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
      };

      http.Response response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      var res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (res['success'] == true) {
          setState(() {
            oceanExploreList[index]['favourite_status'] =
                res['favourite_status'];
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

  deeplinking(BuildContext context, tripId, advertisementType) async {
    var shareUrl =
        "${AppConfigProvider.apiUrl}deepLink?link=aventra://trip_id/${Uri.encodeComponent(tripId.toString())}/advertisement_type/${Uri.encodeComponent(advertisementType.toString())}";
    final RenderBox box = context.findRenderObject() as RenderBox;
    await Share.share("Aventra App! $shareUrl",
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
        inAsyncCall: isApiCalling,
        opacity: 0.5,
        child: _buildUIScreen(context));
  }

  Widget _buildUIScreen(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // double screenHeight = MediaQuery.of(context).size.height;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: Directionality(
          textDirection:
              language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: RefreshIndicator(
            onRefresh: _refreshPage,
            color: AppColor.themeColor,
            child: Container(
              color: AppColor.secondaryColor,
              width: MediaQuery.of(context).size.width * 100 / 100,
              height: MediaQuery.of(context).size.height * 100 / 100,
              child: Column(
                children: [
                  SizedBox(
                    height: screenWidth > 600
                        ? MediaQuery.of(context).size.height * 34 / 100
                        : MediaQuery.of(context).size.height * 29 / 100,
                    child: Stack(
                      children: [
                        Container(
                          alignment: Alignment.topCenter,
                          width: MediaQuery.of(context).size.width * 100 / 100,
                          height: screenWidth > 600
                              ? MediaQuery.of(context).size.height * 31 / 100
                              : MediaQuery.of(context).size.height * 27 / 100,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(50),
                                bottomLeft: Radius.circular(50)),
                            image: DecorationImage(
                              image: AssetImage(
                                AppImage.beachBgImage,
                              ),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Color.fromARGB(104, 24, 137,
                                    139), // You can change the color
                                BlendMode
                                    .darken, // Try BlendMode.srcATop for a different effect
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                color: Colors.transparent,
                                height: MediaQuery.of(context).size.height *
                                    5 /
                                    100,
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                // margin: EdgeInsets.symmetric(vertical: 7),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Transform.rotate(
                                        angle: language == 1 ? 3.1416 : 0,
                                        child: SizedBox(
                                          width: screenWidth > 600
                                              ? MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  6 /
                                                  100
                                              : MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  8 /
                                                  100,
                                          height: screenWidth > 600
                                              ? MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  6 /
                                                  100
                                              : MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  8 /
                                                  100,
                                          child:
                                              Image.asset(AppImage.bgBackArrow),
                                        ),
                                      ),
                                    ),

                                    if (searchStatus == true &&
                                        selectItemView != 3)
                                      Center(
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              60 /
                                              100,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              6 /
                                              100,
                                          child: TextFormField(
                                            readOnly: false,
                                            style:
                                                AppConstant.textFilledHeading,
                                            textAlignVertical:
                                                TextAlignVertical.center,
                                            keyboardType: TextInputType.name,
                                            //controller: controller,
                                            onChanged: (value) {
                                              setState(() {
                                                if (value.isNotEmpty) {
                                                  searchResultCountry(value);
                                                } else {
                                                  oceanExploreList =
                                                      searchOceanExploreList;
                                                }
                                              });
                                            },
                                            decoration: InputDecoration(
                                              prefixIcon: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    child: Image.asset(
                                                      AppImage.searchIcon1,
                                                      height: screenWidth > 600
                                                          ? MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              3 /
                                                              100
                                                          : MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              5 /
                                                              100,
                                                      width: screenWidth > 600
                                                          ? MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              3 /
                                                              100
                                                          : MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              5 /
                                                              100,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              border: const OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: AppColor
                                                        .secondaryColor),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(25)),
                                              ),
                                              enabledBorder:
                                                  const OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: AppColor
                                                        .secondaryColor),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(25)),
                                              ),
                                              focusedBorder:
                                                  const OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: AppColor
                                                        .secondaryColor),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(25)),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5,
                                                      horizontal: 15),
                                              filled: false,
                                              counterText: '',
                                              hintText: AppLanguage
                                                  .searchInputText[language],
                                              hintStyle: const TextStyle(
                                                  color:
                                                      AppColor.secondaryColor,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  fontFamily:
                                                      AppFont.fontFamily),
                                            ),
                                          ),
                                        ),
                                      ),

                                    //search icon
                                    if (selectItemView != 3)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            searchStatus = !searchStatus;
                                          });
                                        },
                                        child: Container(
                                          alignment: Alignment.centerRight,
                                          // color: Colors.red,
                                          height: screenWidth > 600
                                              ? MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  10 /
                                                  100
                                              : MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  13 /
                                                  100,
                                          width: screenWidth > 600
                                              ? MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  8 /
                                                  100
                                              : MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  12 /
                                                  100,
                                          child: Image.asset(
                                            AppImage.searchRoundIcon,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      // color: Colors.red,
                                      width: MediaQuery.of(context).size.width *
                                          90 /
                                          100,
                                      height:
                                          MediaQuery.of(context).size.height *
                                              7.3 /
                                              100,
                                      child: Text(
                                        selectItemView != 3
                                            ? destination
                                            : AppLanguage.divingText[language],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: AppColor.primaryColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: AppFont.fontFamily),
                                      ),
                                    ),
                                    if (selectItemView != 3 &&
                                        rating.toString() != "0.00")
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                15 /
                                                100,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        decoration: BoxDecoration(
                                            color: AppColor.secondaryColor,
                                            borderRadius:
                                                BorderRadius.circular(25),
                                            boxShadow: [
                                              BoxShadow(
                                                  blurRadius: 7,
                                                  spreadRadius: 3,
                                                  color: AppColor.shadowColor
                                                      .withOpacity(0.3))
                                            ]),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: screenWidth > 600
                                                  ? MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      3 /
                                                      100
                                                  : MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      4 /
                                                      100,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  4 /
                                                  100,
                                              child: Image.asset(
                                                  AppImage.ratingIcon),
                                            ),
                                            SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    1 /
                                                    100),
                                            Text(
                                              rating.toString(),
                                              style: TextStyle(
                                                  color: AppColor.primaryColor,
                                                  fontSize: (screenWidth > 600)
                                                      ? 18
                                                      : 12,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily:
                                                      AppFont.fontFamily),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      2 /
                                      100),
                            ],
                          ),
                        ),

                        //three toggle buttons
                        Positioned(
                          left: MediaQuery.of(context).size.width * 9 / 100,
                          bottom: 0,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 82 / 100,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                                color: AppColor.secondaryColor,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: const [
                                  BoxShadow(
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                      color: AppColor.shadowColor)
                                ]),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                if (screenWidth < 600)
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.5 /
                                          100),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectItemView = 1;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 9, horizontal: 20),
                                    decoration: BoxDecoration(
                                        color: selectItemView == 1
                                            ? AppColor.themeColor
                                                .withOpacity(0.9)
                                            : AppColor.secondaryColor,
                                        borderRadius:
                                            BorderRadius.circular(25)),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              4.5 /
                                              100,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              4.5 /
                                              100,
                                          child: Image.asset(selectItemView == 1
                                              ? AppImage.listActiveIcon
                                              : AppImage.listDeactiveIcon),
                                        ),
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                1 /
                                                100),
                                        Text(
                                          AppLanguage.listtext[language],
                                          style: TextStyle(
                                              color: selectItemView == 1
                                                  ? AppColor.secondaryColor
                                                  : AppColor.grayColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: AppFont.fontFamily),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // grid
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectItemView = 2;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 9, horizontal: 20),
                                    decoration: BoxDecoration(
                                        color: selectItemView == 2
                                            ? AppColor.themeColor
                                                .withOpacity(0.9)
                                            : AppColor.secondaryColor,
                                        borderRadius:
                                            BorderRadius.circular(25)),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              4.5 /
                                              100,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              4.5 /
                                              100,
                                          child: Image.asset(selectItemView == 2
                                              ? AppImage.gridActiveIcon
                                              : AppImage.griddeactiveIcon),
                                        ),
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                1 /
                                                100),
                                        Text(
                                          AppLanguage.gridtext[language],
                                          style: TextStyle(
                                              color: selectItemView == 2
                                                  ? AppColor.secondaryColor
                                                  : AppColor.grayColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: AppFont.fontFamily),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // map
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectItemView = 3;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 9, horizontal: 20),
                                    decoration: BoxDecoration(
                                        color: selectItemView == 3
                                            ? AppColor.themeColor
                                                .withOpacity(0.9)
                                            : AppColor.secondaryColor,
                                        borderRadius:
                                            BorderRadius.circular(25)),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              4.5 /
                                              100,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              4.5 /
                                              100,
                                          child: Image.asset(selectItemView == 3
                                              ? AppImage.mapActiveIcon
                                              : AppImage.mapDeactiveIcon),
                                        ),
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                1 /
                                                100),
                                        Text(
                                          AppLanguage.maptext[language],
                                          style: TextStyle(
                                              color: selectItemView == 3
                                                  ? AppColor.secondaryColor
                                                  : AppColor.grayColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: AppFont.fontFamily),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (screenWidth < 600)
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.5 /
                                          100),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 2 / 100),
                  if (selectItemView != 3)
                    Container(
                      width: MediaQuery.of(context).size.width * 90 / 100,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 7),
                      decoration:
                          const BoxDecoration(color: AppColor.transparentColor),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${AppLanguage.availabletext[language]}(${oceanExploreList.length})",
                            style: const TextStyle(
                                color: AppColor.primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFont.fontFamily),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  filterBottomSheet(context, screenWidth);
                                },
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          4 /
                                          100,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              4 /
                                              100,
                                      child:
                                          Image.asset(AppImage.filterSortIcon),
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                2 /
                                                100),
                                    Text(
                                      AppLanguage.filtertext[language],
                                      style: const TextStyle(
                                          color: AppColor.primaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: AppFont.fontFamily),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      3 /
                                      100),
                              Container(
                                color: AppColor.primaryColor,
                                width: MediaQuery.of(context).size.width *
                                    0.3 /
                                    100,
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100,
                              ),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      3 /
                                      100),
                              GestureDetector(
                                onTap: () {
                                  sortBottomSheet(context, screenWidth);
                                },
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          4 /
                                          100,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              4 /
                                              100,
                                      child:
                                          Image.asset(AppImage.filterSortIcon),
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                2 /
                                                100),
                                    Text(
                                      AppLanguage.sorttext[language],
                                      style: const TextStyle(
                                          color: AppColor.primaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: AppFont.fontFamily),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  isLoading
                      ? tripsShimmerEffect(context)
                      : Expanded(
                          flex: 1,
                          child: SingleChildScrollView(
                            physics: selectItemView == 3
                                ? const NeverScrollableScrollPhysics()
                                : const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100),
                                if (selectItemView == 1) ...[
                                  if (oceanExploreList.isNotEmpty)
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          90 /
                                          100,
                                      child: Wrap(
                                        spacing: 10.0,
                                        runSpacing: 15.0,
                                        children: List.generate(
                                            oceanExploreList.length, (index) {
                                          return Stack(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  if (oceanExploreList[index][
                                                          'advertisement_type'] ==
                                                      0) {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                PrivateTripDetailsScreen(
                                                                    tripId: oceanExploreList[index]
                                                                            [
                                                                            'trip_id']
                                                                        .toString())));
                                                  } else {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                PublicTripDetailsScreen(
                                                                    tripId: oceanExploreList[index]
                                                                            [
                                                                            'trip_id']
                                                                        .toString())));
                                                  }
                                                },
                                                child: Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      90 /
                                                      100,
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      20 /
                                                      100,
                                                  padding: language == 1
                                                      ? const EdgeInsets.only(
                                                          top: 12, right: 12)
                                                      : const EdgeInsets.only(
                                                          top: 12, left: 12),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    image: DecorationImage(
                                                      image: oceanExploreList[
                                                                      index][
                                                                  'trip_image'] !=
                                                              null
                                                          ? NetworkImage(
                                                              "${AppConfigProvider.imageURL}${oceanExploreList[index]['trip_image']}")
                                                          : const AssetImage(
                                                                  AppImage
                                                                      .imageFrameImage)
                                                              as ImageProvider,
                                                      fit: BoxFit.cover,
                                                      colorFilter:
                                                          ColorFilter.mode(
                                                        Colors.black.withOpacity(
                                                            0.2), // Adjust the opacity
                                                        BlendMode
                                                            .darken, // You can change the BlendMode if needed
                                                      ),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            80 /
                                                            100,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: [
                                                            GestureDetector(
                                                              onTap: () {
                                                                addFavoriteApiCall(
                                                                    index,
                                                                    oceanExploreList[
                                                                            index]
                                                                        [
                                                                        'trip_id']);
                                                              },
                                                              child: SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    6.5 /
                                                                    100,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    6.5 /
                                                                    100,
                                                                child: Image.asset(oceanExploreList[index]
                                                                            [
                                                                            'favourite_status'] ==
                                                                        0
                                                                    ? AppImage
                                                                        .likeDeactiveIcon
                                                                    : AppImage
                                                                        .likeActiveIcon),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    2 /
                                                                    100),
                                                            InkWell(
                                                              onTap: () {
                                                                deeplinking(
                                                                    context,
                                                                    oceanExploreList[
                                                                            index]
                                                                        [
                                                                        'trip_id'],
                                                                    oceanExploreList[
                                                                            index]
                                                                        [
                                                                        'advertisement_type']);
                                                              },
                                                              child: SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    6.5 /
                                                                    100,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    6.5 /
                                                                    100,
                                                                child: Image.asset(
                                                                    AppImage
                                                                        .shareIcon),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            oceanExploreList[
                                                                    index]
                                                                ['boat_name'],
                                                            style: const TextStyle(
                                                                color: AppColor
                                                                    .secondaryColor,
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontFamily: AppFont
                                                                    .fontFamily),
                                                          ),
                                                          Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                AppLanguage
                                                                        .cityNameInputText[
                                                                    language],
                                                                style: const TextStyle(
                                                                    color: AppColor
                                                                        .secondaryColor,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontFamily:
                                                                        AppFont
                                                                            .fontFamily),
                                                              ),
                                                              SizedBox(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      1 /
                                                                      100),
                                                              Container(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    1 /
                                                                    100,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    1 /
                                                                    100,
                                                                margin:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        top: 2),
                                                                decoration: const BoxDecoration(
                                                                    color: AppColor
                                                                        .secondaryColor,
                                                                    shape: BoxShape
                                                                        .circle),
                                                              ),
                                                              SizedBox(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      1 /
                                                                      100),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    70 /
                                                                    100,
                                                                // color: Colors.red,
                                                                child: Text(
                                                                  "${oceanExploreList[index]['city_name'][language] ?? ""}",
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: const TextStyle(
                                                                      color: AppColor
                                                                          .secondaryColor,
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      fontFamily:
                                                                          AppFont
                                                                              .fontFamily),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                AppLanguage
                                                                        .tripTypeText[
                                                                    language],
                                                                style: const TextStyle(
                                                                    color: AppColor
                                                                        .secondaryColor,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontFamily:
                                                                        AppFont
                                                                            .fontFamily),
                                                              ),
                                                              SizedBox(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      1 /
                                                                      100),
                                                              Container(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    1 /
                                                                    100,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    1 /
                                                                    100,
                                                                margin:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        top: 2),
                                                                decoration: const BoxDecoration(
                                                                    color: AppColor
                                                                        .secondaryColor,
                                                                    shape: BoxShape
                                                                        .circle),
                                                              ),
                                                              SizedBox(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      1 /
                                                                      100),
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    69 /
                                                                    100,
                                                                // color: Colors.red,
                                                                child: Text(
                                                                  oceanExploreList[index]
                                                                              [
                                                                              'advertisement_type'] ==
                                                                          0
                                                                      ? AppLanguage
                                                                              .privateText[
                                                                          language]
                                                                      : AppLanguage
                                                                              .publicText[
                                                                          language],
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: const TextStyle(
                                                                      color: AppColor
                                                                          .secondaryColor,
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      fontFamily:
                                                                          AppFont
                                                                              .fontFamily),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                              height: screenWidth >
                                                                      600
                                                                  ? MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .height *
                                                                      1 /
                                                                      100
                                                                  : null),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  if (oceanExploreList[index]
                                                                              [
                                                                              'rating']
                                                                          .toString() !=
                                                                      "0.00")
                                                                    Container(
                                                                      width: screenWidth >
                                                                              600
                                                                          ? MediaQuery.of(context).size.width *
                                                                              10 /
                                                                              100
                                                                          : MediaQuery.of(context).size.width *
                                                                              14 /
                                                                              100,
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          vertical:
                                                                              4,
                                                                          horizontal:
                                                                              2),
                                                                      decoration: BoxDecoration(
                                                                          color: AppColor.secondaryColor.withOpacity(
                                                                              0.3),
                                                                          borderRadius:
                                                                              BorderRadius.circular(25)),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          SizedBox(
                                                                            width: screenWidth > 600
                                                                                ? MediaQuery.of(context).size.width * 2 / 100
                                                                                : MediaQuery.of(context).size.width * 4 / 100,
                                                                            height: screenWidth > 600
                                                                                ? MediaQuery.of(context).size.width * 2 / 100
                                                                                : MediaQuery.of(context).size.width * 4 / 100,
                                                                            child:
                                                                                Image.asset(AppImage.ratingIcon),
                                                                          ),
                                                                          SizedBox(
                                                                              width: MediaQuery.of(context).size.width * 1 / 100),
                                                                          Text(
                                                                            oceanExploreList[index]['rating'].toString(),
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
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          2 /
                                                                          100),
                                                                  Container(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            4,
                                                                        horizontal:
                                                                            5),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: AppColor
                                                                          .secondaryColor
                                                                          .withOpacity(
                                                                              0.2),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              25),
                                                                    ),
                                                                    child: Text(
                                                                      "${oceanExploreList[index]['max_people']} ${AppLanguage.memberstext[language]}",
                                                                      style: const TextStyle(
                                                                          color: AppColor
                                                                              .secondaryColor,
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight: FontWeight
                                                                              .w600,
                                                                          fontFamily:
                                                                              AppFont.fontFamily),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    vertical: 5,
                                                                    horizontal:
                                                                        20),
                                                                decoration: BoxDecoration(
                                                                    color: AppColor
                                                                        .themeColor,
                                                                    borderRadius: language ==
                                                                            1
                                                                        ? const BorderRadius
                                                                            .only(
                                                                            topRight: Radius.circular(
                                                                                4),
                                                                            bottomLeft: Radius.circular(
                                                                                20))
                                                                        : const BorderRadius
                                                                            .only(
                                                                            topLeft:
                                                                                Radius.circular(4),
                                                                            bottomRight: Radius.circular(20))),
                                                                child: Row(
                                                                  children: [
                                                                    Text(
                                                                      "${oceanExploreList[index]['price_per_hour']} ${AppLanguage.kwdtext[language]}",
                                                                      style: const TextStyle(
                                                                          color: AppColor
                                                                              .secondaryColor,
                                                                          fontSize:
                                                                              14,
                                                                          fontWeight: FontWeight
                                                                              .w600,
                                                                          fontFamily:
                                                                              AppFont.fontFamily),
                                                                    ),
                                                                  ],
                                                                ),
                                                              )
                                                            ],
                                                          )
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              if (oceanExploreList[index]
                                                          ['discount'] !=
                                                      null &&
                                                  oceanExploreList[index]
                                                          ['discount'] >
                                                      0) ...[
                                                Positioned(
                                                  top:
                                                      language == 0 ? -30 : -30,
                                                  left: language == 0
                                                      ? -22
                                                      : null,
                                                  right: language == 1
                                                      ? -22
                                                      : null,
                                                  child: SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            30 /
                                                            100,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            15 /
                                                            100,
                                                    child: Image.asset(language ==
                                                            0
                                                        ? AppImage.discountStrip
                                                        : AppImage
                                                            .discountStripInverted),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: language == 0 ? 15 : 13,
                                                  left: language == 0
                                                      ? -25
                                                      : null,
                                                  right: language == 1
                                                      ? -27
                                                      : null,
                                                  child: Transform.rotate(
                                                    angle: language == 0
                                                        ? -.65
                                                        : .65,
                                                    child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      // color: Colors.red,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              30 /
                                                              100,
                                                      child: Text(
                                                        "${oceanExploreList[index]['discount']}% ${AppLanguage.offText[language]}",
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontFamily: AppFont
                                                                .fontFamily,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: AppColor
                                                                .secondaryColor),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              ]
                                            ],
                                          );
                                        }),
                                      ),
                                    ),
                                  if (oceanExploreList.isEmpty)
                                    Column(
                                      children: [
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                10 /
                                                100),
                                        Container(
                                          alignment: Alignment.center,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              90 /
                                              100,
                                          child: Text(
                                            AppLanguage.notripsText[language],
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              2 /
                                              100)
                                ],
                                if (selectItemView == 2) ...[
                                  if (oceanExploreList.isNotEmpty)
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          90 /
                                          100,
                                      child: Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        runSpacing: 10.0,
                                        children: List.generate(
                                            oceanExploreList.length, (index) {
                                          return GestureDetector(
                                            onTap: () {
                                              if (oceanExploreList[index]
                                                      ['advertisement_type'] ==
                                                  0) {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            PrivateTripDetailsScreen(
                                                                tripId: oceanExploreList[
                                                                            index]
                                                                        [
                                                                        'trip_id']
                                                                    .toString())));
                                              } else {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            PublicTripDetailsScreen(
                                                                tripId: oceanExploreList[
                                                                            index]
                                                                        [
                                                                        'trip_id']
                                                                    .toString())));
                                              }
                                            },
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  44 /
                                                  100,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  25 /
                                                  100,
                                              // decoration: BoxDecoration(
                                              //     color: Colors.amber,
                                              //     borderRadius: BorderRadius.circular(20)),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                image: DecorationImage(
                                                  image: oceanExploreList[index]
                                                              ['trip_image'] !=
                                                          null
                                                      ? NetworkImage(
                                                          "${AppConfigProvider.imageURL}${oceanExploreList[index]['trip_image']}")
                                                      : const AssetImage(AppImage
                                                              .imageFrameImage)
                                                          as ImageProvider,
                                                  fit: BoxFit.cover,
                                                  colorFilter: ColorFilter.mode(
                                                    Colors.black.withOpacity(
                                                        0.2), // Adjust the opacity
                                                    BlendMode
                                                        .darken, // You can change the BlendMode if needed
                                                  ),
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                vertical:
                                                                    screenWidth >
                                                                            600
                                                                        ? 12
                                                                        : 4,
                                                                horizontal:
                                                                    screenWidth >
                                                                            600
                                                                        ? 16
                                                                        : 8),
                                                        decoration: BoxDecoration(
                                                            color: AppColor
                                                                .themeColor,
                                                            borderRadius: language == 1
                                                                ? const BorderRadius
                                                                    .only(
                                                                    topRight:
                                                                        Radius.circular(
                                                                            20),
                                                                    bottomLeft:
                                                                        Radius.circular(
                                                                            4))
                                                                : const BorderRadius
                                                                    .only(
                                                                    topLeft:
                                                                        Radius.circular(
                                                                            20),
                                                                    bottomRight:
                                                                        Radius.circular(
                                                                            4))),
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              "${oceanExploreList[index]['price_per_hour']} ${AppLanguage.kwdtext[language]}",
                                                              style: TextStyle(
                                                                  color: AppColor
                                                                      .secondaryColor,
                                                                  fontSize:
                                                                      screenWidth >
                                                                              600
                                                                          ? 20
                                                                          : 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontFamily:
                                                                      AppFont
                                                                          .fontFamily),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              4 /
                                                              100),
                                                      const Spacer(),
                                                      InkWell(
                                                        onTap: () {
                                                          deeplinking(
                                                              context,
                                                              oceanExploreList[
                                                                      index]
                                                                  ['trip_id'],
                                                              oceanExploreList[
                                                                      index][
                                                                  'advertisement_type']);
                                                        },
                                                        child: SizedBox(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              5 /
                                                              100,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              5 /
                                                              100,
                                                          child: Image.asset(
                                                            AppImage.shareIcon,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              2 /
                                                              100),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    // color: Colors.red,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            40 /
                                                            100,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          oceanExploreList[
                                                                  index]
                                                              ['boat_name'],
                                                          style: const TextStyle(
                                                              color: AppColor
                                                                  .secondaryColor,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontFamily: AppFont
                                                                  .fontFamily),
                                                        ),
                                                        Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              AppLanguage
                                                                      .cityNameInputText[
                                                                  language],
                                                              style: const TextStyle(
                                                                  color: AppColor
                                                                      .secondaryColor,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontFamily:
                                                                      AppFont
                                                                          .fontFamily),
                                                            ),
                                                            SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    1 /
                                                                    100),
                                                            Container(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  1 /
                                                                  100,
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  1 /
                                                                  100,
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 2),
                                                              decoration: const BoxDecoration(
                                                                  color: AppColor
                                                                      .secondaryColor,
                                                                  shape: BoxShape
                                                                      .circle),
                                                            ),
                                                            SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    1 /
                                                                    100),
                                                            SizedBox(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  25 /
                                                                  100,
                                                              child: Text(
                                                                "${oceanExploreList[index]['city_name'][language] ?? ""}",
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: const TextStyle(
                                                                    color: AppColor
                                                                        .secondaryColor,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontFamily:
                                                                        AppFont
                                                                            .fontFamily),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              AppLanguage
                                                                      .tripTypeText[
                                                                  language],
                                                              style: const TextStyle(
                                                                  color: AppColor
                                                                      .secondaryColor,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontFamily:
                                                                      AppFont
                                                                          .fontFamily),
                                                            ),
                                                            SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    1 /
                                                                    100),
                                                            Container(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  1 /
                                                                  100,
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  1 /
                                                                  100,
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 2),
                                                              decoration: const BoxDecoration(
                                                                  color: AppColor
                                                                      .secondaryColor,
                                                                  shape: BoxShape
                                                                      .circle),
                                                            ),
                                                            SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    1 /
                                                                    100),
                                                            SizedBox(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  22 /
                                                                  100,
                                                              child: Text(
                                                                oceanExploreList[index]
                                                                            [
                                                                            'advertisement_type'] ==
                                                                        0
                                                                    ? AppLanguage
                                                                            .privateText[
                                                                        language]
                                                                    : AppLanguage
                                                                            .publicText[
                                                                        language],
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: const TextStyle(
                                                                    color: AppColor
                                                                        .secondaryColor,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontFamily:
                                                                        AppFont
                                                                            .fontFamily),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            if (oceanExploreList[
                                                                            index]
                                                                        [
                                                                        'rating']
                                                                    .toString() !=
                                                                "0.00")
                                                              Container(
                                                                width: screenWidth >
                                                                        600
                                                                    ? MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        10 /
                                                                        100
                                                                    : MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        14 /
                                                                        100,
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    vertical: 4,
                                                                    horizontal:
                                                                        2),
                                                                decoration: BoxDecoration(
                                                                    color: AppColor
                                                                        .secondaryColor
                                                                        .withOpacity(
                                                                            0.3),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            25)),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    SizedBox(
                                                                      width: screenWidth >
                                                                              600
                                                                          ? MediaQuery.of(context).size.width *
                                                                              2 /
                                                                              100
                                                                          : MediaQuery.of(context).size.width *
                                                                              4 /
                                                                              100,
                                                                      height: screenWidth >
                                                                              600
                                                                          ? MediaQuery.of(context).size.width *
                                                                              2 /
                                                                              100
                                                                          : MediaQuery.of(context).size.width *
                                                                              4 /
                                                                              100,
                                                                      child: Image.asset(
                                                                          AppImage
                                                                              .ratingIcon),
                                                                    ),
                                                                    SizedBox(
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          1 /
                                                                          100,
                                                                    ),
                                                                    Text(
                                                                      oceanExploreList[index]
                                                                              [
                                                                              'rating']
                                                                          .toString(),
                                                                      style: const TextStyle(
                                                                          color: AppColor
                                                                              .secondaryColor,
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight: FontWeight
                                                                              .w600,
                                                                          fontFamily:
                                                                              AppFont.fontFamily),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    2 /
                                                                    100),
                                                            Container(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              width: screenWidth >
                                                                      600
                                                                  ? MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      13 /
                                                                      100
                                                                  : MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      17 /
                                                                      100,
                                                              padding: EdgeInsets.symmetric(
                                                                  vertical:
                                                                      screenWidth >
                                                                              600
                                                                          ? 6
                                                                          : 4,
                                                                  horizontal:
                                                                      5),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: AppColor
                                                                    .secondaryColor
                                                                    .withOpacity(
                                                                        0.2),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            25),
                                                              ),
                                                              child: Text(
                                                                "${oceanExploreList[index]['max_people']} ${AppLanguage.memberstext[language]}",
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: const TextStyle(
                                                                    color: AppColor
                                                                        .secondaryColor,
                                                                    fontSize:
                                                                        10,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontFamily:
                                                                        AppFont
                                                                            .fontFamily),
                                                              ),
                                                            ),
                                                            const Spacer(),
                                                            GestureDetector(
                                                              onTap: () {
                                                                addFavoriteApiCall(
                                                                    index,
                                                                    oceanExploreList[
                                                                            index]
                                                                        [
                                                                        'trip_id']);
                                                              },
                                                              child: SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    6 /
                                                                    100,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    6 /
                                                                    100,
                                                                child: Image.asset(oceanExploreList[index]
                                                                            [
                                                                            'favourite_status'] ==
                                                                        0
                                                                    ? AppImage
                                                                        .likeDeactiveIcon
                                                                    : AppImage
                                                                        .likeActiveIcon),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                        SizedBox(
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                2 /
                                                                100)
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                  if (oceanExploreList.isEmpty)
                                    Column(
                                      children: [
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                10 /
                                                100),
                                        Container(
                                          alignment: Alignment.center,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              90 /
                                              100,
                                          child: Text(
                                            AppLanguage.notripsText[language],
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              2 /
                                              100)
                                ],
                                if (selectItemView == 3) ...[
                                  (locationsList.isNotEmpty)
                                      ? Stack(
                                          children: [
                                            ClipRRect(
                                              child: SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.68,
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                child: GoogleMap(
                                                  mapToolbarEnabled: false,
                                                  zoomGesturesEnabled: true,
                                                  rotateGesturesEnabled: true,
                                                  myLocationEnabled: false,
                                                  myLocationButtonEnabled:
                                                      false,
                                                  compassEnabled: true,
                                                  initialCameraPosition:
                                                      CameraPosition(
                                                    target: _getInitialTarget(),
                                                    zoom: 10.0,
                                                  ),
                                                  onMapCreated: (controller) {
                                                    setState(() {
                                                      mapController =
                                                          controller;
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
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  16 /
                                                  100,
                                            ),
                                            Container(
                                              alignment: Alignment.center,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  90 /
                                                  100,
                                              child: Text(
                                                AppLanguage
                                                    .noLocationText[language],
                                                style: const TextStyle(
                                                    fontFamily:
                                                        AppFont.fontFamily,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppColor.primaryColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                ]
                              ],
                            ),
                          )),
                  const NoInternetBanner(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  apply() {
    getTripsApi(
      userId,
      sendDate,
      sendPickUp,
      advertisementId == 1
          ? 0
          : advertisementId == 2
              ? 1
              : "",
      sendAddons.join(','),
      sendActivity.join(','),
    );
  }

  reset() {
    setState(() {
      advertisementId = 0;
      selectedDate;
      date = '';
      sendDate = "";
      sendAddons.clear();
      sendActivity.clear();
      sendPickUp = "";
    });
    sendActivity.add(int.parse(widget.activityId));
    getTripsApi(
      userId,
      sendDate,
      sendPickUp,
      advertisementId == 1
          ? 0
          : advertisementId == 2
              ? 1
              : "",
      sendAddons.join(','),
      sendActivity.join(','),
    );
  }

  void filterBottomSheet(BuildContext context, screenWidth) {
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
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime(2000, 1, 1),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
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
                            if (pickUpList.isNotEmpty)
                              Container(
                                alignment: language == 0
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                child: Text(
                                  AppLanguage.pickupLocationText[language],
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
                                children:
                                    List.generate(pickUpList.length, (index) {
                                  return (GestureDetector(
                                    onTap: () {
                                      if (sendPickUp ==
                                          pickUpList[index]["name"]) {
                                        setState(() {
                                          sendPickUp = "";
                                        });
                                        log(sendPickUp);
                                      } else {
                                        setState(() {
                                          sendPickUp =
                                              pickUpList[index]["name"];
                                        });
                                        log(sendPickUp);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                          color: sendPickUp ==
                                                  pickUpList[index]["name"]
                                              ? AppColor.themeColor
                                              : AppColor.secondaryColor,
                                          border: Border.all(
                                              width: 1,
                                              color: sendPickUp ==
                                                      pickUpList[index]["name"]
                                                  ? AppColor.themeColor
                                                  : AppColor.primaryColor),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 12.0),
                                        child: Text(
                                          pickUpList[index]['name'] ?? "",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: sendPickUp ==
                                                      pickUpList[index]["name"]
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
                                  MediaQuery.of(context).size.height * 2 / 100,
                            ),

                            //advertisement text
                            Container(
                              alignment: language == 0
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Text(
                                AppLanguage.advertisementText[language],
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

                            //advertisementText list
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
                                children: List.generate(
                                    advertisementList.length, (index) {
                                  return (GestureDetector(
                                    onTap: () {
                                      if (advertisementId ==
                                          advertisementList[index]['id']) {
                                        setState(() {
                                          advertisementId = 0;
                                        });
                                      } else {
                                        setState(() {
                                          advertisementId =
                                              advertisementList[index]['id'];
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                          color: advertisementId ==
                                                  advertisementList[index]['id']
                                              ? AppColor.themeColor
                                              : AppColor.secondaryColor,
                                          border: Border.all(
                                              width: 1,
                                              color: advertisementId ==
                                                      advertisementList[index]
                                                          ['id']
                                                  ? AppColor.themeColor
                                                  : AppColor.primaryColor),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 12.0),
                                        child: Text(
                                          advertisementList[index]['title'] ??
                                              "",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: advertisementId ==
                                                      advertisementList[index]
                                                          ['id']
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
                                  MediaQuery.of(context).size.height * 2 / 100,
                            ),

                            //addons list
                            Wrap(
                              children: List.generate(
                                addOnsList.length,
                                (index) {
                                  List<dynamic> subArray =
                                      addOnsList[index]['subcategories'];
                                  return Column(
                                    children: [
                                      //food text
                                      Container(
                                        alignment: language == 0
                                            ? Alignment.centerLeft
                                            : Alignment.centerRight,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                90 /
                                                100,
                                        child: Text(
                                          addOnsList[index]['addon_name']
                                              [language],
                                          style: const TextStyle(
                                              fontFamily: AppFont.fontFamily,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColor.primaryColor),
                                        ),
                                      ),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                2 /
                                                100,
                                      ),

                                      //food list
                                      Container(
                                        alignment: language == 0
                                            ? Alignment.centerLeft
                                            : Alignment.centerRight,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                90 /
                                                100,
                                        child: Wrap(
                                          alignment: WrapAlignment.start,
                                          spacing: 15,
                                          runSpacing: 10,
                                          children: List.generate(
                                              subArray.length, (subIndex) {
                                            return (GestureDetector(
                                              onTap: () {
                                                if (sendAddons.contains(subArray[
                                                        subIndex]
                                                    ["addon_subcategory_id"])) {
                                                  setState(() {
                                                    sendAddons.remove(subArray[
                                                            subIndex][
                                                        "addon_subcategory_id"]);
                                                  });
                                                  log("$sendAddons");
                                                } else {
                                                  setState(() {
                                                    sendAddons.add(subArray[
                                                            subIndex][
                                                        "addon_subcategory_id"]);
                                                  });
                                                  log("$sendAddons");
                                                }
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(1),
                                                decoration: BoxDecoration(
                                                    color: sendAddons.contains(
                                                            subArray[subIndex][
                                                                "addon_subcategory_id"])
                                                        ? AppColor.themeColor
                                                        : AppColor
                                                            .secondaryColor,
                                                    border: Border.all(
                                                        width: 1,
                                                        color: sendAddons.contains(
                                                                subArray[subIndex][
                                                                    "addon_subcategory_id"])
                                                            ? AppColor
                                                                .themeColor
                                                            : AppColor
                                                                .primaryColor),
                                                    borderRadius:
                                                        BorderRadius.circular(10)),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 4.0,
                                                      horizontal: 12.0),
                                                  child: Text(
                                                    subArray[subIndex][
                                                                "sub_category_name"]
                                                            [language] ??
                                                        "",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: sendAddons.contains(
                                                                subArray[
                                                                        subIndex]
                                                                    [
                                                                    "addon_subcategory_id"])
                                                            ? AppColor
                                                                .secondaryColor
                                                            : AppColor
                                                                .themeColor,
                                                        fontFamily:
                                                            AppFont.fontFamily,
                                                        fontWeight:
                                                            FontWeight.w500,
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
                                            MediaQuery.of(context).size.height *
                                                2 /
                                                100,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),

                            //activity text
                            if (activityList.isNotEmpty) ...[
                              Container(
                                alignment: language == 0
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                child: Text(
                                  AppLanguage.activityText[language],
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

                              //activity list
                              Container(
                                alignment: language == 0
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                child: Wrap(
                                  alignment: WrapAlignment.start,
                                  spacing: 15,
                                  runSpacing: 10,
                                  children: List.generate(activityList.length,
                                      (index) {
                                    return (GestureDetector(
                                      onTap: () {
                                        if (sendActivity.contains(
                                            activityList[index]
                                                ['activity_id'])) {
                                          setState(() {
                                            sendActivity.remove(
                                                activityList[index]
                                                    ['activity_id']);
                                          });
                                          log("$sendActivity");
                                        } else {
                                          setState(() {
                                            sendActivity.add(activityList[index]
                                                ['activity_id']);
                                          });
                                          log("$sendActivity");
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(1),
                                        decoration: BoxDecoration(
                                            color: sendActivity.contains(
                                                    activityList[index]
                                                        ['activity_id'])
                                                ? AppColor.themeColor
                                                : AppColor.secondaryColor,
                                            border: Border.all(
                                                width: 1,
                                                color: sendActivity.contains(
                                                        activityList[index]
                                                            ['activity_id'])
                                                    ? AppColor.themeColor
                                                    : AppColor.primaryColor),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0, horizontal: 12.0),
                                          child: Text(
                                            activityList[index]
                                                        ['activity_english']
                                                    [language] ??
                                                "",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: sendActivity.contains(
                                                        activityList[index]
                                                            ['activity_id'])
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
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100,
                              ),
                            ]
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

  void sortBottomSheet(BuildContext context, screenWidth) {
    showModalBottomSheet<void>(
        isScrollControlled: true,
        constraints: BoxConstraints.expand(
            width: screenWidth,
            height: MediaQuery.of(context).size.height * 60 / 100),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return Container(
                height: MediaQuery.of(context).size.height * 35 / 100,
                width: MediaQuery.of(context).size.width * 100 / 100,
                decoration: const BoxDecoration(
                  color: AppColor.secondaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 4 / 100,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 90 / 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLanguage.sorttext[language],
                            style: TextStyle(
                                color: AppColor.primaryColor,
                                fontFamily: AppFont.fontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: screenWidth > 600 ? 20 : 16)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 2 / 100,
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.1 / 100,
                    width: MediaQuery.of(context).size.width * 90 / 100,
                    color: AppColor.textColor,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 2 / 100,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(runSpacing: 15, spacing: 10, children: [
                        ...List.generate(
                          sortList.length,
                          (index) => Column(
                            children: [
                              GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    selectDishCategory(
                                      index,
                                    );
                                  },
                                  child: Container(
                                    width: MediaQuery.of(context).size.width *
                                        90 /
                                        100,
                                    color: Colors.transparent,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      //  crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          child: Text(
                                            sortList[index]["text"],
                                            style: TextStyle(
                                              color: AppColor.primaryColor,
                                              fontFamily: AppFont.fontFamily,
                                              fontSize:
                                                  screenWidth > 600 ? 18 : 16,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              4 /
                                              100,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              4 /
                                              100,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(100),
                                            border: Border.all(
                                                color: sortList[index]["id"] ==
                                                        selectedFilterOption
                                                    ? AppColor.themeColor
                                                    : AppColor
                                                        .hintTextinputColor),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    2 /
                                                    100,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    2 /
                                                    100,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            100),
                                                    color: sortList[index]
                                                                ["id"] ==
                                                            selectedFilterOption
                                                        ? AppColor.themeColor
                                                        : AppColor
                                                            .secondaryColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    1 /
                                    100,
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]));
          });
        });
  }

  void selectDishCategory(
    index,
  ) {
    setState(() {
      selectedFilterOption = sortList[index]['id'];
      applySorting();
    });
  }
}
