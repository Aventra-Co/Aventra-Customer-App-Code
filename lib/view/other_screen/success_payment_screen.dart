import 'dart:convert';
import 'dart:developer';
import 'package:boatapp/view/other_screen/failed_payment_popup.dart';
import 'package:boatapp/view/other_screen/payment_success_popup.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_image.dart';
import 'package:http/http.dart' as http;

// ignore: must_be_immutable
class SuccessPaymentScreen extends StatefulWidget {
  final String webUrl;
  final String userId;
  final String tripId;
  final String bookingDate;
  final String hours;
  final String bookingTime;
  final String grandTotal;
  final String addonArr;
  final String addonTotalAmount;
  final String captainFees;
  final String couponCode;
  final String discount;
  final String couponDiscount;
  final String hoursPrice;
  final String sendTicketsCount;
  final String sendSlotIds;
  const SuccessPaymentScreen({
    super.key,
    required this.webUrl,
    required this.userId,
    required this.tripId,
    required this.bookingDate,
    required this.hours,
    required this.bookingTime,
    required this.grandTotal,
    required this.addonArr,
    required this.addonTotalAmount,
    required this.captainFees,
    required this.couponCode,
    required this.discount,
    required this.couponDiscount,
    required this.hoursPrice,
    required this.sendTicketsCount,
    required this.sendSlotIds,
  });

  @override
  State<SuccessPaymentScreen> createState() => _SuccessPaymentScreenState();
}

class _SuccessPaymentScreenState extends State<SuccessPaymentScreen> {
  bool isApiCalling = false;
  bool isLoading = true; // Added loading state
  int loadingProgress = 0; // Track loading progress
  var status;
  var paymentId;
  var transactionStatus;
  var error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.secondaryColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Container(
            height: MediaQuery.of(context).size.height * 100 / 100,
            width: MediaQuery.of(context).size.width * 100 / 100,
            color: AppColor.secondaryColor,
            child: Directionality(
              textDirection:
                  language == 1 ? TextDirection.rtl : TextDirection.ltr,
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width:
                                MediaQuery.of(context).size.width * 100 / 100,
                            height:
                                MediaQuery.of(context).size.height * 100 / 100,
                            child: WebView(
                                initialUrl: widget.webUrl,
                                javascriptMode: JavascriptMode.unrestricted,
                                onProgress: (int progress) {
                                  log("WebView is loading (progress : $progress%)");
                                  setState(() {
                                    loadingProgress = progress;
                                    if (progress == 100) {
                                      isLoading = false;
                                    }
                                  });
                                },
                                onPageStarted: (String url) {
                                  log('Page started loading: $url');
                                  setState(() {
                                    isLoading = true;
                                    loadingProgress = 0;
                                  });
                                },
                                onPageFinished: (String url) {
                                  log("Final Loaded URL: $url");
                                  setState(() {
                                    isLoading = false;
                                  });
                                  _handlePaymentResponse(url);
                                }),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Loading overlay
                  if (isLoading)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: AppColor.secondaryColor,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // App logo behind the loading indicator
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColor.secondaryColor,
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      AppImage
                                          .appIcon, // Replace with your app logo path
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        // Fallback if image doesn't exist
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColor.primaryColor
                                                .withOpacity(0.1),
                                          ),
                                          child: const Icon(
                                            Icons.directions_boat,
                                            size: 40,
                                            color: AppColor.primaryColor,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                // Circular progress indicator
                                SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: CircularProgressIndicator(
                                    value: loadingProgress / 100,
                                    strokeWidth: 3,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      AppColor.primaryColor,
                                    ),
                                    backgroundColor:
                                        AppColor.primaryColor.withOpacity(0.2),
                                  ),
                                ),
                              ],
                            ),
                     
                            const SizedBox(height: 10),
                            Text(
                              '$loadingProgress%',
                              style: const TextStyle(
                                color: AppColor.primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePaymentResponse(String url) {
    log('Payment Response URL: $url');

    final uri = Uri.parse(url);

    log("Line 130 $uri");

    final paymentId = uri.queryParameters['merchantTxnId'];
    final isSuccess = uri.queryParameters['errorCode'];

    log("paymentId $paymentId");
    log("isSuccess ${isSuccess.runtimeType}");

    Future.delayed(const Duration(milliseconds: 100), () async {
      if (isSuccess == "0") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessPopUp(
              userId: widget.userId,
              addonArr: widget.addonArr,
              addonTotalAmount: widget.addonTotalAmount,
              discount: widget.discount,
              captainFees: widget.captainFees,
              grandTotal: widget.grandTotal,
              hours: widget.hours,
              tripId: widget.tripId,
              bookingTime: widget.bookingTime,
              couponCode: widget.couponCode,
              bookingDate: widget.bookingDate,
              transactionId: paymentId.toString(),
              hoursPrice: widget.hoursPrice,
              couponDiscount: widget.couponDiscount,
              sendTicketsCount: widget.sendTicketsCount,
              sendSlotIds: widget.sendSlotIds,
            ),
          ),
        );
      } else if (isSuccess == "1") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentFailedPopUp(),
          ),
        );
      } else {
        Uri url = uri;
        print("url $url");
        setState(() {
          isLoading = true;
        });
        String token = AppConstant.token;

        if (token.isEmpty) {
          print("Token is missing!");
          // return;
        }

        Map<String, String> headers = {'Authorization': 'Bearer $token'};

        try {
          final response = await http.get(url, headers: headers);
          print("response $response");

          if (response.statusCode == 200) {
            dynamic res = jsonDecode(response.body);
            print("res $res");

            if (res['success'] == true) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentSuccessPopUp(
                    userId: widget.userId,
                    addonArr: widget.addonArr,
                    addonTotalAmount: widget.addonTotalAmount,
                    discount: widget.discount,
                    captainFees: widget.captainFees,
                    grandTotal: widget.grandTotal,
                    hours: widget.hours,
                    tripId: widget.tripId,
                    bookingTime: widget.bookingTime,
                    couponCode: widget.couponCode,
                    bookingDate: widget.bookingDate,
                    transactionId: paymentId.toString(),
                    hoursPrice: widget.hoursPrice,
                    couponDiscount: widget.couponDiscount,
                    sendTicketsCount: widget.sendTicketsCount,
                    sendSlotIds: widget.sendSlotIds,
                  ),
                ),
              );
              setState(() {
                isLoading = false;
              });
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentFailedPopUp(),
                ),
              );
              setState(() {
                isLoading = false;
              });
              // ignore: use_build_context_synchronously
            }
          } else {
            setState(() {
              isLoading = false;
            });
          }
        } catch (e) {
          setState(() {
            isLoading = false;
          });
        }
      }
    });
  }
}
