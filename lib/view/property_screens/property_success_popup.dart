import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_footer.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../authentication/login_screen.dart';

// ignore: must_be_immutable
class PropertyPaymentSuccessPopUp extends StatefulWidget {
  final String userId;
  final String propertyAdId;
  final String pricingType;
  final String totalAmount;
  final String grandTotalAmount;
  final String maxAdult;
  final String maxChild;
  final String checkInDates;
  final String checkOutDate;
  final String selectedDates;
  final String couponCode;
  final String couponDiscount;
  final String discountPercentage;

  const PropertyPaymentSuccessPopUp({
    super.key,
    required this.userId,
    required this.propertyAdId,
    required this.pricingType,
    required this.totalAmount,
    required this.grandTotalAmount,
    required this.maxAdult,
    required this.maxChild,
    required this.checkInDates,
    required this.checkOutDate,
    required this.selectedDates,
    required this.couponCode,
    required this.couponDiscount,
    required this.discountPercentage,
  });

  @override
  _PropertyPaymentSuccessPopUpState createState() =>
      _PropertyPaymentSuccessPopUpState();
}

class _PropertyPaymentSuccessPopUpState
    extends State<PropertyPaymentSuccessPopUp> {
  bool isApiCalling = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(seconds: 2),
      () => propertyBookingApiCall(),
    );
  }

  //------------------------Trip Booking API CALL--------------------------------//
  propertyBookingApiCall() async {
    setState(() {
      isApiCalling = true;
    });

    Uri url = Uri.parse("${AppConfigProvider.apiUrl}property_booking");

    print("Url===> $url");

    try {
      http.MultipartRequest formData = http.MultipartRequest('POST', url);

      // final totalDates = widget.totalNights;

      formData.fields['user_id'] = widget.userId.toString();
      formData.fields['property_ad_id'] = widget.propertyAdId.toString();
      formData.fields['pricing_type'] = widget.pricingType.toString();
      formData.fields['total_amount'] = widget.grandTotalAmount;
      formData.fields['max_child'] = widget.maxChild.toString();
      formData.fields['max_adult'] = widget.maxAdult.toString();
      formData.fields['grand_total'] = widget.grandTotalAmount;
      formData.fields['checkin_date'] = widget.checkInDates;
      formData.fields['checkout_date'] = widget.checkOutDate;
      formData.fields['selected_dates'] = widget.selectedDates;
      formData.fields['coupon_code'] = widget.couponCode;
      formData.fields['coupon_discount'] = widget.couponDiscount;
      formData.fields['discount_percentage'] =
          widget.discountPercentage.toString();
      log("response--==> ${formData.fields}");
      // print("response--==> ${formData.files}");
      http.StreamedResponse response = await formData.send();
      print("response--==> $response");
      var responseString = await response.stream.toBytes();
      var res = jsonDecode(utf8.decode(responseString));

      if (response.statusCode == 200) {
        print("res : $res");
        if (res['success'] == true) {
          AppConstant.selectFooterIndex = 1;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyFooterPage(
                selectedTab: 1,
              ),
            ),
          );
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          setState(() {
            isApiCalling = false;
          });
        } else {
          setState(() {
            isApiCalling = false;
          });
          // ignore: use_build_context_synchronously
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
      }
    } catch (e) {
      setState(() {
        isApiCalling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.secondaryColor,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 100 / 100,
            height: MediaQuery.of(context).size.height * 1,
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 25 / 100,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 40 / 100,
                  height: MediaQuery.of(context).size.width * 40 / 100,
                  child: Image.asset(
                    AppImage.rightConfirmationIcon,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 5 / 100,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 90 / 100,
                  child: Text(
                    AppLanguage.successText[language],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
