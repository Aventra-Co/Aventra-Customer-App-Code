import 'package:flutter/material.dart';
import 'app_color.dart';
import 'app_constant.dart';
import 'app_font.dart';

// ignore: must_be_immutable
class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String image;
  final int maxLength;
  final int fillColorStatus;
  final bool readOnly;
  // ignore: prefer_typing_uninitialized_variables
  var keyboardtype;

  CustomTextFormField({
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
    return Center(
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
            border: const OutlineInputBorder(
              borderSide:
                  BorderSide(color: AppColor.textinputBorderColor, width: 1.2),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide:
                  BorderSide(color: AppColor.textinputBorderColor, width: 1.2),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide:
                  BorderSide(color: AppColor.textinputBorderColor, width: 1.2),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
            filled: false,
            counterText: '',
            hintText: hintText,
            hintStyle: const TextStyle(
                color: AppColor.hintTextinputColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: AppFont.fontFamily),
          ),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class CustomEditTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLength;
  final int fillColorStatus;
  final bool readOnly;
  // ignore: prefer_typing_uninitialized_variables
  var keyboardtype;

  CustomEditTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.keyboardtype,
    required this.fillColorStatus,
    required this.readOnly,
    required this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 90 / 100,
        height: MediaQuery.of(context).size.height * 5.5 / 100,
        child: TextFormField(
          readOnly: readOnly,
          style: AppConstant.textFilledProfileHeading,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: keyboardtype,
          controller: controller,
          onTapOutside: (event) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColor.textinputBorderColor),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColor.textinputBorderColor),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColor.textinputBorderColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            hintText: hintText,
            hintStyle: const TextStyle(
                color: AppColor.hintTextinputColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: AppFont.fontFamily),
          ),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class CustomFormatterTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLength;
  final int fillColorStatus;
  final bool readOnly;
  final dynamic inputFormatter;
  // ignore: prefer_typing_uninitialized_variables
  var keyboardtype;

  CustomFormatterTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.keyboardtype,
    required this.fillColorStatus,
    required this.readOnly,
    required this.maxLength,
    this.inputFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
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
          inputFormatters: inputFormatter,
          decoration: InputDecoration(
            border: const OutlineInputBorder(
              borderSide:
                  BorderSide(color: AppColor.textinputBorderColor, width: 1.2),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide:
                  BorderSide(color: AppColor.textinputBorderColor, width: 1.2),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide:
                  BorderSide(color: AppColor.textinputBorderColor, width: 1.2),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
            filled: false,
            counterText: '',
            hintText: hintText,
            hintStyle: const TextStyle(
                color: AppColor.hintTextinputColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: AppFont.fontFamily),
          ),
        ),
      ),
    );
  }
}
