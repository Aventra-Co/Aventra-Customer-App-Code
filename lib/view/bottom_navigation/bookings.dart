import 'dart:convert';
import 'dart:developer';
import 'package:boatapp/controller/app_footer.dart';
import 'package:boatapp/view/property_screens/property_bookinghistory_screen.dart';
import 'package:boatapp/view/property_screens/property_ongoing_details_screen.dart';
import 'package:boatapp/view/property_screens/property_pending_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_shimmers.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../authentication/login_screen.dart';
import '../other_screen/completed_details_screen.dart';
import '../other_screen/onging_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../other_screen/upcoming_details_screen.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

class MyTrip extends StatefulWidget {
  final int selectedTab;
  static String routeName = './MyTrip';
  const MyTrip({super.key, this.selectedTab = 0});

  @override
  State<MyTrip> createState() => _MyTripState();
}

class _MyTripState extends State<MyTrip> {
  List<dynamic> bookings = [];
  List<dynamic> propertyTypeList = [];
  bool isApiCalling = false;
  bool isLoading = true;
  int userId = 0;
  dynamic data;
  dynamic userDataArr;
  List activitiesList = <dynamic>[];
  int selectedActivityId = 0;
  int selectedPropTypeId = 0;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.selectedTab;

    getUserDetails();
  }

  int selectedTab = 0;
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
        context,
        MaterialPageRoute(
          builder: (context) => const Login(),
        ),
      );
      return;
    }
    if (data == null) {
      // print("worked");
      // SnackBarToastMessage.showSnackBar(
      //     context, AppLanguage.notRegisteredMsg[language]);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const Login(),
        ),
      );
    } else {
      userDataArr = jsonDecode(data);
      userId = userDataArr['user_id'] ?? 0;
      log("userId$userId");
    }

    // print("userDataArr $userDataArr");
    bookingsApiCall(userId, "");
    propertyBookingsApiCall(userId, "");
    getActivitiesApi(userId);
    propertyTypesApiCall(userId);
    isApiCalling = false;
    setState(() {});
  }

  //=============================GET Activities DETAILS===================================//
  Future<void> getActivitiesApi(userId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_activity_list?user_id=$userId");
    print("url $url");

    String token = AppConstant.token;

    if (token.isEmpty) {
      print("Token is missing!");
      return;
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
        print("res122 $res");

        if (res['success'] == true) {
          var item = res['activity_arr'];
          activitiesList = (item != "NA") ? item : [];
          print("activity$activitiesList");
        } else {
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }
          setState(() {
            // isLoading = false;
          });
        }
      } else {
        print("Error: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Exception: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  //------------------------Bookings API CALL--------------------------------//
  Future<void> bookingsApiCall(userId, tripTypeId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}fetch_my_booking?user_id=$userId&trip_type_id=$tripTypeId");
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
          var item = res['trip_arr'];
          bookings = (item != "NA") ? item : [];

          setState(() {
            isLoading = false;
          });
        } else {
          bookings = [];
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
        bookings = [];
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      bookings = [];
      setState(() {
        isLoading = false;
      });
    }
  }

  //------------------------Bookings API CALL--------------------------------//
  Future<void> propertyBookingsApiCall(userId, propertyTypeId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_user_property_booking?user_id=$userId&property_type_id=$propertyTypeId");
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
          propertyBookings = (item != "NA") ? item : [];

          setState(() {
            isLoading = false;
          });
        } else {
          propertyBookings = [];
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
        propertyBookings = [];
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      propertyBookings = [];
      setState(() {
        isLoading = false;
      });
    }
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
          propertyBookings = [];
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
        propertyBookings = [];
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      propertyBookings = [];
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

    log("Worked");

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

  List<dynamic> propertyBookings = [];

  bool get isSeaSelected => selectedOption == AppLanguage.seaText[language];
  String selectedOption = AppLanguage.seaText[language];

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
        inAsyncCall: isApiCalling,
        opacity: 0.5,
        child: _buildUIScreen(context));
  }

  Widget _buildUIScreen(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final size = MediaQuery.of(context).size;

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
                  Container(
                      width: MediaQuery.of(context).size.width * 90 / 100,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLanguage.bookingsText[language],
                            style: const TextStyle(
                                color: AppColor.primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFont.fontFamily),
                          ),
                          GestureDetector(
                            onTap: () {
                              selectedTab == 1
                                  ? showFilterModal(
                                      context, selectedOption, screenWidth)
                                  : filterBottomSheet(context, screenWidth);
                            },
                            child: Container(
                              width:
                                  MediaQuery.of(context).size.width * 10 / 100,
                              height:
                                  MediaQuery.of(context).size.width * 10 / 100,
                              decoration: BoxDecoration(
                                  image: const DecorationImage(
                                      image: AssetImage(AppImage.filterIcon)),
                                  color: AppColor.secondaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        blurRadius: 7,
                                        spreadRadius: 3,
                                        color: AppColor.shadowColor
                                            .withOpacity(0.3))
                                  ]),
                            ),
                          ),
                        ],
                      )),

                  SizedBox(
                      height: MediaQuery.of(context).size.height *
                          2 /
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
                                "Sea",
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
                                "Property",
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

                  SizedBox(
                      height: MediaQuery.of(context).size.height * 2 / 100),

                  if (selectedTab != 0)
                    isLoading
                        ? myTripShimmerEffect(context)
                        : Expanded(
                            child: ListView.builder(
                              itemCount: propertyBookings.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: size.width * 0.05),
                                  child: _propertyBookingCard(
                                      propertyBookings[index], index),
                                );
                              },
                            ),
                          ),
                  if (selectedTab == 0)
                    isLoading
                        ? myTripShimmerEffect(context)
                        : Expanded(
                            flex: 1,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                children: [
                                  if (bookings.isNotEmpty)
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          90 /
                                          100,
                                      child: Wrap(
                                        runSpacing: 15.0,
                                        children: List.generate(bookings.length,
                                            (index) {
                                          return Column(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  if (bookings[index]
                                                          ['status'] ==
                                                      0) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            UpComingDetailsScreen(
                                                          tripId: bookings[
                                                                      index][
                                                                  'trip_booking_id']
                                                              .toString(),
                                                        ),
                                                      ),
                                                    );
                                                  } else if (bookings[index]
                                                          ['status'] ==
                                                      1) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            OngoingDetailsScreen(
                                                          tripId: bookings[
                                                                      index][
                                                                  'trip_booking_id']
                                                              .toString(),
                                                        ),
                                                      ),
                                                    );
                                                  } else if (bookings[index]
                                                          ['status'] ==
                                                      2) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            CompletedDetailsScreen(
                                                          tripBookingId: bookings[
                                                                      index][
                                                                  'trip_booking_id']
                                                              .toString(),
                                                          isCancelled: 0,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              18 /
                                                              100,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 18,
                                                          horizontal: 3),
                                                      decoration: BoxDecoration(
                                                          color: AppColor
                                                              .themeColor,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      16)),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceAround,
                                                        children: [
                                                          Text(
                                                            bookings[index]
                                                                ['month'],
                                                            style: const TextStyle(
                                                                color: AppColor
                                                                    .secondaryColor,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontFamily: AppFont
                                                                    .fontFamily),
                                                          ),
                                                          Text(
                                                            bookings[index]
                                                                ['date'],
                                                            style: const TextStyle(
                                                                color: AppColor
                                                                    .secondaryColor,
                                                                fontSize: 32,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontFamily: AppFont
                                                                    .fontFamily),
                                                          ),
                                                          Text(
                                                            bookings[index]
                                                                ['year'],
                                                            style: const TextStyle(
                                                                color: AppColor
                                                                    .secondaryColor,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontFamily: AppFont
                                                                    .fontFamily),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              70 /
                                                              100,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 15,
                                                          horizontal: 15),
                                                      decoration: BoxDecoration(
                                                          color: AppColor
                                                              .creamColor,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      16)),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  SizedBox(
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        53 /
                                                                        100,
                                                                    child: Text(
                                                                      bookings[
                                                                              index]
                                                                          [
                                                                          'boat_name_english'][0],
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: const TextStyle(
                                                                          color: AppColor
                                                                              .primaryColor,
                                                                          fontSize:
                                                                              16,
                                                                          fontWeight: FontWeight
                                                                              .w600,
                                                                          fontFamily:
                                                                              AppFont.fontFamily),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        53 /
                                                                        100,
                                                                    child: Text(
                                                                      bookings[index]
                                                                              [
                                                                              'destination_english']
                                                                          [
                                                                          language],
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: const TextStyle(
                                                                          color: AppColor
                                                                              .grayColor,
                                                                          fontSize:
                                                                              14,
                                                                          fontWeight: FontWeight
                                                                              .w500,
                                                                          fontFamily:
                                                                              AppFont.fontFamily),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        53 /
                                                                        100,
                                                                    child: Text(
                                                                      bookings[index]['advertisement_type'] ==
                                                                              0
                                                                          ? AppLanguage.privateText[
                                                                              language]
                                                                          : AppLanguage
                                                                              .publicText[language],
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: const TextStyle(
                                                                          color: AppColor
                                                                              .grayColor,
                                                                          fontSize:
                                                                              14,
                                                                          fontWeight: FontWeight
                                                                              .w500,
                                                                          fontFamily:
                                                                              AppFont.fontFamily),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Transform.rotate(
                                                                angle:
                                                                    language ==
                                                                            1
                                                                        ? 3.1416
                                                                        : 0,
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
                                                                          .rightArrow),
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                          SizedBox(
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.5 /
                                                                  100),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    bookings[
                                                                            index]
                                                                        [
                                                                        'time'],
                                                                    style: const TextStyle(
                                                                        color: AppColor
                                                                            .primaryColor,
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w500,
                                                                        fontFamily:
                                                                            AppFont.fontFamily),
                                                                  ),
                                                                  Text(
                                                                    AppLanguage
                                                                            .startTimeText[
                                                                        language],
                                                                    style: const TextStyle(
                                                                        color: AppColor
                                                                            .textColor,
                                                                        fontSize:
                                                                            10,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w500,
                                                                        fontFamily:
                                                                            AppFont.fontFamily),
                                                                  ),
                                                                ],
                                                              ),
                                                              Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    "${bookings[index]['hour']} ${AppLanguage.hourtext[language]}",
                                                                    style: const TextStyle(
                                                                        color: AppColor
                                                                            .primaryColor,
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w500,
                                                                        fontFamily:
                                                                            AppFont.fontFamily),
                                                                  ),
                                                                  Text(
                                                                    AppLanguage
                                                                            .bookingHoursText[
                                                                        language],
                                                                    style: const TextStyle(
                                                                        color: AppColor
                                                                            .textColor,
                                                                        fontSize:
                                                                            10,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w500,
                                                                        fontFamily:
                                                                            AppFont.fontFamily),
                                                                  ),
                                                                ],
                                                              ),
                                                              Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    bookings[index]['status'] ==
                                                                            0
                                                                        ? AppLanguage.upcomingText[
                                                                            language]
                                                                        : bookings[index]['status'] ==
                                                                                1
                                                                            ? AppLanguage.ongoingText[language]
                                                                            : bookings[index]['status'] == 2
                                                                                ? AppLanguage.completedText[language]
                                                                                : "",
                                                                    style: TextStyle(
                                                                        color: bookings[index]['status'] == 0
                                                                            ? AppColor.yellowColor
                                                                            : bookings[index]['status'] == 1
                                                                                ? AppColor.darkBlueColor
                                                                                : AppColor.themeColor,
                                                                        fontSize: 12,
                                                                        fontWeight: FontWeight.w500,
                                                                        fontFamily: AppFont.fontFamily),
                                                                  ),
                                                                  Text(
                                                                    AppLanguage
                                                                            .statuText[
                                                                        language],
                                                                    style: const TextStyle(
                                                                        color: AppColor
                                                                            .textColor,
                                                                        fontSize:
                                                                            10,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w500,
                                                                        fontFamily:
                                                                            AppFont.fontFamily),
                                                                  ),
                                                                ],
                                                              )
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              if (bookings.length - 1 == index)
                                                SizedBox(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      2 /
                                                      100,
                                                ),
                                            ],
                                          );
                                        }),
                                      ),
                                    ),
                                  if (bookings.isEmpty)
                                    Column(
                                      children: [
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                30 /
                                                100),
                                        //!text msg
                                        SizedBox(
                                          width: screenWidth * 75 / 100,
                                          child: Text(
                                            AppLanguage
                                                .myTripsNoDataMsg[language],
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
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

  Widget _toggleButton(String option) {
    final isSelected = selectedOption == option;
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOption = option;
        });
      },
      child: Container(
        width: size.width * 0.45,
        height: size.height * 0.045,
        padding: EdgeInsets.symmetric(
            vertical: size.height * 0.01, horizontal: size.height * 0.02),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.themeColor : AppColor.secondaryColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColor.themeColor,
            width: 0.8,
          ),
        ),
        child: Text(
          option,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: AppFont.fontFamily,
            color: isSelected ? AppColor.secondaryColor : AppColor.primaryColor,
          ),
        ),
      ),
    );
  }

  String getDatePart(String inputDate, String type) {
    DateTime date = DateFormat("MMM dd, yyyy").parse(inputDate);

    switch (type.toLowerCase()) {
      case 'month':
        return DateFormat("MMM").format(date);
      case 'date':
        return DateFormat("dd").format(date);
      case 'year':
        return DateFormat("yyyy").format(date);
      default:
        return '';
    }
  }

  Widget _propertyBookingCard(Map<String, dynamic> booking, index) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
        onTap: () {
          if (booking["booking_status"] == 1) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PropertyOngoingDetailScreen(
                          propertyBookingId: booking['property_booking_id'],
                        )));
          }
          if (booking["booking_status"] == 0) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PropertyPendingDetailsScreen(
                          propertyBookingId: booking['property_booking_id'],
                        )));
          }
          if (booking["booking_status"] == 2) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PropertyBookingHistoryDetailScreen(
                          propertyBookingId: booking['property_booking_id'],
                          iscompleted: true,
                        )));
          }
        },
        child: Container(
          margin: EdgeInsets.symmetric(
              vertical: size.height * 0.01, horizontal: size.width * 0.02),
          child: Row(
            children: [
              // Date section (left teal box)
              Container(
                width: size.width * 0.2,
                padding: EdgeInsets.symmetric(
                    vertical: size.height * 0.01,
                    horizontal: size.width * 0.02),
                decoration: BoxDecoration(
                  color: AppColor.themeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      getDatePart(booking['booking_date'], "month"),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFont.fontFamily,
                        color: AppColor.secondaryColor,
                      ),
                    ),
                    Text(
                      getDatePart(booking['booking_date'], "date"),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFont.fontFamily,
                        color: AppColor.secondaryColor,
                      ),
                    ),
                    Text(
                      getDatePart(booking['booking_date'], "year"),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFont.fontFamily,
                        color: AppColor.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Content section
              SizedBox(width: size.width * 0.02),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.03,
                      vertical: size.height * 0.01),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "name static",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: AppFont.fontFamily,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  "property type static",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: AppFont.fontFamily,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Arrow icon
                          Padding(
                            padding: const EdgeInsets.symmetric(),
                            child: Image.asset(
                              AppImage.rightArrow,
                              color: AppColor.primaryColor,
                              width: size.width * 0.07,
                              height: size.height * 0.07,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.01),
                      Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Duration / Booking
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking['booking_time_label'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFont.fontFamily,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                AppLanguage.bookingText[language],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFont.fontFamily,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(width: size.width * 0.15),
                          // Status
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking['booking_status_label'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFont.fontFamily,
                                  color: booking['booking_status'] == 0
                                      ? AppColor.yellowColor
                                      : booking['booking_status'] == 1
                                          ? AppColor.darkBlueColor
                                          : AppColor.themeColor,
                                ),
                              ),
                              Text(
                                AppLanguage.statusText[language],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFont.fontFamily,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _propertyTypeCard(BuildContext context, String imagePath, String label,
      String selectedOption) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Column(
        children: [
          // Image card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: selectedOption == 'Property'
                    ? Border.all(color: AppColor.boxshadowColor)
                    : null,
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(height: size.height * 0.01),
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

  void filterBottomSheet(BuildContext context, screenWidth) {
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
                        Text(AppLanguage.selectActivityText[language],
                            style: TextStyle(
                                color: AppColor.primaryColor,
                                fontFamily: AppFont.fontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: screenWidth > 600 ? 20 : 16)),
                        InkWell(
                          onTap: () {
                            selectedActivityId = 0;
                            Navigator.pop(context);
                            bookingsApiCall(userId, "");
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
                              children:
                                  List.generate(activitiesList.length, (index) {
                                return Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        selectedActivityId =
                                            activitiesList[index]
                                                ['trip_type_id'];
                                        Navigator.pop(context);
                                        bookingsApiCall(
                                            userId,
                                            activitiesList[index]
                                                ['trip_type_id']);
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
                                            image: activitiesList[index]
                                                        ['image'] !=
                                                    null
                                                ? NetworkImage(
                                                    "${AppConfigProvider.imageURL}${activitiesList[index]['image']}")
                                                : const AssetImage(
                                                        AppImage.dummyIcon)
                                                    as ImageProvider,
                                            fit: BoxFit.cover,
                                            colorFilter: (selectedActivityId ==
                                                    activitiesList[index]
                                                        ['trip_type_id'])
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
                                        child: (selectedActivityId ==
                                                activitiesList[index]
                                                    ['trip_type_id'])
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
                                        activitiesList[index]['activity_name']
                                            [language],
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

  void showFilterModal(
      BuildContext context, String selectedOption, screenWidth) {
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
                            propertyBookingsApiCall(userId, "");
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
                                        propertyBookingsApiCall(
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
}
