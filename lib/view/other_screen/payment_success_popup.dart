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
class PaymentSuccessPopUp extends StatefulWidget {
  final String userId;
  final String tripId;
  final String bookingDate;
  final String hours;
  final String bookingTime;
  final String grandTotal;
  final String transactionId;
  final String addonArr;
  final String addonTotalAmount;
  final String captainFees;
  final String couponCode;
  final String discount;
  final String couponDiscount;
  final String hoursPrice;
  final String sendTicketsCount;
  final String sendSlotIds;

  const PaymentSuccessPopUp({
    super.key,
    required this.userId,
    required this.tripId,
    required this.bookingDate,
    required this.hours,
    required this.bookingTime,
    required this.grandTotal,
    required this.transactionId,
    required this.addonArr,
    required this.addonTotalAmount,
    required this.captainFees,
    required this.couponCode,
    required this.discount,
    required this.couponDiscount,
    required this.hoursPrice,
    required this.sendTicketsCount, required this.sendSlotIds,
  });

  @override
  _PaymentSuccessPopUpState createState() => _PaymentSuccessPopUpState();
}

class _PaymentSuccessPopUpState extends State<PaymentSuccessPopUp> {
  bool isApiCalling = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(seconds: 2),
      () => tripBookingApiCall(),
    );
  }

  //------------------------Trip Booking API CALL--------------------------------//
  tripBookingApiCall() async {
    setState(() {
      isApiCalling = true;
    });

    Uri url = Uri.parse("${AppConfigProvider.apiUrl}trip_booking");

    print("Url===> $url");

    try {
      http.MultipartRequest formData = http.MultipartRequest('POST', url);

      formData.fields['user_id'] = widget.userId;
      formData.fields['trip_id'] = widget.tripId;
      formData.fields['booking_date'] = widget.bookingDate;
      formData.fields['hours'] = widget.hours;
      formData.fields['booking_time'] = widget.bookingTime;
      formData.fields['grand_total'] = widget.grandTotal;
      formData.fields['transaction_id'] = widget.transactionId;
      formData.fields['addon_arr'] = widget.addonArr;
      formData.fields['addon_total_amount'] = widget.addonTotalAmount;
      formData.fields['captain_fees'] = "0";
      formData.fields['coupon_code'] = widget.couponCode;
      formData.fields['discount'] = widget.discount;
      formData.fields['coupon_discount'] = widget.couponDiscount;
      formData.fields['hours_price'] = widget.hoursPrice;
      formData.fields['slot_ids'] = widget.sendSlotIds;
      formData.fields['ticket_count'] = widget.sendTicketsCount;

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
              builder: (context) => const MyFooterPage(),
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
     print("check${widget.sendTicketsCount}");
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
