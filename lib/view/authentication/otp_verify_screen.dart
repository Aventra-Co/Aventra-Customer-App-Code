import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import '../../controller/app_button.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_footer.dart';
import '../../controller/app_header.dart';
import '../../controller/app_language.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import 'login_screen.dart';

class SignUpOtpVerifyHeader extends StatelessWidget {
  static String routeName = "./SignUpOtpVerifyHeader";
  const SignUpOtpVerifyHeader({super.key});

  @override
  Widget build(BuildContext context) {
    ResetPasswordIdClass? object;
    object = ModalRoute.of(context)!.settings.arguments as ResetPasswordIdClass;

    // print("Data retrieved ${object.email}");
    return OTP(
      userId: object.userId,
    );
  }
}

class OTP extends StatefulWidget {
  final String userId;
  const OTP({
    super.key,
    required this.userId,
  });

  @override
  State<OTP> createState() => _OTPState();
}

class _OTPState extends State<OTP> {
  TextEditingController pinController = TextEditingController();
  late Timer _timer;
  late int _secondsRemaining;
  bool resendText = true;
  bool isApiCalling = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = 120;
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer.cancel();
          resendText = false;
        }
      });
    });
  }

  // ================ Validation for OTP ==================================
  otpValidation(String otp) async {
    if (otp.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.otpMessage[language]);
    } else if (otp.length < 6) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.otpMinLenthMessage[language]);
    } else {
      verifyOTPRequest(widget.userId, otp);
    }
  }

  //================== VERIFY OTP REQUEST-------------------
  verifyOTPRequest(userId, otp) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}otp_verify");

    print("Url $url");

    setState(() {
      isApiCalling = true;
    });

    try {
      String playeID = AppConstant.playerID.toString();
      print("playeID line number 101 $playeID");
      http.MultipartRequest formData = http.MultipartRequest('POST', url);

      formData.fields['user_id'] = userId.toString();
      formData.fields['otp'] = otp.toString();

      http.StreamedResponse response = await formData.send();
      print("response--> $response");
      var responseString = await response.stream.toBytes();
      var res = jsonDecode(utf8.decode(responseString));

      if (response.statusCode == 200) {
        print("res : $res");
        if (res['success'] == true) {
          setState(() {
            isApiCalling = false;
          });
          dynamic data = res['userDataArray'];
          if (data != "NA") {
            AppConstant.selectFooterIndex = 0;
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const MyFooterPage()));

            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          }
        } else {
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          setState(() {
            isApiCalling = false;
          });
          if (res['active_status'] == 0) {
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

//---------------------RESEND OTP API CALLING--------------------------------------
  Future<void> resendOTPRequest(BuildContext context, {bool byEmail = false}) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}otp_resend");

    print("Url $url");

    setState(() {
      isApiCalling = true;
    });

    try {
      http.MultipartRequest formData = http.MultipartRequest('POST', url);

      formData.fields['user_id'] = widget.userId.toString();
      if (byEmail) {
        formData.fields['channel'] = 'email';
      }

      log("${formData.fields}");

      http.StreamedResponse response = await formData.send();
      print("response--> $response");
      var responseString = await response.stream.toBytes();
      var res = jsonDecode(utf8.decode(responseString));

      if (response.statusCode == 200) {
        print("res : $res");
        if (res['success'] == true) {
          setState(() {
            isApiCalling = false;
          });
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
        }
        else {
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          setState(() {
            isApiCalling = false;
          });
          if (res['active_status'] == 0) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Login()));
          }
        }
      }
      else {
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
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    final defaultPinTheme = PinTheme(
      width: MediaQuery.of(context).size.width * 20 / 100,
      height: MediaQuery.of(context).size.width * 12 / 100,
      margin: const EdgeInsets.only(right: 5),
      textStyle: const TextStyle(
        fontSize: 23,
        fontFamily: AppFont.fontFamily,
        fontWeight: FontWeight.w600,
        color: AppColor.violetColor,
      ),
      decoration: BoxDecoration(
        // border: Border.all(color: AppColor.greyLightColor),
        color: AppColor.textfIllColor,
        borderRadius: BorderRadius.circular(8),
      ),
    );
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColor.secondaryColor,
        statusBarIconBrightness: Brightness.dark));
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColor.secondaryColor,
        body: SafeArea(
          child: Container(
              width: MediaQuery.of(context).size.width * 100 / 100,
              color: AppColor.secondaryColor,
              child: Column(
                children: [
                  const NoInternetBanner(),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 1 / 100),
                  AppHeader(
                      text: "",
                      onPress: () {
                        Navigator.pop(context);
                      }),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 6 / 100),
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 3 / 100,
                        ),
                        Container(
                            alignment: Alignment.center,
                            child: Text(
                              AppLanguage.otpVerficationText[language],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColor.themeColor,
                                  fontSize: 30,
                                  fontFamily: AppFont.fontFamily,
                                  fontWeight: FontWeight.w800),
                            )),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 1 / 100,
                        ),
                        Container(
                            width: MediaQuery.of(context).size.width * 90 / 100,
                            alignment: Alignment.center,
                            child: Text(
                              AppLanguage.sentOtpText[language],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: AppFont.fontFamily,
                                  color: AppColor.textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400),
                            )),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 90 / 100,
                          child: Column(
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    5 /
                                    100,
                              ),
                              Pinput(
                                controller: pinController,
                                defaultPinTheme: defaultPinTheme,
                                autofocus: true,
                                length: 6,
                                hapticFeedbackType:
                                    HapticFeedbackType.lightImpact,
                                onCompleted: (pin) {},
                                onChanged: (value) {},
                                cursor: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 13),
                                      width: 15,
                                      height: 2,
                                      color: AppColor.violetColor,
                                    ),
                                  ],
                                ),
                                submittedPinTheme: defaultPinTheme.copyWith(
                                  decoration: defaultPinTheme.decoration!
                                      .copyWith(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          border: Border.all(
                                            color: AppColor.violetColor,
                                          )),
                                ),
                              ),
                              SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    4 /
                                    100,
                              ),
                            ],
                          ),
                        ),
                        AppButton(
                            text: AppLanguage.verifyButtonText[language],
                            onPress: () {
                              otpValidation(pinController.text);
                            }),
                        SizedBox(
                          height:
                              MediaQuery.of(context).size.height * 3.5 / 100,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 90 / 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontFamily: AppFont.fontFamily,
                                      color: AppColor.blueTextColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: AppLanguage
                                            .didNotReceiveSmsOtpPrefix[
                                                language],
                                      ),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: GestureDetector(
                                          onTap: () {
                                            resendOTPRequest(context,
                                                byEmail: true);
                                          },
                                          child: Text(
                                            AppLanguage
                                                .tryOtpByEmailText[language],
                                            style: const TextStyle(
                                              fontFamily: AppFont.fontFamily,
                                              color: AppColor.themeColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  AppColor.themeColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              resendText == false
                                  ? GestureDetector(
                                      onTap: () {
                                        resendOTPRequest(context);
                                        setState(
                                          () {
                                            resendText = true;
                                            _secondsRemaining = 120;
                                            startTimer();
                                          },
                                        );
                                      },
                                      child: Text(
                                        AppLanguage.resendText[language],
                                        style: const TextStyle(
                                          color: AppColor.redcolor,
                                          fontFamily: AppFont.fontFamily,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      '$minutes:${seconds.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: AppColor.redcolor,
                                        fontFamily: AppFont.fontFamily,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 2 / 100,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            AppLanguage.changeEmailText[language],
                            style: const TextStyle(
                                fontFamily: AppFont.fontFamily,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColor.blueTextColor,
                                color: AppColor.blueTextColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12),
                          ),
                        ),
                        SizedBox(
                          height:
                              MediaQuery.of(context).size.height * 26.5 / 100,
                        ),
                      ]),
                    ),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
