import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/app_button.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_header.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../../controller/custom_input.dart';
import 'forgetPassword_otpverify_screen.dart';
import 'login_screen.dart';

class ForgotPassword extends StatefulWidget {
  static String routeName = './ForgotPassword';
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  TextEditingController emailTextEditingController = TextEditingController();
  bool isApiCalling = false;

  //---------------------------------FORGOT PASS EMAIL VALIDATION--------------------------
  forgotPasswordEmailValidation(String email) {
    if (email.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.emailMessage[language]);
      return;
    } else if (!AppConstant.emailValidatorRegExp.hasMatch(email)) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.emailValidMessage[language]);
      return;
    } else {
      forgetPasswordRequestApiCall(email);
    }
  }

  //-----------------------forgot passward---------------
  forgetPasswordRequestApiCall(email) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}forgot_password");

    print("Url $url");

    setState(() {
      isApiCalling = true;
    });

    try {
      String playeID = AppConstant.playerID.toString();
      print("playeID line number 101 $playeID");
      http.MultipartRequest formData = http.MultipartRequest('POST', url);

      formData.fields['email'] = email.toString();

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
          if (res["userDataArray"] != null) {
            var userData = res["userDataArray"];
            int userId = userData["user_id"];
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setInt('user_id', userId);
            Navigator.pushNamed(
                context, ForgetPasswordOtpVerifyHeader.routeName,
                arguments: ForgotOtpResendEmailClass(
                    email: email, userId: userId.toString()));
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          } else {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          }
        } else {
          // ignore: use_build_context_synchronously
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
        body: SafeArea(
          child: Container(
              height: MediaQuery.of(context).size.height * 100 / 100,
              width: MediaQuery.of(context).size.width * 100 / 100,
              color: AppColor.secondaryColor,
              child: Column(
                children: [
                  const NoInternetBanner(),
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 1 / 100,
                          ),
                          AppHeader(
                              text: AppLanguage
                                  .forgotPasswordHeaderText[language],
                              onPress: () {
                                Navigator.pop(context);
                              }),

                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 3 / 100,
                          ),

                          // --------------email -------------
                          CustomTextFormField(
                              readOnly: false,
                              fillColorStatus: 0,
                              controller: emailTextEditingController,
                              hintText: AppLanguage.emailInputText[language],
                              image: AppImage.emailcon,
                              keyboardtype: TextInputType.text,
                              maxLength: AppConstant.fullnameLength),

                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 4 / 100),

                          AppButton(
                              text: AppLanguage.sendButtonText[language],
                              onPress: () {
                                forgotPasswordEmailValidation(
                                    emailTextEditingController.text);
                              }),
                        ],
                      ),
                    ),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
