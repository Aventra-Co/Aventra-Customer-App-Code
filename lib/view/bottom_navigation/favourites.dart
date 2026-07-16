import 'dart:convert';
import 'package:http/http.dart' as http;
import '/view/other_screen/publicBookingFlow/public_trip_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_footer.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import 'dart:ui' as ui;
import '../../controller/app_loader.dart';
import '../../controller/app_shimmers.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../authentication/login_screen.dart';
import '../other_screen/privateBookingFlow/private_trip_details.dart';
import '../property_screens/property_detail_screen.dart';
import '../../widgets/trip_ad_card.dart';

class Favourites extends StatefulWidget {
  static String routeName = './Favourites';
  const Favourites({super.key});

  @override
  State<Favourites> createState() => _FavouritesState();
}

class _FavouritesState extends State<Favourites> {
  int gridOrListView = 1;
  List favoriteList = [];
  bool isApiCalling = false;
  bool isLoading = true;
  int userId = 0;
  dynamic data;
  dynamic userDataArr;
  int selectedTab = 0;
  List<dynamic> properties = [];

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  //----------------------------GET USER DETAILS--------------------------------//
  Future<dynamic> getUserDetails() async {
    setState(() {
      isApiCalling = true;
    });
    final prefs = await SharedPreferences.getInstance();
    data = prefs.getString("userDetails");

    // print("userDetails $userDetails");
    if (isGuest) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Login()));
      return;
    }
    if (data == null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Login()));
    } else {
      userDataArr = jsonDecode(data);
      userId = userDataArr['user_id'] ?? 0;
    }
    getFavoritesApiCall(userId);
    isApiCalling = false;
    setState(() {});
  }

  //------------------------Get Favorite API CALL--------------------------------//
  Future<void> getFavoritesApiCall(userId) async {
    setState(() {
      isLoading = true;
    });
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}my_favourite?user_id=$userId&entity_type=$selectedTab");
    print("URL $url");

    String token = AppConstant.token;

    if (token.isEmpty) {
      // return;
    }

    Map<String, String> headers = {
      'Authorization': 'Bearer $token', // Use 'Bearer' if required
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);

        if (res['success'] == true) {
          var item = res['favourite_arr'];
          if (selectedTab == 0) {
            favoriteList = (item != "NA") ? item : [];
          } else {
            properties = (item != "NA") ? item : [];
          }

          setState(() {
            isLoading = false;
          });
        } else {
          favoriteList = [];
          setState(() {
            isLoading = false;
          });
          // ignore: use_build_context_synchronously
          if (res['active_status'] == 0) {
            localstorageclearbutton();
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          }
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

  //-----------------Sign Out-----------------------
  localstorageclearbutton() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userDetails');
    prefs.remove('password');

    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (context) => const Login(),
      ),
    );
  }

  var refreshKey = GlobalKey<RefreshIndicatorState>();

  //--------------------REFRESH FUNCION-----------------------//
  Future<Null> _refreshPage() async {
    refreshKey.currentState?.show(atTop: false);
    await Future.delayed(const Duration(seconds: 1));
    getUserDetails();
    return null;
  }

  //=============add favorite trip API================//
  Future<void> addFavoriteApiCall(tripId, int entity) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}add_favourite");
    setState(() {
      isApiCalling = true;
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

      http.Response response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      var res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (res['success'] == true) {
          getFavoritesApiCall(userId);
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
        "${AppConfigProvider.apiUrl}deepLink?link=aventra://trip_id/${Uri.encodeComponent(tripId.toString())}/advertisement_type/${Uri.encodeComponent(advertisementType.toString())}/entity/${Uri.encodeComponent(0.toString())}";
    final RenderBox box = context.findRenderObject() as RenderBox;
    await Share.share("Aventra App! $shareUrl",
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
  }

  deeplinkingProp(BuildContext context, propertyAdId) async {
    var shareUrl =
        "${AppConfigProvider.apiUrl}deepLink?link=aventra://property_ad_id/${Uri.encodeComponent(propertyAdId.toString())}/entity/${Uri.encodeComponent(1.toString())}";
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
    final size = MediaQuery.of(context).size;
    double screenWidth = MediaQuery.of(context).size.width;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColor.secondaryColor,
        statusBarIconBrightness: Brightness.dark));
    return WillPopScope(
      onWillPop: () {
        AppConstant.selectFooterIndex = 0;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyFooterPage(),
          ),
        );
        return Future.value(false);
      },
      child: Scaffold(
        body: SafeArea(
            child: Directionality(
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
                  const NoInternetBanner(),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 1 / 100),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 90 / 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLanguage.favouritesText[language],
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
                                setState(() {
                                  gridOrListView = 1;
                                });
                              },
                              child: SizedBox(
                                height: screenWidth > 600
                                    ? MediaQuery.of(context).size.width *
                                        5 /
                                        100
                                    : MediaQuery.of(context).size.width *
                                        7 /
                                        100,
                                width: screenWidth > 600
                                    ? MediaQuery.of(context).size.width *
                                        5 /
                                        100
                                    : MediaQuery.of(context).size.width *
                                        7 /
                                        100,
                                child: Image.asset(gridOrListView == 1
                                    ? AppImage.gridViewActiveIcon
                                    : AppImage.griddeactiveIcon),
                              ),
                            ),
                            SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    3 /
                                    100),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  gridOrListView = 2;
                                });
                              },
                              child: SizedBox(
                                height: screenWidth > 600
                                    ? MediaQuery.of(context).size.width *
                                        5 /
                                        100
                                    : MediaQuery.of(context).size.width *
                                        7 /
                                        100,
                                width: screenWidth > 600
                                    ? MediaQuery.of(context).size.width *
                                        5 /
                                        100
                                    : MediaQuery.of(context).size.width *
                                        7 /
                                        100,
                                child: Image.asset(gridOrListView == 2
                                    ? AppImage.listViewActiveIcon
                                    : AppImage.listViewDeactiveIcon),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),

                  SizedBox(
                      height: MediaQuery.of(context).size.height *
                          3.5 /
                          100), // Toggle buttons
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: size.width * 0.04),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedTab = 0; // Sea tab
                                if (favoriteList.isEmpty) {
                                  getFavoritesApiCall(userId);
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: size.height * 0.01,
                                  horizontal: size.width * 0.04),
                              decoration: BoxDecoration(
                                color: selectedTab == 0
                                    ? AppColor.themeColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedTab == 0
                                      ? AppColor.themeColor
                                      : AppColor.themeColor,
                                ),
                              ),
                              child: Text(
                                AppLanguage.seaText[language],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: AppFont.fontFamily,
                                  fontWeight: FontWeight.w600,
                                  color: selectedTab == 0
                                      ? AppColor.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * 0.03),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedTab = 1; // Property tab
                                if (properties.isEmpty) {
                                  getFavoritesApiCall(userId);
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: size.height * 0.01,
                                  horizontal: size.width * 0.04),
                              decoration: BoxDecoration(
                                color: selectedTab == 1
                                    ? AppColor.themeColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedTab == 1
                                      ? AppColor.themeColor
                                      : AppColor.themeColor,
                                ),
                              ),
                              child: Text(
                                AppLanguage.propertyText[language],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: AppFont.fontFamily,
                                  fontWeight: FontWeight.w600,
                                  color: selectedTab == 1
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SizedBox(height: size.height * 3.5 / 100),

                  if (selectedTab == 1) ...[
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 2 / 100),
                    Expanded(
                      child: isLoading
                          ? favGridShimmerEffect(context)
                          : (properties.isEmpty)
                              ? Center(
                                  child: SizedBox(
                                    width: screenWidth * 70 / 100,
                                    child: Text(
                                      AppLanguage.favNoDataMsg[language],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontFamily: AppFont.fontFamily,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.primaryColor),
                                    ),
                                  ),
                                )
                              : (gridOrListView == 1
                                  ? _propertyGridCard()
                                  // GridView.builder(
                                  //     padding: const EdgeInsets.symmetric(
                                  //         horizontal: 16),
                                  //     itemCount: properties.length,
                                  //     physics:
                                  //         const AlwaysScrollableScrollPhysics(),
                                  //     gridDelegate:
                                  //         const SliverGridDelegateWithFixedCrossAxisCount(
                                  //       crossAxisCount: 2,
                                  //       crossAxisSpacing: 8,
                                  //       mainAxisSpacing: 16,
                                  //       childAspectRatio:
                                  //           0.72, // slightly taller cells
                                  //     ),
                                  //     itemBuilder: (context, index) {
                                  //       return _propertyGridCard(
                                  //           properties[index], index);
                                  //     },
                                  //   )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18),
                                      itemCount: properties.length,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        return Column(
                                          children: [
                                            _propertyCard(properties[index],
                                                index, screenWidth),
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  2 /
                                                  100,
                                            ),
                                          ],
                                        );
                                      },
                                    )),
                    ),
                  ],

                  if (selectedTab != 1) ...[
                    isLoading
                        ? Expanded(
                            flex: 1,
                            child: favGridShimmerEffect(context),
                          )
                        : Expanded(
                            flex: 1,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                children: [
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              2 /
                                              100),
                                  if (gridOrListView == 1)
                                    (favoriteList.isNotEmpty)
                                        ? SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                90 /
                                                100,
                                            child: Wrap(
                                              alignment:
                                                  WrapAlignment.spaceBetween,
                                              runSpacing: 10.0,
                                              children: List.generate(
                                                  favoriteList.length, (index) {
                                                final trip = favoriteList[index];
                                                // Favourites are always liked
                                                if (trip['favourite_status'] != 1) {
                                                  trip['favourite_status'] = 1;
                                                }
                                                final size =
                                                    MediaQuery.of(context).size;
                                                return TripAdCard(
                                                  trip: trip,
                                                  layout:
                                                      TripAdCardLayout.portrait,
                                                  width: size.width * 0.44,
                                                  height: size.height * 0.32,
                                                  showFavorite: true,
                                                  showShare: true,
                                                  showImageCount: false,
                                                  onTap: () {
                                                    if (trip[
                                                            'advertisement_type'] ==
                                                        0) {
                                                      Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  PrivateTripDetailsScreen(
                                                                      tripId: trip[
                                                                              'trip_id']
                                                                          .toString())));
                                                    } else {
                                                      Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  PublicTripDetailsScreen(
                                                                      tripId: trip[
                                                                              'trip_id']
                                                                          .toString())));
                                                    }
                                                  },
                                                  onFavorite: () {
                                                    addFavoriteApiCall(
                                                        trip['trip_id'], 0);
                                                  },
                                                  onShare: () {
                                                    deeplinking(
                                                      context,
                                                      trip['trip_id'],
                                                      trip['advertisement_type'],
                                                    );
                                                  },
                                                );
                                              }),
                                            ),
                                          )
                                        : Column(
                                            children: [
                                              SizedBox(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      30 /
                                                      100),
                                              //!text msg
                                              SizedBox(
                                                width: screenWidth * 70 / 100,
                                                child: Text(
                                                  AppLanguage
                                                      .favNoDataMsg[language],
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontFamily:
                                                          AppFont.fontFamily,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColor
                                                          .primaryColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                  if (gridOrListView == 2) ...[
                                    (favoriteList.isNotEmpty)
                                        ? SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                90 /
                                                100,
                                            child: Wrap(
                                              spacing: 10.0,
                                              runSpacing: 15.0,
                                              children: List.generate(
                                                  favoriteList.length, (index) {
                                                final trip = favoriteList[index];
                                                if (trip['favourite_status'] != 1) {
                                                  trip['favourite_status'] = 1;
                                                }
                                                final size =
                                                    MediaQuery.of(context).size;
                                                return Stack(
                                                  children: [
                                                    TripAdCard(
                                                      trip: trip,
                                                      layout: TripAdCardLayout
                                                          .landscape,
                                                      width: size.width * 0.9,
                                                      height: size.height * 0.24,
                                                      showFavorite: true,
                                                      showShare: true,
                                                      onTap: () {
                                                        if (trip[
                                                                'advertisement_type'] ==
                                                            0) {
                                                          Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder: (context) =>
                                                                      PrivateTripDetailsScreen(
                                                                          tripId: trip[
                                                                                  'trip_id']
                                                                              .toString())));
                                                        } else {
                                                          Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder: (context) =>
                                                                      PublicTripDetailsScreen(
                                                                          tripId: trip[
                                                                                  'trip_id']
                                                                              .toString())));
                                                        }
                                                      },
                                                      onFavorite: () {
                                                        addFavoriteApiCall(
                                                            trip['trip_id'], 0);
                                                      },
                                                      onShare: () {
                                                        deeplinking(
                                                          context,
                                                          trip['trip_id'],
                                                          trip[
                                                              'advertisement_type'],
                                                        );
                                                      },
                                                    ),
                                                    if (trip['discount'] !=
                                                            null &&
                                                        trip['discount'] > 0) ...[
                                                      Positioned(
                                                        top: language == 0
                                                            ? -30
                                                            : -30,
                                                        left: language == 0
                                                            ? -22
                                                            : null,
                                                        right: language == 1
                                                            ? -22
                                                            : null,
                                                        child: SizedBox(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              30 /
                                                              100,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              15 /
                                                              100,
                                                          child: Image.asset(
                                                              language == 0
                                                                  ? AppImage
                                                                      .discountStrip
                                                                  : AppImage
                                                                      .discountStripInverted),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: language == 0
                                                            ? 15
                                                            : 13,
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
                                                            alignment: Alignment
                                                                .center,
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                30 /
                                                                100,
                                                            child: Text(
                                                              "${trip['discount']}% ${AppLanguage.offText[language]}",
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: const TextStyle(
                                                                  fontFamily:
                                                                      AppFont
                                                                          .fontFamily,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
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
                                          )
                                        : Column(
                                            children: [
                                              SizedBox(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      30 /
                                                      100),
                                              //!text msg
                                              SizedBox(
                                                width: screenWidth * 70 / 100,
                                                child: Text(
                                                  AppLanguage
                                                      .favNoDataMsg[language],
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontFamily:
                                                          AppFont.fontFamily,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColor
                                                          .primaryColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                1 /
                                                100)
                                  ]
                                ],
                              ),
                            ))
                  ],
                ],
              ),
            ),
          ),
        )),
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
                  addFavoriteApiCall(property['property_ad_id'], 1);
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
              left: 8,
              right: 8,
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
                      if (property['rating'] != 0) ...[
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
                      ],
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
  // Widget _propertyGridCard(Map<String, dynamic> property, int index) {
  //   final size = MediaQuery.of(context).size;
  //   double screenWidth = MediaQuery.of(context).size.width;
  //   return GestureDetector(
  //     onTap: () {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => PropertyDetailsScreen(
  //             propertyAdId: property['property_ad_id'],
  //           ),
  //         ),
  //       );
  //     },
  //     child: Stack(
  //       children: [
  //         // Gradient overlay
  //         Container(
  //           width: MediaQuery.of(context).size.width * 44 / 100,
  //           height: MediaQuery.of(context).size.height * 25 / 100,
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(16),
  //             image: DecorationImage(
  //               image: NetworkImage(
  //                   "${AppConfigProvider.imageURL}${property['image_path']}"),
  //               fit: BoxFit.cover,
  //               colorFilter: ColorFilter.mode(
  //                 Colors.black.withOpacity(0.2),
  //                 BlendMode.darken,
  //               ),
  //             ),
  //           ),
  //         ),
  //         // Price badge top-left
  //         Positioned(
  //           top: 0,
  //           left: language == 0 ? 0 : null,
  //           right: language == 1 ? 0 : null,
  //           child: Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
  //             decoration: BoxDecoration(
  //                 color: AppColor.themeColor,
  //                 borderRadius: language == 1
  //                     ? const BorderRadius.only(
  //                         bottomLeft: Radius.circular(4),
  //                         topRight: Radius.circular(17))
  //                     : const BorderRadius.only(
  //                         topLeft: Radius.circular(17),
  //                         bottomRight: Radius.circular(4))),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(AppLanguage.startingFromText[language],
  //                     style: const TextStyle(
  //                         fontSize: 10,
  //                         fontWeight: FontWeight.w500,
  //                         fontFamily: AppFont.fontFamily,
  //                         color: Colors.white)),
  //                 Text("${property['starting_price']?.toString() ?? 0} KWD",
  //                     style: const TextStyle(
  //                         fontSize: 14,
  //                         fontWeight: FontWeight.w500,
  //                         fontFamily: AppFont.fontFamily,
  //                         color: Colors.white)),
  //               ],
  //             ),
  //           ),
  //         ),
  //         Positioned(
  //           bottom: 30,
  //           left: 8,
  //           right: 8,
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text(
  //                 property['property_name_english'][0] ?? "",
  //                 maxLines: 1,
  //                 overflow: TextOverflow.ellipsis,
  //                 style: const TextStyle(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w700,
  //                   fontFamily: AppFont.fontFamily,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //               const SizedBox(height: 1),
  //               Text(
  //                 "${AppLanguage.cityText[language]} \u2022 ${property['city_name'][language] ?? ""}",
  //                 maxLines: 1,
  //                 overflow: TextOverflow.ellipsis,
  //                 style: const TextStyle(
  //                   fontSize: 10,
  //                   fontWeight: FontWeight.w500,
  //                   fontFamily: AppFont.fontFamily,
  //                   color: AppColor.white,
  //                 ),
  //               ),
  //               const SizedBox(height: 1),
  //               Text(
  //                 "${AppLanguage.propertyTypeText[language]} \u2022 ${property['property_type_name'][language] ?? ""}",
  //                 maxLines: 1,
  //                 overflow: TextOverflow.ellipsis,
  //                 style: const TextStyle(
  //                   fontSize: 10,
  //                   fontWeight: FontWeight.w500,
  //                   fontFamily: AppFont.fontFamily,
  //                   color: AppColor.white,
  //                 ),
  //               ),
  //               const SizedBox(height: 4),
  //               Row(
  //                 children: [
  //                   if (property['rating'] != 0)
  //                     Container(
  //                       width: screenWidth > 600
  //                           ? MediaQuery.of(context).size.width * 10 / 100
  //                           : MediaQuery.of(context).size.width * 11 / 100,
  //                       padding: const EdgeInsets.symmetric(
  //                           vertical: 4, horizontal: 2),
  //                       decoration: BoxDecoration(
  //                           color: AppColor.secondaryColor.withOpacity(0.3),
  //                           borderRadius: BorderRadius.circular(25)),
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           SizedBox(
  //                             width: screenWidth > 600
  //                                 ? MediaQuery.of(context).size.width * 2 / 100
  //                                 : MediaQuery.of(context).size.width * 3 / 100,
  //                             height: screenWidth > 600
  //                                 ? MediaQuery.of(context).size.width * 2 / 100
  //                                 : MediaQuery.of(context).size.width * 3 / 100,
  //                             child: Image.asset(AppImage.ratingIcon),
  //                           ),
  //                           SizedBox(
  //                               width: MediaQuery.of(context).size.width *
  //                                   1 /
  //                                   100),
  //                           Text(
  //                             property['rating'].toString(),
  //                             style: const TextStyle(
  //                                 color: AppColor.secondaryColor,
  //                                 fontSize: 10,
  //                                 fontWeight: FontWeight.w600,
  //                                 fontFamily: AppFont.fontFamily),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   SizedBox(
  //                       width: MediaQuery.of(context).size.width * 1 / 100),
  //                   Container(
  //                     alignment: Alignment.center,
  //                     width: MediaQuery.of(context).size.width * 15 / 100,
  //                     padding: const EdgeInsets.symmetric(
  //                         vertical: 2, horizontal: 5),
  //                     decoration: BoxDecoration(
  //                       color: AppColor.secondaryColor.withOpacity(0.2),
  //                       borderRadius: BorderRadius.circular(25),
  //                     ),
  //                     child: Text(
  //                       "${(property['max_adult'] ?? 0 + (property['max_child'] ?? 0))} ${AppLanguage.guestsext[language]}",
  //                       textAlign: TextAlign.center,
  //                       style: const TextStyle(
  //                           color: AppColor.secondaryColor,
  //                           fontSize: 8,
  //                           fontWeight: FontWeight.w600,
  //                           fontFamily: AppFont.fontFamily),
  //                     ),
  //                   ),
  //                   const Spacer(),
  //                   GestureDetector(
  //                     onTap: () {
  //                       addFavoriteApiCall(property['property_ad_id'], 1);
  //                     },
  //                     child: Image.asset(
  //                       (property['favourite_status'] ?? 0) == 1
  //                           ? AppImage.removeFavouriteIcon
  //                           : AppImage.addFavouriteIcons,
  //                       width: size.width * 0.06,
  //                       height: size.width * 0.06,
  //                     ),
  //                   ),
  //                   SizedBox(
  //                     width: MediaQuery.of(context).size.width * 1 / 100,
  //                   ),
  //                   GestureDetector(
  //                     onTap: () {
  //                       deeplinkingProp(context, property['property_ad_id']);
  //                     },
  //                     child: Image.asset(
  //                       AppImage.favShareICon,
  //                       width: size.width * 0.06,
  //                       height: size.width * 0.06,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _propertyGridCard() {
    final size = MediaQuery.of(context).size;
    double screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 90 / 100,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 10.0,
          children: List.generate(properties.length, (index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyDetailsScreen(
                      propertyAdId: properties[index]['property_ad_id'],
                    ),
                  ),
                );
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 44 / 100,
                height: MediaQuery.of(context).size.height * 25 / 100,
                decoration: BoxDecoration(
                    image: DecorationImage(
                      image: properties[index]['image_path'] != null
                          ? NetworkImage(
                              "${AppConfigProvider.imageURL}${properties[index]['image_path']}")
                          : const AssetImage(AppImage.imageFrameImage)
                              as ImageProvider,
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.2),
                        BlendMode.darken,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                              color: AppColor.themeColor,
                              borderRadius: language == 1
                                  ? const BorderRadius.only(
                                      topRight: Radius.circular(20),
                                      bottomLeft: Radius.circular(4))
                                  : const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(4))),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLanguage.startingFromText[language],
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily,
                                          color: Colors.white)),
                                  Text(
                                      "${properties[index]['starting_price']?.toString() ?? 0} KWD",
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily,
                                          color: Colors.white)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 2 / 100,
                        )
                      ],
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 40 / 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            properties[index]['property_name_english'][0] ?? "",
                            style: const TextStyle(
                                color: AppColor.secondaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFont.fontFamily),
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    40 /
                                    100,
                                child: Text(
                                  "${AppLanguage.cityText[language]} \u2022 ${properties[index]['city_name'][language] ?? ""}",
                                  style: const TextStyle(
                                      color: AppColor.secondaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFont.fontFamily),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    40 /
                                    100,
                                child: Text(
                                  "${AppLanguage.propertyTypeText[language]} \u2022 ${properties[index]['property_type_name'][language] ?? ""}",
                                  style: const TextStyle(
                                      color: AppColor.secondaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFont.fontFamily),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (properties[index]['rating'] != 0)
                                Container(
                                  width: screenWidth > 600
                                      ? MediaQuery.of(context).size.width *
                                          8 /
                                          100
                                      : MediaQuery.of(context).size.width *
                                          11 /
                                          100,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: AppColor.secondaryColor
                                        .withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: screenWidth > 600
                                            ? MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                2 /
                                                100
                                            : MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                3 /
                                                100,
                                        height: screenWidth > 600
                                            ? MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                2 /
                                                100
                                            : MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                3 /
                                                100,
                                        child: Image.asset(AppImage.ratingIcon),
                                      ),
                                      SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              1 /
                                              100),
                                      Text(
                                        properties[index]['rating'].toString(),
                                        style: const TextStyle(
                                            color: AppColor.secondaryColor,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: AppFont.fontFamily),
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      1 /
                                      100),
                              Container(
                                alignment: Alignment.center,
                                width: MediaQuery.of(context).size.width *
                                    15 /
                                    100,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 5),
                                decoration: BoxDecoration(
                                  color:
                                      AppColor.secondaryColor.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Text(
                                  "${(properties[index]['max_adult'] ?? 0 + (properties[index]['max_child'] ?? 0))} ${AppLanguage.guestsext[language]}",
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
                                      properties[index]['property_ad_id'], 1);
                                },
                                child: SizedBox(
                                  //  color: Colors.red,
                                  width: MediaQuery.of(context).size.width *
                                      6 /
                                      100,
                                  height: MediaQuery.of(context).size.width *
                                      6 /
                                      100,
                                  child: Image.asset(AppImage.favHeartIcon),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 2.0),
                                child: InkWell(
                                  onTap: () {
                                    deeplinkingProp(
                                      context,
                                      properties[index]['property_ad_id'],
                                    );
                                  },
                                  child: SizedBox(
                                    // color: Colors.red,
                                    width: MediaQuery.of(context).size.width *
                                        6 /
                                        100,
                                    height: MediaQuery.of(context).size.width *
                                        6 /
                                        100,
                                    child: Image.asset(
                                      AppImage.favShareICon,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 1 / 100)
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
    );
  }
}
