import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_color.dart';

import 'app_font.dart';

class SettingRow extends StatelessWidget {
  final String title;
  final String leadingIcon;
  final String rightLeadingIcon;
  final Function onPress;

  const SettingRow({
    Key? key,
    required this.title,
    required this.leadingIcon,
    required this.rightLeadingIcon,
    required this.onPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onPress(),
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 90 / 100,
            height: MediaQuery.of(context).size.height * 6 / 100,
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 7 / 100,
                  height: MediaQuery.of(context).size.width * 7 / 100,
                  alignment: Alignment.center,
                  child: Image.asset(
                    leadingIcon,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 60 / 100,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColor.primaryColor,
                      fontFamily: AppFont.fontFamily,
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 7 / 100,
                  height: MediaQuery.of(context).size.width * 7 / 100,
                  alignment: Alignment.center,
                  child: Image.asset(
                    rightLeadingIcon,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
          Container(
              width: MediaQuery.of(context).size.width * 90 / 100,
              height: MediaQuery.of(context).size.height * 0.1 / 100,
              color: AppColor.textColor),
        ],
      ),
    );
  }
}
