import '/controller/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'app_color.dart';
import 'app_font.dart';
import 'app_image.dart';

class AppHeader extends StatelessWidget {
  final String text;
  final Function onPress;
  const AppHeader({
    super.key,
    required this.text,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 7 / 100,
      width: MediaQuery.of(context).size.width * 90 / 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              onPress();
            },
            child: Transform.rotate(
              angle: language == 1 ? 3.1416 : 0,
              child: Container(
                height: MediaQuery.of(context).size.width * 5 / 100,
                width: MediaQuery.of(context).size.width * 5 / 100,
                child: Image.asset(
                  AppImage.navigateBackIcon,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 4 / 100,
            width: MediaQuery.of(context).size.width * 4 / 100,
          ),
          Text(text,
              style: const TextStyle(
                  color: AppColor.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFont.fontFamily)),
          SizedBox(
            height: MediaQuery.of(context).size.width * 5 / 100,
            width: MediaQuery.of(context).size.width * 5 / 100,
          ),
        ],
      ),
    );
  }
}
