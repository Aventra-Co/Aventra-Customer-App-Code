import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../controller/app_button.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_header.dart';
import '../../controller/app_language.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../../controller/custom_password.dart';
import 'login_screen.dart';

class ResetPasswordHeader extends StatelessWidget {
  static const routeName = './ResetPasswordHeader';
  const ResetPasswordHeader({super.key});

  @override
  Widget build(BuildContext context) {
    ResetPasswordIdClass? object;
    object = ModalRoute.of(context)!.settings.arguments as ResetPasswordIdClass;

    return ResetPassword(
      userId: object.userId,
    );
  }
}

class ResetPassword extends StatefulWidget {
  final String userId;
  const ResetPassword({
    super.key,
    required this.userId,
  });

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController confirmpasswordTextEditingController =
      TextEditingController();
  bool isApiCalling = false;

  //--------------------------------------RESET PASSWORD VALIDATION---------------------------//
  resetPasswordValidation(String password, String confirmpass) {
    if (password.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.newPasswordMsg[language]);
    } else if (password.length < 6) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.passwordMinMessage[language]);
    } else if (confirmpass.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.repeatPasswordMsg[language]);
    } else if (confirmpass.length < 6) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.passwordMinMessage[language]);
    } else if (password != confirmpass) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.newPasswordandConfirmpassMessage[language]);
    } else {
      createNewPasswordRequest(widget.userId, password);
    }
  }

  // ---------------------CREATE NEW PASSWORD API CALL-------------------//
  createNewPasswordRequest(userId, password) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}forgot_change_password");

    print("Url $url");

    setState(() {
      isApiCalling = true;
    });

    try {
      http.MultipartRequest formData = http.MultipartRequest('POST', url);

      formData.fields['user_id'] = userId.toString();
      formData.fields['new_password'] = password.toString();

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
          // ignore: use_build_context_synchronously
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          //FirebaseProvider.firebaseCreateUser(true);
          // ignore: use_build_context_synchronously
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
          );
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
    return WillPopScope(
      onWillPop: () {
        sureGoBackBottomSheet(context);
        return Future.value(false);
      },
      child: GestureDetector(
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
                      physics: NeverScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 2 / 100,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 90 / 100,
                            child: Row(
                              children: [
                                AppHeader(
                                    text:
                                        AppLanguage.resetPasswordText[language],
                                    onPress: () {
                                      sureGoBackBottomSheet(context);
                                    }),
                              ],
                            ),
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 2 / 100,
                          ),
                          Column(
                            children: [
                              // -----------Password Text Input -------------
                              CustomPasswordTextFormField(
                                  readOnly: false,
                                  fillColorStatus: 0,
                                  controller: passwordTextEditingController,
                                  hintText:
                                      AppLanguage.newPasswordText[language],
                                  keyboardtype: TextInputType.visiblePassword,
                                  maxLength: AppConstant.passwordLength),

                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      1.5 /
                                      100),

                              // ----------- Confirm Password Text Input -------------
                              CustomPasswordTextFormField(
                                  readOnly: false,
                                  fillColorStatus: 0,
                                  controller:
                                      confirmpasswordTextEditingController,
                                  hintText: AppLanguage
                                      .confirmPasswordInputText[language],
                                  keyboardtype: TextInputType.visiblePassword,
                                  maxLength: AppConstant.passwordLength),

                              SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    6 /
                                    100,
                              ),

                              AppButton(
                                text: AppLanguage.updateButtonText[language],
                                onPress: () {
                                  resetPasswordValidation(
                                      passwordTextEditingController.text,
                                      confirmpasswordTextEditingController
                                          .text);
                                },
                              )
                            ],
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 50 / 100,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )),
        )),
      ),
    );
  }

  void sureGoBackBottomSheet(BuildContext context) {
    Widget cancelButton = TextButton(
      child: Text(
        AppLanguage.noText[language],
        style: TextStyle(
            fontFamily: AppFont.fontFamily,
            color: AppColor.redcolor,
            fontSize: 14,
            fontWeight: FontWeight.w600),
      ),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: Text(
        AppLanguage.yesText[language],
        style: TextStyle(
            fontFamily: AppFont.fontFamily,
            color: AppColor.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Login(),
          ),
        );
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text(
        AppLanguage.backText[language],
        style: TextStyle(
            fontFamily: AppFont.fontFamily,
            color: AppColor.primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w500),
      ),
      content: Text(
        AppLanguage.sureGoBackText[language],
        style: TextStyle(
            fontFamily: AppFont.fontFamily,
            color: AppColor.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w400),
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

}
