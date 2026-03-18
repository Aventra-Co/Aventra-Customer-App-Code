import 'package:flutter/material.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';

class ViewPropertyDetailsScreen extends StatelessWidget {
  const ViewPropertyDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 6 / 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Top Space
              SizedBox(height: size.height * 3 / 100),

              /// Header Row
              Row(
                children: [
                  /// Back Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Image.asset(
                      AppImage.backnav,
                      color: Colors.black,
                      height: size.width * 6 / 100,
                    ),
                  ),

                  SizedBox(width: size.width * 20 / 100),

                  /// Title
                  Text(
                    AppLanguage.propertyDetailsText[language],
                    style: TextStyle(
                      fontFamily: AppFont.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              SizedBox(height: size.height * 5 / 100),

              /// Property Info
              _detailRow(
                  AppLanguage.propertyNameText[language], "Palm Resort", size),

              SizedBox(height: size.height * 2 / 100),

              _detailRow(
                  "${AppLanguage.propertyTypeText[language]}:", "Resort", size),

              SizedBox(height: size.height * 2 / 100),

              _detailRow(AppLanguage.propertyAddressText[language],
                  "1901 Thornridge Cir.\nShiloh, Hawaii 81063", size),

              SizedBox(height: size.height * 2 / 100),

              _detailRow("${AppLanguage.roomsText[language]}:", "4", size),

              SizedBox(height: size.height * 2 / 100),

              _detailRow("${AppLanguage.hallsText[language]}:", "1", size),

              SizedBox(height: size.height * 2 / 100),

              _detailRow(AppLanguage.outdoorSeatingText[language], "1", size),

              SizedBox(height: size.height * 2 / 100),

              _detailRow("${AppLanguage.washroomsText[language]}:", "5", size),

              SizedBox(height: size.height * 2 / 100),

              _detailRow(AppLanguage.poolText[language],
                  AppLanguage.yesText[language], size),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value, Size size) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Title
        SizedBox(
          width: size.width * 35 / 100,
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppFont.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(
          width: size.width * 8 / 100,
        ),

        /// Value
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: AppFont.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
