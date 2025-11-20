import 'dart:convert';
import 'dart:ui' as ui;
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
import '../../controller/custom_password.dart';
import 'login_screen.dart';

class ChangePassword extends StatefulWidget {
  static String routeName = './ChangePassword';
  const ChangePassword({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  TextEditingController currentPasswordTextEditingController =
      TextEditingController();
  TextEditingController newPasswordTextEditingController =
      TextEditingController();
  TextEditingController confirmPasswordTextEditingController =
      TextEditingController();
  bool isPasswordVisible = true;
  bool isNewPasswordVisible = true;
  bool isConfirmPasswordVisible = true;

  @override
  void dispose() {
    super.dispose();
  }

  dynamic userDetails;
  int userId = 0;
  bool isApiCalling = false;

  @override
  void initState() {
    super.initState();
    getDetails();
  }

//============================GET DETAILS=======================
  Future<dynamic> getDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userDetails = prefs.getString("userDetails");

    // print("userDetails $userDetails");
    if (userDetails != null) {
      dynamic data = json.decode(userDetails);
      print("up ${data}");
      userId = data['user_id'];
    } else {}
    setState(() {});
  }

//================================CHANGE PASSWORD VALIDATION=================
  passwordValidation(
      String currPassword, String newPassword, String confirmNewPassword) {
    if (currPassword.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.currPasswordMsg[language]);
      return false;
    } else if (currPassword.length < 6) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.passwordMinMessage[language]);
      return false;
    } else if (newPassword.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.newPasswordMsg[language]);
      return false;
    } else if (newPassword.length < 6) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.passwordMinMessage[language]);
      return false;
    } else if (confirmNewPassword.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.confirmNewPasswordMsg[language]);
      return false;
    } else if (confirmNewPassword.length < 6) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.passwordMinMessage[language]);
      return false;
    } else if (confirmNewPassword != newPassword) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.newPasswordandConfirmNewPassMessage[language]);
      return false;
    } else {
      changePasswordApiCall(newPassword);
    }
  }

//-------------------------------CHANGE PASS API CALL----------------------------------//
  changePasswordApiCall(String password) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}change_password");
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
        'current_password': currentPasswordTextEditingController.text,
        'new_password': password,
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
          print('Password Changed');
          final prefs = await SharedPreferences.getInstance();
          prefs.setString("password", password);
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          Navigator.pop(context);
          // AppConstant.selectFooterIndex = 3;
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => const MyFooterPage(),
          //   ),
          // );
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
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColor.secondaryColor,
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
                AppHeader(
                  text: AppLanguage.changePasswordText[language],
                  onPress: () {
                    Navigator.pop(context);
                  },
                ),
                Expanded(
                    child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 3 / 100,
                      ),
                      CustomPasswordTextFormField(
                        controller: currentPasswordTextEditingController,
                        fillColorStatus: 0,
                        hintText: AppLanguage.currentPasswordText[language],
                        maxLength: AppConstant.passwordLength,
                        readOnly: false,
                        keyboardtype: TextInputType.text,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 2 / 100,
                      ),
                      CustomPasswordTextFormField(
                        controller: newPasswordTextEditingController,
                        fillColorStatus: 0,
                        hintText: AppLanguage.newPasswordText[language],
                        maxLength: AppConstant.passwordLength,
                        readOnly: false,
                        keyboardtype: TextInputType.text,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 2 / 100,
                      ),
                      CustomPasswordTextFormField(
                        controller: confirmPasswordTextEditingController,
                        fillColorStatus: 0,
                        hintText: AppLanguage.confirmNewPasswordText[language],
                        maxLength: AppConstant.passwordLength,
                        readOnly: false,
                        keyboardtype: TextInputType.text,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 6 / 100,
                      ),
                      AppButton(
                          text: AppLanguage.updateButtonText[language],
                          onPress: () {
                            passwordValidation(
                                currentPasswordTextEditingController.text,
                                newPasswordTextEditingController.text,
                                confirmPasswordTextEditingController.text);
                          })
                    ],
                  ),
                ))
              ],
            ),
          ),
        )),
      ),
    );
  }
}
