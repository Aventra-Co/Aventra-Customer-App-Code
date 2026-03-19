import 'dart:convert';
import 'package:boatapp/controller/app_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/app_button.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_header.dart';
import '../../controller/app_language.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../authentication/login_screen.dart';

class CancelBooking extends StatefulWidget {
  static String routeName = "./CancelBooking";
  final int cancelType;
  final String tripBookingId;
  final int propertyBookingId;
  const CancelBooking(
      {super.key,
      required this.tripBookingId,
      required this.propertyBookingId,
      required this.cancelType});

  @override
  State<CancelBooking> createState() => CancelBookingState();
}

class CancelBookingState extends State<CancelBooking> {
  TextEditingController cancelTextEditingController = TextEditingController();
  int fillColorStatus = 0;
  int userId = 0;
  bool isApiCalling = false;
  dynamic userDetails;

  @override
  void initState() {
    super.initState();
    getDetails();
  }

  //-----------------------------Cancel Booking---------------------------//
  Future<dynamic> getDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userDetails = prefs.getString("userDetails");

    print("userDetails $userDetails");
    if (userDetails != null) {
      dynamic data = json.decode(userDetails);
      print("up $data");
      userId = data['user_id']; //Retrieve userId from local storage
      print('userId- $userId');
      setState(() {});
    }
  }

  //-----------------------------------REASON VALIDATION---------------------------//
  reasonValidation(String reason) {
    if (reason.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.reasonCancelMsg[language]);
      return false;
    } else {
      if (widget.cancelType == 1) {
        cancelTripApiCall(reason);
      } else {
        cancelPropertyCall(reason);
      }
    }
  }

  //---------------------------------DELETE ACCOUNT API CALL---------------------------//
  cancelTripApiCall(String reason) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}cancel_trip");
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
        'trip_booking_id': widget.tripBookingId,
        'cancle_reason': reason,
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
        final res = json.decode(response.body);
        setState(() {
          isApiCalling = false;
        });
        if (res['success'] == true) {
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          AppConstant.selectFooterIndex = 1;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyFooterPage()),
          );
        } else {
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          if (res['active_status'] == 0) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Login()));
          }
        }
      } else {
        setState(() {
          isApiCalling = false;
        });

        throw Exception('Album loading failed!');
      }
    } catch (e) {
      setState(() {
        isApiCalling = false;
      });

      print("Call Update Api");
    }
  }

  //---------------------------------DELETE ACCOUNT API CALL---------------------------//
  cancelPropertyCall(String reason) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}cancel_property_status");
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
        'property_booking_id': widget.propertyBookingId.toString(),
        'cancle_reason': reason,
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
        final res = json.decode(response.body);
        setState(() {
          isApiCalling = false;
        });
        if (res['success'] == true) {
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          AppConstant.selectFooterIndex = 1;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyFooterPage()),
          );
        } else {
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          if (res['active_status'] == 0) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Login()));
          }
        }
      } else {
        setState(() {
          isApiCalling = false;
        });

        throw Exception('Album loading failed!');
      }
    } catch (e) {
      setState(() {
        isApiCalling = false;
      });

      print("Call Update Api");
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColor.secondaryColor,
        statusBarIconBrightness: Brightness.dark));
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColor.secondaryColor,
        body: SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 100 / 100,
            width: MediaQuery.of(context).size.width * 100 / 100,
            color: AppColor.secondaryColor,
            child: Column(
              children: [
                const NoInternetBanner(),
                AppHeader(
                    text: AppLanguage.cancelBookingText[language],
                    onPress: () {
                      Navigator.pop(context);
                    }),
                // SizedBox(
                //     height: MediaQuery.of(context).size.height * 3 / 100),
                // Container(
                //   width: MediaQuery.of(context).size.width * 90 / 100,
                //   child: Text(AppLanguage.deleteReasonText[language],
                //       style: const TextStyle(
                //         fontWeight: FontWeight.w400,
                //         fontFamily: AppFont.fontFamily,
                //         color: AppColor.primaryColor,
                //         fontSize: 12,
                //       )),
                // ),

                SizedBox(height: MediaQuery.of(context).size.height * 3 / 100),
                //----------- Message Input -------------
                Container(
                  width: MediaQuery.of(context).size.width * 90 / 100,
                  child: TextFormField(
                    style: TextStyle(height: 1, color: AppColor.textColor),
                    keyboardType: TextInputType.multiline,
                    controller: cancelTextEditingController,
                    maxLines: 7,
                    maxLength: AppConstant.describeLength,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColor.textinputBorderColor,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(11)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColor.textinputBorderColor,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(11)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColor.textinputBorderColor,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(11)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 15),
                        fillColor: AppColor.secondaryColor,
                        filled: true,
                        counterText: '',
                        hintText: AppLanguage.cancelReasonText[language],
                        hintStyle: AppConstant.textFilledStyle),
                  ),
                ),

                SizedBox(
                  height: MediaQuery.of(context).size.height * 4 / 100,
                ),
                AppButton(
                  text: AppLanguage.submitButtonText[language],
                  onPress: () {
                    reasonValidation(cancelTextEditingController.text);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
