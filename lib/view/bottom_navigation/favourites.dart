import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:boatapp/view/other_screen/publicBookingFlow/public_trip_details.dart';
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
      // print("worked");
      // SnackBarToastMessage.showSnackBar(
      //     context, AppLanguage.notRegisteredMsg[language]);
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
    // setState(() {
    //   isLoading = true;
    // });
    Uri url =
        Uri.parse("${AppConfigProvider.apiUrl}my_favourite?user_id=$userId");
    print("url $url");

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
          var item = res['favourite_arr'];
          favoriteList = (item != "NA") ? item : [];

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
    print("prefs =================>$prefs");
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
  Future<void> addFavoriteApiCall(tripId) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}add_favourite");
    print("Url $url");
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
      };

      print("body $body");

      http.Response response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      print("response--> $response");
      var res = jsonDecode(response.body);

      print("res333 : $res");
      if (response.statusCode == 200) {
        print("res : $res");
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
        "${AppConfigProvider.apiUrl}deepLink?link=aventra://trip_id/${Uri.encodeComponent(tripId.toString())}/advertisement_type/${Uri.encodeComponent(advertisementType.toString())}";
    final RenderBox box = context.findRenderObject() as RenderBox;
    await Share.share("Aventra App! $shareUrl",
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);

    print("shareUrl $shareUrl");
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
                                  print(gridOrListView);
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
                                  print(gridOrListView);
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
                      height: MediaQuery.of(context).size.height * 2 / 100),
                  isLoading
                      ? favGridShimmerEffect(context)
                      : Expanded(
                          flex: 1,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
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
                                              return GestureDetector(
                                                onTap: () {
                                                  if (favoriteList[index][
                                                          'advertisement_type'] ==
                                                      0) {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                PrivateTripDetailsScreen(
                                                                    tripId: favoriteList[index]
                                                                            [
                                                                            'trip_id']
                                                                        .toString())));
                                                  } else {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                PublicTripDetailsScreen(
                                                                    tripId: favoriteList[index]
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
                                                  decoration: BoxDecoration(
                                                      image: DecorationImage(
                                                          image: favoriteList[
                                                                          index]
                                                                      [
                                                                      'trip_image'] !=
                                                                  null
                                                              ? NetworkImage(
                                                                  '${AppConfigProvider.imageURL}${favoriteList[index]['trip_image']}')
                                                              : const AssetImage(
                                                                      AppImage
                                                                          .imageFrameImage)
                                                                  as ImageProvider,
                                                          fit: BoxFit.cover),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20)),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical: 4,
                                                                    horizontal:
                                                                        8),
                                                            decoration: BoxDecoration(
                                                                color: AppColor
                                                                    .themeColor,
                                                                borderRadius: language ==
                                                                        1
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
                                                                            Radius.circular(4))),
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  "${favoriteList[index]['price_per_hour']} ${AppLanguage.kwdtext[language]}",
                                                                  style: TextStyle(
                                                                      color: AppColor
                                                                          .secondaryColor,
                                                                      fontSize: screenWidth >
                                                                              600
                                                                          ? 24
                                                                          : 14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontFamily:
                                                                          AppFont
                                                                              .fontFamily),
                                                                ),
                                                                Container(
                                                                  margin:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              4),
                                                                  child: Text(
                                                                    AppLanguage
                                                                            .hourtext[
                                                                        language],
                                                                    style: const TextStyle(
                                                                        color: AppColor
                                                                            .secondaryColor,
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w600,
                                                                        fontFamily:
                                                                            AppFont.fontFamily),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          SizedBox(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                2 /
                                                                100,
                                                          )
                                                        ],
                                                      ),
                                                      SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
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
                                                              favoriteList[
                                                                      index][
                                                                  'boat_name_english'][0],
                                                              style: const TextStyle(
                                                                  color: AppColor
                                                                      .secondaryColor,
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontFamily:
                                                                      AppFont
                                                                          .fontFamily),
                                                            ),
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  AppLanguage
                                                                          .pickupText[
                                                                      language],
                                                                  style: const TextStyle(
                                                                      color: AppColor
                                                                          .secondaryColor,
                                                                      fontSize:
                                                                          10,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      fontFamily:
                                                                          AppFont
                                                                              .fontFamily),
                                                                ),
                                                                SizedBox(
                                                                    width: MediaQuery.of(context)
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
                                                                  decoration: const BoxDecoration(
                                                                      color: AppColor
                                                                          .secondaryColor,
                                                                      shape: BoxShape
                                                                          .circle),
                                                                ),
                                                                SizedBox(
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        1 /
                                                                        100),
                                                                SizedBox(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      28 /
                                                                      100,
                                                                  child: Text(
                                                                    favoriteList[index]
                                                                            [
                                                                            'destination_english']
                                                                        [
                                                                        language],
                                                                    style: const TextStyle(
                                                                        color: AppColor
                                                                            .secondaryColor,
                                                                        fontSize:
                                                                            10,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w500,
                                                                        fontFamily:
                                                                            AppFont.fontFamily),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: [
                                                                if (favoriteList[
                                                                            index]
                                                                        [
                                                                        'total_rating'] !=
                                                                    "0.00")
                                                                  Container(
                                                                    width: screenWidth >
                                                                            600
                                                                        ? MediaQuery.of(context).size.width *
                                                                            8 /
                                                                            100
                                                                        : MediaQuery.of(context).size.width *
                                                                            11 /
                                                                            100,
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            2,
                                                                        horizontal:
                                                                            3),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: AppColor
                                                                          .secondaryColor
                                                                          .withOpacity(
                                                                              0.4),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              25),
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        SizedBox(
                                                                          width: screenWidth > 600
                                                                              ? MediaQuery.of(context).size.width * 2 / 100
                                                                              : MediaQuery.of(context).size.width * 3 / 100,
                                                                          height: screenWidth > 600
                                                                              ? MediaQuery.of(context).size.width * 2 / 100
                                                                              : MediaQuery.of(context).size.width * 3 / 100,
                                                                          child:
                                                                              Image.asset(AppImage.ratingIcon),
                                                                        ),
                                                                        SizedBox(
                                                                            width: MediaQuery.of(context).size.width *
                                                                                1 /
                                                                                100),
                                                                        Text(
                                                                          favoriteList[index]['total_rating'],
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
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        1 /
                                                                        100),
                                                                Container(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      15 /
                                                                      100,
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          2,
                                                                      horizontal:
                                                                          5),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: AppColor
                                                                        .secondaryColor
                                                                        .withOpacity(
                                                                            0.4),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            25),
                                                                  ),
                                                                  child: Text(
                                                                    "${favoriteList[index]['max_people']} ${AppLanguage.memberstext[language]}",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: const TextStyle(
                                                                        color: AppColor
                                                                            .secondaryColor,
                                                                        fontSize:
                                                                            8,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w600,
                                                                        fontFamily:
                                                                            AppFont.fontFamily),
                                                                  ),
                                                                ),
                                                                const Spacer(),
                                                                GestureDetector(
                                                                  onTap: () {
                                                                    addFavoriteApiCall(
                                                                        favoriteList[index]
                                                                            [
                                                                            'trip_id']);
                                                                  },
                                                                  child:
                                                                      SizedBox(
                                                                    //  color: Colors.red,
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        6 /
                                                                        100,
                                                                    height: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        6 /
                                                                        100,
                                                                    child: Image.asset(
                                                                        AppImage
                                                                            .favHeartIcon),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              2.0),
                                                                  child:
                                                                      InkWell(
                                                                    onTap: () {
                                                                      deeplinking(
                                                                        context,
                                                                        favoriteList[index]
                                                                            [
                                                                            'trip_id'],
                                                                        favoriteList[index]
                                                                            [
                                                                            'advertisement_type'],
                                                                      );
                                                                    },
                                                                    child:
                                                                        SizedBox(
                                                                      // color: Colors.red,
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          6 /
                                                                          100,
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          6 /
                                                                          100,
                                                                      child: Image
                                                                          .asset(
                                                                        AppImage
                                                                            .favShareICon,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            SizedBox(
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height *
                                                                    1 /
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
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColor.primaryColor),
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
                                              return GestureDetector(
                                                onTap: () {
                                                  if (favoriteList[index][
                                                          'advertisement_type'] ==
                                                      0) {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                PrivateTripDetailsScreen(
                                                                    tripId: favoriteList[index]
                                                                            [
                                                                            'trip_id']
                                                                        .toString())));
                                                  } else {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                PublicTripDetailsScreen(
                                                                    tripId: favoriteList[index]
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
                                                      image: DecorationImage(
                                                          image: favoriteList[
                                                                          index]
                                                                      [
                                                                      'trip_image'] !=
                                                                  null
                                                              ? NetworkImage(
                                                                  '${AppConfigProvider.imageURL}${favoriteList[index]['trip_image']}')
                                                              : const AssetImage(
                                                                      AppImage
                                                                          .imageFrameImage)
                                                                  as ImageProvider,
                                                          fit: BoxFit.cover),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20)),
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
                                                                    favoriteList[
                                                                            index]
                                                                        [
                                                                        'trip_id']);
                                                              },
                                                              child: SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    7 /
                                                                    100,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    7 /
                                                                    100,
                                                                child: Image.asset(
                                                                    AppImage
                                                                        .favHeartIcon),
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding: language ==
                                                                      1
                                                                  ? const EdgeInsets
                                                                      .only(
                                                                      right:
                                                                          4.0)
                                                                  : const EdgeInsets
                                                                      .only(
                                                                      left:
                                                                          4.0),
                                                              child: SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    7 /
                                                                    100,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    7 /
                                                                    100,
                                                                child: Image.asset(
                                                                    AppImage
                                                                        .favShareICon),
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
                                                            favoriteList[index][
                                                                'boat_name_english'][0],
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
                                                                        .pickupText[
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
                                                              Text(
                                                                favoriteList[
                                                                            index]
                                                                        [
                                                                        'destination_english']
                                                                    [language],
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
                                                            ],
                                                          ),
                                                          // Row(
                                                          //   crossAxisAlignment:
                                                          //       CrossAxisAlignment.center,
                                                          //   children: [
                                                          //     Text(
                                                          //       favoriteList[index]
                                                          //           ['pickup'],
                                                          //       style: const TextStyle(
                                                          //           color: AppColor
                                                          //               .secondaryColor,
                                                          //           fontSize: 12,
                                                          //           fontWeight:
                                                          //               FontWeight.w500,
                                                          //           fontFamily:
                                                          //               AppFont.fontFamily),
                                                          //     ),
                                                          //     SizedBox(
                                                          //         width:
                                                          //             MediaQuery.of(context)
                                                          //                     .size
                                                          //                     .width *
                                                          //                 1 /
                                                          //                 100),
                                                          //     Container(
                                                          //       width:
                                                          //           MediaQuery.of(context)
                                                          //                   .size
                                                          //                   .width *
                                                          //               1 /
                                                          //               100,
                                                          //       height:
                                                          //           MediaQuery.of(context)
                                                          //                   .size
                                                          //                   .width *
                                                          //               1 /
                                                          //               100,
                                                          //       margin:
                                                          //           const EdgeInsets.only(
                                                          //               top: 2),
                                                          //       decoration: const BoxDecoration(
                                                          //           color: AppColor
                                                          //               .secondaryColor,
                                                          //           shape: BoxShape.circle),
                                                          //     ),
                                                          //     SizedBox(
                                                          //         width:
                                                          //             MediaQuery.of(context)
                                                          //                     .size
                                                          //                     .width *
                                                          //                 1 /
                                                          //                 100),
                                                          //     Text(
                                                          //       favoriteList[index]
                                                          //           ['khiran'],
                                                          //       style: const TextStyle(
                                                          //           color: AppColor
                                                          //               .secondaryColor,
                                                          //           fontSize: 12,
                                                          //           fontWeight:
                                                          //               FontWeight.w500,
                                                          //           fontFamily:
                                                          //               AppFont.fontFamily),
                                                          //     ),
                                                          //   ],
                                                          // ),

                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  if (favoriteList[
                                                                              index]
                                                                          [
                                                                          'total_rating'] !=
                                                                      "0.00")
                                                                    Container(
                                                                      width: screenWidth >
                                                                              600
                                                                          ? MediaQuery.of(context).size.width *
                                                                              8 /
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
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: AppColor
                                                                            .secondaryColor
                                                                            .withOpacity(0.2),
                                                                        borderRadius:
                                                                            BorderRadius.circular(25),
                                                                      ),
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
                                                                            favoriteList[index]['total_rating'],
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
                                                                      "${favoriteList[index]['max_people']} ${AppLanguage.memberstext[language]}",
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
                                                              const Spacer(),
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
                                                                            bottomLeft: Radius.circular(
                                                                                20),
                                                                            topRight: Radius.circular(
                                                                                4))
                                                                        : const BorderRadius
                                                                            .only(
                                                                            topLeft:
                                                                                Radius.circular(4),
                                                                            bottomRight: Radius.circular(20))),
                                                                child: Row(
                                                                  children: [
                                                                    Text(
                                                                      "${favoriteList[index]['price_per_hour']} ${AppLanguage.kwdtext[language]}",
                                                                      style: const TextStyle(
                                                                          color: AppColor
                                                                              .secondaryColor,
                                                                          fontSize:
                                                                              16,
                                                                          fontWeight: FontWeight
                                                                              .w600,
                                                                          fontFamily:
                                                                              AppFont.fontFamily),
                                                                    ),
                                                                    Container(
                                                                      margin: const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              4),
                                                                      child:
                                                                          Text(
                                                                        AppLanguage
                                                                            .hourtext[language],
                                                                        style: const TextStyle(
                                                                            color: AppColor
                                                                                .secondaryColor,
                                                                            fontSize:
                                                                                11,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontFamily: AppFont.fontFamily),
                                                                      ),
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
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColor.primaryColor),
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
              ),
            ),
          ),
        )),
      ),
    );
  }
}
