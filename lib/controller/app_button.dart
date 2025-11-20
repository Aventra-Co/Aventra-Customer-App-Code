import 'package:flutter/material.dart';
import 'app_color.dart';
import 'app_font.dart';

class AppButton extends StatelessWidget {
  final String text;
  final Function onPress;

  const AppButton({
    super.key,
    required this.text,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onPress();
      },
      child: Container(
        alignment: Alignment.center,
        height: MediaQuery.of(context).size.height * 7 / 100,
        width: MediaQuery.of(context).size.width * 88 / 100,
        decoration: BoxDecoration(
          color: AppColor.themeColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 16,
              color: AppColor.secondaryColor,
              fontFamily: AppFont.fontFamily,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
