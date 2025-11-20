import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_color.dart';
import 'app_connectivity.dart';
import 'app_font.dart';
import 'app_language.dart';
import 'package:provider/provider.dart';

int language = 0;
bool isGuest = false;

class AppConstant {
  static int languageNav = 0;
  static const int fullnameLength = 50;
  static const int emailMaxLength = 100;
  static const int mobileLength = 15;
  static const int passwordLength = 16;
  static const int searchLength = 30;
  static const int describeLength = 500;
  static bool isLoggedOut = false;
  static int selectFooterIndex = 0;
  static String temperature = '28';
  static String unit = '°C';
  static String weatherDesc = AppLanguage.clearSkyText[language];
  static String weatherIcon = '☀️';
  static String token = "";
  static String weatherKey = "iw1HuqjddUHzaFmb";
  static String playerID = "12345";
  static String oneSignalAppId = "e55e569a-73a2-409d-bfa3-b790d8ec642d";
  static final RegExp emailValidatorRegExp =
      RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  static String appId = "1:83903925512:web:05db133012c6cbcc7bb0bd";
  static String apiKey = "AIzaSyB8FxTSDhhEmL8rFwW5qdDYECEyHX_ul_0";
  // static String apiKey = "AIzaSyAlmy6hvQysu1m7UhhevgFpuhzXkHHdhJ0";
  static String messagingSenderId = "83903925512";
  static String projectId = "my-boat-a9c54";
      static dynamic onlyDigitFormatter = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')) // only digits allowed
  ];
  static dynamic alphaNumericFormatter = [
    FilteringTextInputFormatter.allow(
        RegExp(r'[a-zA-Z0-9]')) // alphanumeric allowed
  ];

  static var deviceType = Platform.isAndroid ? 'android' : 'ios';

  static const TextStyle textFilledStyle = TextStyle(
      color: AppColor.textColor,
      fontFamily: AppFont.fontFamily,
      fontWeight: FontWeight.w500,
      fontSize: 14);

  static const TextStyle textHeadingStyle = TextStyle(
      fontFamily: AppFont.fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 23,
      color: AppColor.textColor);

  static const TextStyle textFilledHeading = TextStyle(
      color: AppColor.primaryColor,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: AppFont.fontFamily);

  static const TextStyle textFilledProfileHeading = TextStyle(
      color: AppColor.primaryColor,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: AppFont.fontFamily);
}

class ContentClass {
  final String header;
  final String contenttype;

  ContentClass({required this.header, required this.contenttype});
}

class ResetPasswordIdClass {
  final String userId;
  ResetPasswordIdClass({required this.userId});
}

class ForgotOtpResendEmailClass {
  final String userId;
  final String email;
  ForgotOtpResendEmailClass({required this.email, required this.userId});
}

class NoInternetBanner extends StatelessWidget {
  const NoInternetBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var connectionProvider = Provider.of<ConnectionProvider>(context);
    if (connectionProvider.status.name == "WiFi" ||
        connectionProvider.status.name == "Mobile") {
      return const SizedBox(); // No internet issue, return empty container
    }

    return Column(
      children: [
        // SizedBox(
        //   height: MediaQuery.of(context).size.height * 1 / 100,
        // ),
        Container(
          height: MediaQuery.of(context).size.height * 5 / 100,
          width: double.infinity,
          alignment: Alignment.centerLeft,
          color: Colors.red,
          child: Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Text(
              AppLanguage
                  .noInternetText[language], // Access directly without language
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                fontFamily: AppFont.fontFamily,
                color: AppColor.secondaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum BottomMenus { home, myBookings, wallet, profile }
