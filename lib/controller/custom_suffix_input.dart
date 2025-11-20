import 'package:flutter/material.dart';
import 'app_color.dart';
import 'app_constant.dart';
import 'app_font.dart';

// ignore: must_be_immutable
class CustomSuffixTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String image;
  final int maxLength;
  final int fillColorStatus;
  final bool readOnly;
  // ignore: prefer_typing_uninitialized_variables
  var keyboardtype;

  CustomSuffixTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.image,
    required this.keyboardtype,
    required this.maxLength,
    required this.fillColorStatus,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    return 
    Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 90 / 100,
        height: MediaQuery.of(context).size.height * 6 / 100,
        child: TextFormField(
          readOnly: readOnly,
          style: AppConstant.textFilledHeading,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: keyboardtype,
          controller: controller,
          maxLength: maxLength,
          decoration: InputDecoration(
            prefixIcon: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  child: Image.asset(
                    image,
                    height: MediaQuery.of(context).size.width * 5 / 100,
                    width: MediaQuery.of(context).size.width * 5 / 100,
                  ),
                ),
              ],
            ),
            suffixIcon: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  child: Image.asset(
                    image,
                    height: MediaQuery.of(context).size.width * 5 / 100,
                    width: MediaQuery.of(context).size.width * 5 / 100,
                  ),
                ),
              ],
            ),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColor.textinputBorderColor),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColor.textinputBorderColor),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColor.textinputBorderColor),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
            filled: false,
            counterText: '',
            hintText: hintText,
            hintStyle: const TextStyle(
                color: AppColor.textinputBorderColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: AppFont.fontFamily),
          ),
        ),
      ),
    );
 
 
 
  }
}
