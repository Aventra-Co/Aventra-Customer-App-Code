import 'dart:convert';
import 'dart:developer';
import 'package:boatapp/controller/app_shimmers.dart';
import 'package:http/http.dart' as http;
import 'package:boatapp/controller/app_color.dart';
import 'package:boatapp/controller/app_constant.dart';
import 'package:boatapp/controller/app_font.dart';
import 'package:boatapp/controller/app_header.dart';
import 'package:boatapp/controller/app_image.dart';
import 'package:boatapp/controller/app_language.dart';
import 'package:flutter/material.dart';
import 'package:boatapp/view/property_screens/property_detail_screen.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../authentication/login_screen.dart';
import 'dart:ui' as ui;

class PropertyHomeScreen extends StatefulWidget {
  final String initialView;

  const PropertyHomeScreen({super.key, this.initialView = "List"});

  @override
  State<PropertyHomeScreen> createState() => _PropertyHomeScreenState();
}

class _PropertyHomeScreenState extends State<PropertyHomeScreen> {
  late String selectedView;
  int userId = 0;
  dynamic userDetails;
  bool isApiCalling = false;
  bool isLoading = true;
  int selectedPropTypeId = 0;

  // ── Search ────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<dynamic> get _filteredProperties {
    if (_searchQuery.isEmpty) return properties;
    return properties
        .where((p) =>
            p['property_name_english']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            p['city_name'][language]
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }
  // ─────────────────────────────────────────────────────────────────────

  List<dynamic> properties = [];
  List<dynamic> propertyTypeList = [];

  @override
  void initState() {
    super.initState();
    getUserDetails();
    selectedView = widget.initialView;
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
    getAllAdvertisementApi(userId, 0);
    propertyTypesApiCall(userId);
    setState(() {});
  }

  Future<void> getAllAdvertisementApi(userId, int propTypeId) async {
    setState(() {
      isLoading = true;
    });
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}getall_advertisements?user_id=$userId&property_type_id=$propTypeId");
    print("url $url");
    String token = AppConstant.token;
    Map<String, String> headers = {'Authorization': 'Bearer $token'};
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        if (res['success'] == true) {
          var item = res['data'];
          properties = (item != "NA") ? item : [];
          setState(() => isLoading = false);
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColor.white,
        statusBarIconBrightness: Brightness.dark));

    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Directionality(
        textDirection:
            language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Scaffold(
          backgroundColor: AppColor.secondaryColor,
          body: SafeArea(
            child: Column(
              children: [
                // ── Header ───────────────────────────────────────────────
                AppHeader(
                  text: AppLanguage.mostPopularpropertiesText[language],
                  onPress: () => Navigator.pop(context),
                ),

                SizedBox(height: size.height * 0.01),

                // ── Search Bar ───────────────────────────────────────────
                _buildSearchBar(size),
                SizedBox(height: size.height * 0.015),

                Expanded(
                    child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.020),
                      // ── Grid ─────────────────────────────────────────────────
                      isLoading
                          ? favGridShimmerEffect(context)
                          : _filteredProperties.isEmpty
                              ? Padding(
                                  padding:
                                      EdgeInsets.only(top: size.height * 0.1),
                                  child: Column(
                                    children: [
                                      Icon(Icons.search_off,
                                          size: 60,
                                          color: Colors.grey.shade300),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No properties found',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: AppFont.fontFamily,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: size.width * 0.04),
                                  itemCount: _filteredProperties.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.75,
                                  ),
                                  itemBuilder: (context, index) {
                                    return _propertyGridCard(
                                        _filteredProperties[index], index);
                                  },
                                ),

                      SizedBox(height: size.height * 0.05),
                    ],
                  ),
                ))
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Search Bar Widget ─────────────────────────────────────────────────
  Widget _buildSearchBar(Size size) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: size.height * 0.060,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  fontFamily: AppFont.fontFamily,
                  color: AppColor.primaryColor,
                ),
                decoration: InputDecoration(
                  hintText: AppLanguage.searchInputText[language],
                  hintStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFont.fontFamily,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Icon(
                      Icons.search,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  // Clear button when text is entered
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(Icons.close,
                              color: Colors.grey.shade400, size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  counterText: '',
                ),
              ),
            ),
          ),

          SizedBox(width: size.width * 0.03),

          // Filter Button
          GestureDetector(
            onTap: () {
              showFilterModal(context, screenWidth);
            },
            child: Container(
              width: size.height * 0.055,
              height: size.height * 0.055,
              decoration: BoxDecoration(
                color: AppColor.themeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColor.themeColor.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── View Toggle Button ────────────────────────────────────────────────
  Widget _viewButton(String label, String activeImage, String inactiveImage) {
    final isSelected = selectedView == label;
    return GestureDetector(
      onTap: () => setState(() => selectedView = label),
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

  // ── List Card ─────────────────────────────────────────────────────────
  Widget _propertyCard(Map<String, dynamic> property, int index) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PropertyDetailsScreen(
                  propertyAdId: property['property_ad_id'],
                )),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: AssetImage(property['image']),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 12,
              child: GestureDetector(
                onTap: () => setState(() {
                  addFavoriteApiCall(index, property['property_ad_id'], 1);
                }),
                child: Container(
                  width: size.width * 0.07,
                  height: size.height * 0.07,
                  decoration: const BoxDecoration(
                    color: AppColor.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    property['favourite_status'] == 1
                        ? AppImage.removeFavouriteIcon
                        : AppImage.addFavouriteIcons,
                    width: size.width * 0.07,
                    height: size.width * 0.07,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(property['name'],
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppFont.fontFamily,
                          color: AppColor.secondaryColor)),
                  const SizedBox(height: 4),
                  Text(property['location'],
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFont.fontFamily,
                          color: AppColor.secondaryColor)),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColor.themeColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                    text: property['price'],
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFont.fontFamily,
                        color: AppColor.secondaryColor),
                  ),
                  const TextSpan(
                    text: '/Day',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        fontFamily: AppFont.fontFamily,
                        color: AppColor.secondaryColor),
                  ),
                ])),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grid Card ─────────────────────────────────────────────────────────
  Widget _propertyGridCard(Map<String, dynamic> property, int index) {
    final size = MediaQuery.of(context).size;
    double screenWidth = MediaQuery.of(context).size.width;
    // find real index in original list for favorite toggle
    final realIndex = properties.indexOf(property);

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PropertyDetailsScreen(
                    propertyAdId: property['property_ad_id'],
                  ))),
      child: Container(
        width: size.width * 0.45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
              image: NetworkImage(
                  "${AppConfigProvider.imageURL}${property['cover_image']}"),
              fit: BoxFit.cover),
        ),
        child: Stack(
          children: [
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7)
                    ]),
              ),
            ),
            // Price badge top-left
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: const BoxDecoration(
                  color: AppColor.themeColor,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLanguage.startingFromText[language],
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.white)),
                    Text("${property['starting_price']?.toString() ?? ""} KWD",
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
            // Remain badge top-right
            Positioned(
              top: 6,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  deeplinkingProp(context, property['property_ad_id']);
                },
                child: Image.asset(
                  AppImage.shareIcon,
                  width: size.width * 0.06,
                  height: size.width * 0.06,
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property['property_name_english'] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: AppFont.fontFamily,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${AppLanguage.cityText[language]} \u2022 ${property['city_name'][language] ?? ""}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      fontFamily: AppFont.fontFamily,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${AppLanguage.propertyTypeText[language]} \u2022 ${property['property_type_name'][language] ?? ""}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      fontFamily: AppFont.fontFamily,
                      color: Colors.white.withOpacity(0.9),
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
                                    ? MediaQuery.of(context).size.width *
                                        2 /
                                        100
                                    : MediaQuery.of(context).size.width *
                                        3 /
                                        100,
                                height: screenWidth > 600
                                    ? MediaQuery.of(context).size.width *
                                        2 /
                                        100
                                    : MediaQuery.of(context).size.width *
                                        3 /
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 5),
                        decoration: BoxDecoration(
                          color: AppColor.secondaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          "${(property['max_adult'] ?? 0 + (property['max_child'] ?? 0))} ${AppLanguage.guestsext[language]}",
                          style: const TextStyle(
                              color: AppColor.secondaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          if (realIndex != -1) {
                            addFavoriteApiCall(
                                index, property['property_ad_id'], 1);
                          }
                        },
                        child: Image.asset(
                          (property['favourite_status'] ?? 0) == 1
                              ? AppImage.removeFavouriteIcon
                              : AppImage.addFavouriteIcons,
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
      ),
    );
  }
// ── Selected filter state ────────────────────────────────────────────

  void showFilterModal(BuildContext context, screenWidth) {
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
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 55 / 100,
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
                    height: MediaQuery.of(context).size.height * 4 / 100,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 90 / 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLanguage.selectProTypeText[language],
                            style: TextStyle(
                                color: AppColor.primaryColor,
                                fontFamily: AppFont.fontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: screenWidth > 600 ? 20 : 16)),
                        InkWell(
                          onTap: () {
                            selectedPropTypeId = 0;
                            Navigator.pop(context);
                            getAllAdvertisementApi(userId, 0);
                          },
                          child: Text(AppLanguage.clearAllText[language],
                              style: TextStyle(
                                  color: AppColor.themeColor,
                                  fontFamily: AppFont.fontFamily,
                                  fontWeight: FontWeight.w700,
                                  fontSize: screenWidth > 600 ? 18 : 14)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 3 / 100,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 90 / 100,
                            child: Wrap(
                              spacing: 15,
                              runSpacing: 10,
                              // alignment: WrapAlignment.spaceBetween,
                              children: List.generate(propertyTypeList.length,
                                  (index) {
                                return Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        selectedPropTypeId =
                                            propertyTypeList[index]
                                                ['property_type_id'];
                                        Navigator.pop(context);
                                        getAllAdvertisementApi(
                                            userId,
                                            propertyTypeList[index]
                                                ['property_type_id']);
                                      },
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                26 /
                                                100,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                26 /
                                                100,
                                        // padding:
                                        //     const EdgeInsets.only(left: 15),
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: propertyTypeList[index]
                                                        ['image'] !=
                                                    null
                                                ? NetworkImage(
                                                    "${AppConfigProvider.imageURL}${propertyTypeList[index]['image']}")
                                                : const AssetImage(
                                                        AppImage.dummyIcon)
                                                    as ImageProvider,
                                            fit: BoxFit.cover,
                                            colorFilter: (selectedPropTypeId ==
                                                    propertyTypeList[index]
                                                        ['property_type_id'])
                                                ? ColorFilter.mode(
                                                    Colors.black.withOpacity(
                                                        0.4), // Adjust the opacity
                                                    BlendMode
                                                        .darken, // You can change the BlendMode if needed
                                                  )
                                                : ColorFilter.mode(
                                                    Colors.black.withOpacity(
                                                        0.0), // Adjust the opacity
                                                    BlendMode
                                                        .darken, // You can change the BlendMode if needed
                                                  ),
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: (selectedPropTypeId ==
                                                propertyTypeList[index]
                                                    ['property_type_id'])
                                            ? Center(
                                                child: SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      8 /
                                                      100,
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      8 /
                                                      100,
                                                  child: Image.asset(
                                                      AppImage.checkIcon),
                                                ),
                                              )
                                            : Container(),
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                1 /
                                                100),
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          26 /
                                          100,
                                      alignment: Alignment.center,
                                      child: Text(
                                        propertyTypeList[index]
                                                    ['property_type_label']
                                                [language] ??
                                            '',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: AppColor.primaryColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: AppFont.fontFamily),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Property Type Card ────────────────────────────────────────────────
  Widget _propertyTypeCard({
    required BuildContext context,
    required StateSetter setModalState,
    required String imagePath,
    required String label,
  }) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Column(
        children: [
          // Image card
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                // border: Border.all(
                //   color: isSelected
                //       ? AppColor.themeColor
                //       : AppColor.boxshadowColor,
                //   width: isSelected ? 2.5 : 1,
                // ),
                // boxShadow: isSelected
                //     ? [
                //         BoxShadow(
                //           color: AppColor.themeColor.withOpacity(0.25),
                //           blurRadius: 8,
                //           spreadRadius: 1,
                //         )
                //       ]
                //     : [],
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                  // Darken slightly when NOT selected so selected pops
                  // colorFilter: isSelected
                  //     ? null
                  //     : ColorFilter.mode(
                  //         Colors.black.withOpacity(0.15),
                  //         BlendMode.darken,
                  //       ),
                ),
              ),
            ),
          ),
          SizedBox(height: size.height * 0.008),
          // Label
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: AppFont.fontFamily,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
