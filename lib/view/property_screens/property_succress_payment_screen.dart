import 'dart:convert';
import 'dart:developer';
import '/view/other_screen/failed_payment_popup.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_image.dart';
import 'package:http/http.dart' as http;
import 'property_success_popup.dart';

// ignore: must_be_immutable
class PropertySuccessPaymentScreen extends StatefulWidget {
  final String webUrl;
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
  const PropertySuccessPaymentScreen({
    super.key,
    required this.webUrl,
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
  State<PropertySuccessPaymentScreen> createState() =>
      _PropertySuccessPaymentScreenState();
}

class _PropertySuccessPaymentScreenState
    extends State<PropertySuccessPaymentScreen> {
  bool isApiCalling = false;
  bool isLoading = true; // Added loading state
  int loadingProgress = 0; // Track loading progress
  var status;
  var paymentId;
  var transactionStatus;
  var error;

  @override
  void initState() {
    super.initState();
    log("Check the gateway ${widget.webUrl}");
  }

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
            builder: (context) => PropertyPaymentSuccessPopUp(
              userId: widget.userId,
              checkInDates: widget.checkInDates,
              checkOutDate: widget.checkOutDate,
              couponCode: widget.couponCode,
              couponDiscount: widget.couponDiscount,
              discountPercentage: widget.discountPercentage,
              grandTotalAmount: widget.grandTotalAmount,
              maxAdult: widget.maxAdult,
              maxChild: widget.maxChild,
              pricingType: widget.pricingType,
              propertyAdId: widget.propertyAdId,
              selectedDates: widget.selectedDates,
              totalAmount: widget.totalAmount,
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
                  builder: (context) => PropertyPaymentSuccessPopUp(
                    userId: widget.userId,
                    checkInDates: widget.checkInDates,
                    checkOutDate: widget.checkOutDate,
                    couponCode: widget.couponCode,
                    couponDiscount: widget.couponDiscount,
                    discountPercentage: widget.discountPercentage,
                    grandTotalAmount: widget.grandTotalAmount,
                    maxAdult: widget.maxAdult,
                    maxChild: widget.maxChild,
                    pricingType: widget.pricingType,
                    propertyAdId: widget.propertyAdId,
                    selectedDates: widget.selectedDates,
                    totalAmount: widget.totalAmount,
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
