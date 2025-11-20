import 'package:flutter/material.dart';

import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
class PaymentFailedPopUp extends StatefulWidget {
  PaymentFailedPopUp({
    super.key,
  });

  @override
  _PaymentFailedPopUpState createState() => _PaymentFailedPopUpState();
}

class _PaymentFailedPopUpState extends State<PaymentFailedPopUp> {
  @override
  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(seconds: 3),
      () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.secondaryColor,
      body: SafeArea(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 100 / 100,
            height: MediaQuery.of(context).size.height * 1,
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 25 / 100,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 40 / 100,
                  height: MediaQuery.of(context).size.width * 40 / 100,
                  child: Image.asset(
                    AppImage.failedIcon,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 5 / 100,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 90 / 100,
                  child: Text(
                    AppLanguage.failedText[language],
                    style: const TextStyle(
                        fontSize: 24,
                        color: AppColor.themeColor,
                        fontFamily: AppFont.fontFamily,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 2 / 100,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 90 / 100,
                  child: Text(
                    AppLanguage.pleaseTryText[language],
                    style: const TextStyle(
                        fontSize: 17.5,
                        color: AppColor.textColor,
                        fontFamily: AppFont.fontFamily,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
