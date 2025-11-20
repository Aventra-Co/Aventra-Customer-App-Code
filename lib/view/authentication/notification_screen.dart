import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../other_screen/broadcastScreen.dart';
import '../other_screen/completed_details_screen.dart';
import '../other_screen/onging_details_screen.dart';
import '../other_screen/upcoming_details_screen.dart';
import 'login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;

class NotificationScreen extends StatefulWidget {
  static String routeName = "./NotificationScreen";
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> notificationarraylist = <dynamic>[];
  bool isApiCalling = true;
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
    fetchNotificationApi(userId);
    setState(() {});
  }

  //=============================GET Notification DETAILS===================================//
  Future<void> fetchNotificationApi(userId) async {
    setState(() {
      isApiCalling = true;
    });
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_all_notifications?user_id=$userId");
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
        print("res $res");

        if (res['success'] == true) {
          var item = res['notification_arr'];
          notificationarraylist = (item != "NA") ? item : [];
          setState(() {
            isApiCalling = false;
          });
        } else {
          notificationarraylist = [];
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
        print("Error: ${response.statusCode}");
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (e) {
      print("Exception: $e");
      setState(() {
        isApiCalling = false;
      });
    }
  }

  //==================Delete Single Notification================
  Future<void> deleteSingleNotificationApiCall(notificationId) async {
    Uri url =
        Uri.parse("${AppConfigProvider.apiUrl}delete_single_notification");
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
        'notification_message_id': notificationId.toString(),
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
          fetchNotificationApi(userId);
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          setState(() {
            isApiCalling = false;
          });
        } else {
          setState(() {
            isApiCalling = false;
          });
          // ignore: use_build_context_synchronously
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
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

  //==================Delete All Notification================
  Future<void> clearAllNotificationApiCall() async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}clear_all_notification");
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
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          fetchNotificationApi(userId);
          setState(() {
            isApiCalling = false;
          });
        } else {
          setState(() {
            isApiCalling = false;
          });
          // ignore: use_build_context_synchronously
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
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

  Future<void> checkStatusApiCall(tripId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_trip_status?trip_booking_id=$tripId");
    print("url $url");
    // setState(() {
    //   isApiCalling = true;
    // });
    String token = AppConstant.token;

    if (token.isEmpty) {
      print("Token is missing!");
      // return;
    }

    Map<String, String> headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);
      print("response $response");

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print("res $res");

        if (res['success'] == true) {
          if (res['trip_status'] == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UpComingDetailsScreen(
                  tripId: tripId.toString(),
                ),
              ),
            );
          } else if (res['trip_status'] == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OngoingDetailsScreen(
                  tripId: tripId.toString(),
                ),
              ),
            );
          } else if (res['trip_status'] == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CompletedDetailsScreen(
                  tripBookingId: tripId.toString(),
                  isCancelled: 2,
                ),
              ),
            );
          }

          setState(() {
            isApiCalling = false;
          });
        } else {
          setState(() {
            isApiCalling = false;
          });
          // ignore: use_build_context_synchronously
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
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
  Widget build(BuildContext context) {
    return ProgressHUD(
        inAsyncCall: isApiCalling,
        opacity: 0.5,
        child: _buildUIScreen(context));
  }

  Widget _buildUIScreen(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection:
              language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: Container(
            width: MediaQuery.of(context).size.width * 100 / 100,
            height: MediaQuery.of(context).size.height * 100 / 100,
            color: AppColor.secondaryColor,
            child: Column(
              children: [
                const NoInternetBanner(),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 90 / 100,
                  height: MediaQuery.of(context).size.height * 12 / 100,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Transform.rotate(
                          angle: language == 1 ? 3.1416 : 0,
                          child: SizedBox(
                            width: screenWidth > 600
                                ? MediaQuery.of(context).size.width * 5 / 100
                                : MediaQuery.of(context).size.width * 7 / 100,
                            height: screenWidth > 600
                                ? MediaQuery.of(context).size.width * 5 / 100
                                : MediaQuery.of(context).size.width * 7 / 100,
                            child: Image.asset(
                              AppImage.navigateBackIcon,
                              color: AppColor.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 3 / 100,
                      ),
                      Container(
                        child: Text(
                          AppLanguage.notificationsText[language],
                          style: const TextStyle(
                              color: AppColor.primaryColor,
                              fontFamily: AppFont.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 20),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          if (notificationarraylist.isNotEmpty) {
                            clearAllNotificationApiCall();
                          }
                        },
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 15 / 100,
                          height: MediaQuery.of(context).size.width * 6 / 100,
                          child: Text(AppLanguage.clearAllText[language],
                              style: const TextStyle(
                                  color: AppColor.primaryColor,
                                  fontFamily: AppFont.fontFamily,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),

                //! Notification list
                if (notificationarraylist.isNotEmpty && isApiCalling == false)
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 0),
                      width: MediaQuery.of(context).size.width * 95 / 100,
                      child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemCount: notificationarraylist.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Column(
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100,
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (notificationarraylist[index]['action'] ==
                                      "trip_cancellation") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CompletedDetailsScreen(
                                          tripBookingId:
                                              notificationarraylist[index]
                                                      ['action_id']
                                                  .toString(),
                                          isCancelled: 3,
                                        ),
                                      ),
                                    );
                                  } else if (notificationarraylist[index]
                                          ['action'] ==
                                      "trip_booking") {
                                    checkStatusApiCall(
                                        notificationarraylist[index]
                                                ['action_id']
                                            .toString());
                                  } else if (notificationarraylist[index]
                                          ['action'] ==
                                      "Broadcast") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BroadcastScreen(
                                          broadCastDetails:
                                              notificationarraylist[index],
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  color: AppColor.secondaryColor,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                2 /
                                                100,
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                10 /
                                                100,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                10 /
                                                100,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          child: (notificationarraylist[index]
                                                          ['user_image'] !=
                                                      null &&
                                                  notificationarraylist[index]
                                                          ['user_image'] !=
                                                      "NA")
                                              ? Image.network(
                                                  '${AppConfigProvider.imageURL}${notificationarraylist[index]['user_image']}',
                                                  fit: BoxFit.cover,
                                                  loadingBuilder:
                                                      (BuildContext context,
                                                          Widget child,
                                                          ImageChunkEvent?
                                                              loadingProgress) {
                                                    if (loadingProgress ==
                                                        null) {
                                                      return child;
                                                    } else {
                                                      return Shimmer.fromColors(
                                                        baseColor: Colors
                                                            .grey.shade300,
                                                        highlightColor: Colors
                                                            .grey.shade100,
                                                        child: Container(
                                                          color: Colors
                                                              .grey.shade300,
                                                        ),
                                                      );
                                                    }
                                                  },
                                                )
                                              : Image.asset(
                                                  AppImage
                                                      .profilePlaceholderImage,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                3 /
                                                100,
                                      ),
                                      Column(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                78 /
                                                100,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                (notificationarraylist[index]
                                                            ['action'] ==
                                                        "trip_booking")
                                                    ? SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            55 /
                                                            100,
                                                        child: Text(
                                                          '${AppLanguage.bookingIdText[language]}: #${notificationarraylist[index]['random_booking_id']}',
                                                          textAlign:
                                                              TextAlign.start,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                              color: AppColor
                                                                  .themeColor,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                      )
                                                    : SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            55 /
                                                            100,
                                                        child: Text(
                                                          '${notificationarraylist[index]['title'][language]}',
                                                          textAlign:
                                                              TextAlign.start,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                              color: AppColor
                                                                  .themeColor,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                      ),
                                                Text(
                                                  notificationarraylist[index]
                                                      ['date_time'],
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        AppFont.fontFamily,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        AppColor.primaryColor,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                78 /
                                                100,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      70 /
                                                      100,
                                                  child: Text(
                                                    '${notificationarraylist[index]['message'][language]}',
                                                    textAlign: TextAlign.start,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        color: AppColor
                                                            .primaryColor,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    deleteSingleNotificationApiCall(
                                                        notificationarraylist[
                                                                index][
                                                            'notification_message_id']);
                                                  },
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            4 /
                                                            100,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            4 /
                                                            100,
                                                    child: Image.asset(
                                                      AppImage.crossIcon,
                                                      fit: BoxFit.cover,
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

                              //! ==== Boader ===
                              SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                child: Divider(
                                  thickness: 1,
                                  color: AppColor.boaderColor,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ), //: Container(),

                if (notificationarraylist.isEmpty && isApiCalling == false)
                  Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                      ),
                      SizedBox(
                        width: screenWidth * 0.7,
                        child: Text(
                          AppLanguage.notificationNoDataMsg[language],
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
      ),
    );
  }
}
