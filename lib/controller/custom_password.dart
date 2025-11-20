import 'package:flutter/material.dart';
import 'app_color.dart';
import 'app_constant.dart';
import 'app_font.dart';
import 'app_image.dart';

// ignore: must_be_immutable
class CustomPasswordTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLength;
  final int fillColorStatus;
  final bool readOnly;
  // ignore: prefer_typing_uninitialized_variables
  var keyboardtype;

  CustomPasswordTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.keyboardtype,
    required this.maxLength,
    required this.fillColorStatus,
    required this.readOnly,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CustomPasswordTextFormFieldState createState() =>
      _CustomPasswordTextFormFieldState();
}

class _CustomPasswordTextFormFieldState
    extends State<CustomPasswordTextFormField> {
  bool passwordVisible = true;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 90 / 100,
        height: MediaQuery.of(context).size.height * 6 / 100,
        child: TextFormField(
          style: AppConstant.textFilledStyle,
          keyboardType: widget.keyboardtype,
          maxLength: widget.maxLength,
          controller: widget.controller,
          textAlignVertical: TextAlignVertical.center,
          obscureText: passwordVisible,
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
            prefixIcon: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  child: Image.asset(
                    AppImage.passwordIcon,
                    height: MediaQuery.of(context).size.width * 5 / 100,
                    width: MediaQuery.of(context).size.width * 5 / 100,
                  ),
                ),
              ],
            ),
            suffixIcon: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      passwordVisible = !passwordVisible;
                    });
                  },
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 5 / 100,
                    height: MediaQuery.of(context).size.width * 5 / 100,
                    child: Image.asset(
                      passwordVisible
                          ? AppImage.showEyeIcon
                          : AppImage.hideEyeIcon,
                    ),
                  ),
                ),
              ],
            ),
            contentPadding: EdgeInsets.zero,
            fillColor: AppColor.secondaryColor,
            filled: true,
            counterText: '',
            hintText: widget.hintText,
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
