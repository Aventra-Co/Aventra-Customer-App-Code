import 'dart:convert';
import 'package:boatapp/view/other_screen/publicBookingFlow/public_trip_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_font.dart';
import '../../controller/app_constant.dart';
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
  static String routeName = "./BookingHistory";
  const BookingHistory({super.key});

  @override
  State<BookingHistory> createState() => _BookingHistoryState();
}

class _BookingHistoryState extends State<BookingHistory> {
  List<dynamic> bookingHistoryList = [];
  bool isApiCalling = false;
  bool isLoading = true;
  int userId = 0;
  dynamic token;
  dynamic userDetails;

  @override
  void initState() {
    super.initState();
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

  var refreshKey = GlobalKey<RefreshIndicatorState>();

  //--------------------REFRESH FUNCION-----------------------//
  Future<Null> _refreshPage() async {
    refreshKey.currentState?.show(atTop: false);
    await Future.delayed(const Duration(seconds: 1));
    // getTopStories(0);
    getUserDetails();
    return null;
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
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return Scaffold(
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
                    Navigator.pop(context);
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 15,
                                                      horizontal: 15),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color:
                                                      AppColor.textfIllColor),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            20 /
                                                            100,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            20 /
                                                            100,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: bookingHistoryList[
                                                                      index][
                                                                  'trip_image'] !=
                                                              null
                                                          ? Image.network(
                                                              '${AppConfigProvider.imageURL}${bookingHistoryList[index]['trip_image']}',
                                                              fit: BoxFit.cover,
                                                              loadingBuilder:
                                                                  (BuildContext
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
                                                                    highlightColor:
                                                                        Colors
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
                                                              fit: BoxFit.cover,
                                                            ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
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
                                                                FontWeight.w600,
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
                                                                FontWeight.w600,
                                                            fontSize: 14),
                                                      ),
                                                      SizedBox(
                                                        width: screenWidth > 600
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
                                                              "KWD ${bookingHistoryList[index]["total_amount"].toString()}",
                                                              style: const TextStyle(
                                                                  color: AppColor
                                                                      .hintTextinputColor,
                                                                  fontFamily:
                                                                      AppFont
                                                                          .fontFamily,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 14),
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
                                                              bookingHistoryList[
                                                                              index]
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
                                                                  color: bookingHistoryList[index]
                                                                              [
                                                                              "trip_status"] ==
                                                                          3
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
                                                                  fontSize: 12),
                                                            ),
                                                            const Spacer(),
                                                            InkWell(
                                                              onTap: () {
                                                                if (bookingHistoryList[
                                                                            index]
                                                                        [
                                                                        'advertisement_type'] ==
                                                                    0) {
                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              PrivateTripDetailsScreen(tripId: bookingHistoryList[index]['trip_id'].toString())));
                                                                } else {
                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              PublicTripDetailsScreen(tripId: bookingHistoryList[index]['trip_id'].toString())));
                                                                }
                                                              },
                                                              child: Container(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    18 /
                                                                    100,
                                                                height: MediaQuery.of(
                                                                            context)
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
                                                                      fontFamily:
                                                                          AppFont
                                                                              .fontFamily,
                                                                      fontWeight:
                                                                          FontWeight
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
                              if (bookingHistoryList.isEmpty)
                                Column(
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
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
    );
  }
}
