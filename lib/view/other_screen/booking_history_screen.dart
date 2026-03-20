import 'dart:convert';
import 'package:boatapp/view/other_screen/publicBookingFlow/public_trip_details.dart';
import 'package:boatapp/view/property_screens/property_bookinghistory_screen.dart';
import 'package:boatapp/view/property_screens/property_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_font.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_footer.dart';
import '../../controller/app_header.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import '../../controller/app_loader.dart';
import '../../controller/app_shimmers.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../authentication/login_screen.dart';
import 'completed_details_screen.dart';
import 'privateBookingFlow/private_trip_details.dart';

class BookingHistory extends StatefulWidget {
  final int selectedTab;
  static String routeName = "./BookingHistory";
  const BookingHistory({super.key, this.selectedTab = 0});

  @override
  State<BookingHistory> createState() => _BookingHistoryState();
}

class _BookingHistoryState extends State<BookingHistory> {
  List<dynamic> bookingHistoryList = [];
  List<dynamic> propBookingHistoryList = [];
  bool isApiCalling = false;
  bool isLoading = true;
  int userId = 0;
  dynamic token;
  dynamic userDetails;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.selectedTab;

    getUserDetails();
  }

//--------------------GET USER DETAILS-----------------------//
  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userDetails = prefs.getString("userDetails");
    token = prefs.getString("token");
    // setState(() {
    //   isApiCalling = true;
    // });

    // print("userDetails $userDetails");
    if (userDetails != null) {
      dynamic data = json.decode(userDetails);
      print("up ${data}");
      userId = data['user_id'];
      print('67$userId');
    }

    getBookingHistoryApi(userId);
    getPropBookingHistoryApi(userId);
    setState(() {});
  }

//=============================GET FAQS DETAILS===================================//
  Future<void> getBookingHistoryApi(userId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_user_trip_history?user_id=$userId");
    print("url $url");

    String token = AppConstant.token;

    if (token.isEmpty) {
      print("Token is missing!");
      return;
    }

    Map<String, String> headers = {
      'Authorization': 'Bearer $token', // Use 'Bearer' if required
    };

    setState(() {
      isLoading = true;
    });

    print("headers $headers");

    try {
      final response = await http.get(url, headers: headers);
      print("response $response");

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print("res $res");

        if (res['success'] == true) {
          var item = res['trip_array'];
          bookingHistoryList = (item != "NA") ? item : [];

          setState(() {
            isLoading = false;
          });
        } else {
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(
                context, res['message'][language]);
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

//=============================GET FAQS DETAILS===================================//
  Future<void> getPropBookingHistoryApi(userId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_property_history_booking?user_id=$userId");
    print("url $url");

    String token = AppConstant.token;

    if (token.isEmpty) {
      print("Token is missing!");
      return;
    }

    Map<String, String> headers = {
      'Authorization': 'Bearer $token', // Use 'Bearer' if required
    };

    setState(() {
      isLoading = true;
    });

    print("headers $headers");

    try {
      final response = await http.get(url, headers: headers);
      print("response $response");

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print("res $res");

        if (res['success'] == true) {
          var item = res['data'];
          propBookingHistoryList = (item != "NA") ? item : [];

          setState(() {
            isLoading = false;
          });
        } else {
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(
                context, res['message'][language]);
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

  var refreshKey = GlobalKey<RefreshIndicatorState>();

  //--------------------REFRESH FUNCION-----------------------//
  Future<Null> _refreshPage() async {
    refreshKey.currentState?.show(atTop: false);
    await Future.delayed(const Duration(seconds: 1));
    // getTopStories(0);
    getUserDetails();
    return null;
  }

  int selectedTab = 0;
  String selectedOption = "Sea";
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
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return WillPopScope(
      onWillPop: () {
        AppConstant.selectFooterIndex = 1;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyFooterPage(selectedTab: 4),
          ),
        );
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: AppColor.secondaryColor,
        body: SafeArea(
            child: Directionality(
          textDirection:
              language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: RefreshIndicator(
            onRefresh: _refreshPage,
            color: AppColor.themeColor,
            child: Container(
              width: MediaQuery.of(context).size.width * 100 / 100,
              height: MediaQuery.of(context).size.height * 100 / 100,
              color: AppColor.secondaryColor,
              child: Column(
                children: [
                  const NoInternetBanner(),
                  AppHeader(
                    text: AppLanguage.bookingHistoryText[language],
                    onPress: () {
                      AppConstant.selectFooterIndex = 4;
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyFooterPage()));
                    },
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 3 / 100,
                  ),
                  isLoading
                      ? bookingHistoryShimmerEffect(context)
                      : Expanded(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: size.width * 0.04),
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                  height: MediaQuery.of(context).size.height *
                                      3 /
                                      100,
                                ),
                                if (selectedTab != 0)
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: size.width * 0.05),
                                    child: _buildPropertyList(context),
                                  ),
                                if (selectedTab == 0)
                                  if (bookingHistoryList.isNotEmpty)
                                    Wrap(
                                      children: List.generate(
                                        bookingHistoryList.length,
                                        (index) {
                                          return Column(
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          CompletedDetailsScreen(
                                                        tripBookingId:
                                                            bookingHistoryList[
                                                                        index][
                                                                    'trip_booking_id']
                                                                .toString(),
                                                        isCancelled:
                                                            bookingHistoryList[
                                                                    index]
                                                                ['trip_status'],
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      90 /
                                                      100,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 15,
                                                      horizontal: 15),
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      color: AppColor
                                                          .textfIllColor),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            20 /
                                                            100,
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            20 /
                                                            100,
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          child: bookingHistoryList[
                                                                          index]
                                                                      [
                                                                      'trip_image'] !=
                                                                  null
                                                              ? Image.network(
                                                                  '${AppConfigProvider.imageURL}${bookingHistoryList[index]['trip_image']}',
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  loadingBuilder: (BuildContext
                                                                          context,
                                                                      Widget
                                                                          child,
                                                                      ImageChunkEvent?
                                                                          loadingProgress) {
                                                                    if (loadingProgress ==
                                                                        null) {
                                                                      return child;
                                                                    } else {
                                                                      return Shimmer
                                                                          .fromColors(
                                                                        baseColor: Colors
                                                                            .grey
                                                                            .shade300,
                                                                        highlightColor: Colors
                                                                            .grey
                                                                            .shade100,
                                                                        child:
                                                                            Container(
                                                                          color: Colors
                                                                              .grey
                                                                              .shade300,
                                                                        ),
                                                                      );
                                                                    }
                                                                  },
                                                                )
                                                              : Image.asset(
                                                                  AppImage
                                                                      .imageFrameImage,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            2 /
                                                            100,
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            bookingHistoryList[
                                                                        index][
                                                                    "boat_name_english"] ??
                                                                "",
                                                            style: const TextStyle(
                                                                color: AppColor
                                                                    .primaryColor,
                                                                fontFamily: AppFont
                                                                    .fontFamily,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 16),
                                                          ),
                                                          SizedBox(
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                .5 /
                                                                100,
                                                          ),
                                                          Text(
                                                            bookingHistoryList[
                                                                index]["date"],
                                                            style: const TextStyle(
                                                                color: AppColor
                                                                    .hintTextinputColor,
                                                                fontFamily: AppFont
                                                                    .fontFamily,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 14),
                                                          ),
                                                          SizedBox(
                                                            width: screenWidth >
                                                                    600
                                                                ? MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    60 /
                                                                    100
                                                                : MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    58 /
                                                                    100,
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  "${bookingHistoryList[index]["total_amount"].toString()} KWD",
                                                                  style: const TextStyle(
                                                                      color: AppColor
                                                                          .hintTextinputColor,
                                                                      fontFamily:
                                                                          AppFont
                                                                              .fontFamily,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontSize:
                                                                          14),
                                                                ),
                                                                SizedBox(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      3 /
                                                                      100,
                                                                ),
                                                                Text(
                                                                  bookingHistoryList[index]
                                                                              [
                                                                              "trip_status"] ==
                                                                          3
                                                                      ? AppLanguage
                                                                              .cancelledText[
                                                                          language]
                                                                      : AppLanguage
                                                                              .completedText[
                                                                          language],
                                                                  style: TextStyle(
                                                                      color: bookingHistoryList[index]["trip_status"] == 3
                                                                          ? AppColor
                                                                              .redcolor
                                                                          : AppColor
                                                                              .themeColor,
                                                                      fontFamily:
                                                                          AppFont
                                                                              .fontFamily,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      fontSize:
                                                                          12),
                                                                ),
                                                                const Spacer(),
                                                                InkWell(
                                                                  onTap: () {
                                                                    if (bookingHistoryList[index]
                                                                            [
                                                                            'advertisement_type'] ==
                                                                        0) {
                                                                      Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) => PrivateTripDetailsScreen(tripId: bookingHistoryList[index]['trip_id'].toString())));
                                                                    } else {
                                                                      Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) => PublicTripDetailsScreen(tripId: bookingHistoryList[index]['trip_id'].toString())));
                                                                    }
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        18 /
                                                                        100,
                                                                    height: MediaQuery.of(context)
                                                                            .size
                                                                            .height *
                                                                        3.2 /
                                                                        100,
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    decoration: BoxDecoration(
                                                                        border: Border.all(
                                                                            color: AppColor
                                                                                .themeColor),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                                20),
                                                                        color: AppColor
                                                                            .secondaryColor),
                                                                    child: Text(
                                                                      AppLanguage
                                                                              .rebookText[
                                                                          language],
                                                                      style: const TextStyle(
                                                                          color: AppColor
                                                                              .themeColor,
                                                                          fontFamily: AppFont
                                                                              .fontFamily,
                                                                          fontWeight: FontWeight
                                                                              .w500,
                                                                          fontSize:
                                                                              12),
                                                                    ),
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
                                              ),
                                              SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    1.5 /
                                                    100,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                if (selectedTab == 0)
                                  if (bookingHistoryList.isEmpty)
                                    Column(
                                      children: [
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.3,
                                        ),
                                        SizedBox(
                                          width: screenWidth * 0.7,
                                          child: Text(
                                            AppLanguage.noHistoryMsg[language],
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontFamily: AppFont.fontFamily,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColor.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildPropertyList(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: List.generate(
        propBookingHistoryList.length,
        (index) {
          final property = propBookingHistoryList[index];
          final isCompleted = property['booking_status'] == 2;
          final isCancelled = property['booking_status'] == 3;

          return Padding(
            padding: EdgeInsets.only(bottom: size.height * 0.015),
            child: InkWell(
              onTap: () {
                if (isCompleted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyBookingHistoryDetailScreen(
                        propertyBookingId: property['property_booking_id'],
                        iscompleted: true,
                      ),
                    ),
                  );
                }
                if (isCancelled) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyBookingHistoryDetailScreen(
                        propertyBookingId: 1,
                        iscompleted: false,
                        cancelReason: "",
                      ),
                    ),
                  );
                }
              },
              child: Container(
                width: size.width * 0.90,
                padding: EdgeInsets.all(size.width * 0.04),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColor.textfIllColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property image
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 20 / 100,
                      height: MediaQuery.of(context).size.width * 20 / 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: property['cover_image'] != null
                            ? Image.network(
                                '${AppConfigProvider.imageURL}${property['cover_image']}',
                                fit: BoxFit.cover,
                                loadingBuilder: (BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  } else {
                                    return Shimmer.fromColors(
                                      baseColor: Colors.grey.shade300,
                                      highlightColor: Colors.grey.shade100,
                                      child: Container(
                                        color: Colors.grey.shade300,
                                      ),
                                    );
                                  }
                                },
                              )
                            : Image.asset(
                                AppImage.imageFrameImage,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),

                    SizedBox(width: size.width * 0.03),

                    // Property details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Property name
                          Text(
                            property['property_name_english'] ?? "",
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: AppFont.fontFamily,
                              fontWeight: FontWeight.w600,
                              color: AppColor.primaryColor,
                            ),
                          ),

                          SizedBox(height: size.height * 0.005),

                          // Date
                          Text(
                            property['checkin_date'] ?? "",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppFont.fontFamily,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          SizedBox(height: size.height * 0.008),

                          // Amount, Status, Rebook button
                          Row(
                            children: [
                              // Amount
                              Text(
                                "${property['total_amount'] ?? "NA"} KWD",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: AppFont.fontFamily,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),

                              SizedBox(width: size.width * 0.03),

                              // Status
                              Text(
                                isCancelled
                                    ? AppLanguage.cancelledText[language]
                                    : AppLanguage.completedText[language],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: AppFont.fontFamily,
                                  fontWeight: FontWeight.w500,
                                  color: isCancelled
                                      ? AppColor.redcolor
                                      : AppColor.themeColor,
                                ),
                              ),

                              const Spacer(),

                              // Rebook button
                              InkWell(
                                onTap: () {
                                  // Navigate to property details
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PropertyDetailsScreen(
                                        propertyAdId:
                                            propBookingHistoryList[index]
                                                ['property_ad_id'],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: size.width * 0.04,
                                    vertical: size.height * 0.008,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColor.themeColor,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    color: AppColor.secondaryColor,
                                  ),
                                  child: Text(
                                    AppLanguage.rebookText[language],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: AppFont.fontFamily,
                                      fontWeight: FontWeight.w500,
                                      color: AppColor.themeColor,
                                    ),
                                  ),
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
            ),
          );
        },
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
}
