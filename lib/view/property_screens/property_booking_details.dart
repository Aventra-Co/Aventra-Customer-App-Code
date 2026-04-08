import 'dart:convert';
import 'dart:developer';
import 'package:boatapp/controller/app_button.dart';
import 'package:boatapp/controller/app_color.dart';
import 'package:boatapp/controller/app_constant.dart';
import 'package:boatapp/controller/app_font.dart';
import 'package:boatapp/controller/app_header.dart';
import 'package:boatapp/controller/app_image.dart';
import 'package:boatapp/controller/app_language.dart';
import 'package:boatapp/controller/app_snack_bar_toast_message.dart';
import 'package:boatapp/view/property_screens/property_succress_payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import '../../controller/app_config_provider.dart';
import '../../controller/app_footer.dart';
import '../../controller/app_loader.dart';
import '../../service/date_selection_service.dart';
import '../authentication/login_screen.dart';
import 'view_property_details_screen.dart';

class PropertyBookingDetails extends StatefulWidget {
  final dynamic adDetails;
  final int adultCount;
  final int childCount;
  final DateTime checkinDate;
  final DateTime checkoutDate;
  final int totalNights;
  final double grandTotal;
  final int propertyAdId;
  final int pricingType;
  const PropertyBookingDetails({
    super.key,
    required this.adDetails,
    required this.adultCount,
    required this.childCount,
    required this.checkinDate,
    required this.checkoutDate,
    required this.totalNights,
    required this.grandTotal,
    required this.propertyAdId,
    required this.pricingType,
  });

  @override
  State<PropertyBookingDetails> createState() => _PropertyBookingDetailsState();
}

class _PropertyBookingDetailsState extends State<PropertyBookingDetails> {
  dynamic adDetails = {};
  TextEditingController couponController = TextEditingController();
  dynamic userDetails;
  int userId = 0;
  bool isApiCalling = false;
  bool isCouponDiscount = false;
  bool isDiscountApplied = false;
  int couponDiscount = 0;
  String couponCode = '';
  int isPayment = 0;
  String email = '';
  int? selectedMethod;
  String fullName = '';

  //map
  double longitudex = 77.4126;
  double latitudex = 23.2599;
  GoogleMapController? mapController;
  LatLng initialPosition = const LatLng(23.2599, 77.4126);

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }

  double _discountPercent() {
    return _toDouble(adDetails['discount_percentage']);
  }

  double _applyDiscounts(double baseTotal) {
    double total = baseTotal;
    final propertyDiscount = _discountPercent();
    if (propertyDiscount > 0) {
      total -= total * (propertyDiscount / 100);
    }
    if (isDiscountApplied && couponDiscount > 0) {
      total -= total * (couponDiscount / 100);
    }
    if (total < 0) return 0;
    return total;
  }

  @override
  void initState() {
    super.initState();
    adDetails = widget.adDetails;
    latitudex = double.parse(adDetails['latitude']);
    longitudex = double.parse(adDetails['longitude']);
    initialPosition = LatLng(latitudex, longitudex);
    getUserDetails();
    paymentStatusApiCall();
  }

  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userDetails = prefs.getString("userDetails");
    if (userDetails != null) {
      dynamic data = json.decode(userDetails);
      userId = data['user_id'];
      email = data['email'] ?? "";
      fullName = data['name'] ?? "";
    }
  }

  void couponApplied() {
    if (!isCouponDiscount) {
      return;
    }
    setState(() {
      isDiscountApplied = true;
      couponCode = couponController.text.toUpperCase();
    });
  }

  Future<void> checkCouponApi(userId, couponCode, propertyAdId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}check_property_coupon_discount?user_id=$userId&coupon_code=$couponCode&property_ad_id=$propertyAdId");
    print("url $url");
    String token = AppConstant.token;
    if (token.isEmpty) {
      print("Token is missing!");
    }

    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
    };

    setState(() {
      isApiCalling = true;
    });

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);

        if (res['success'] == true) {
          couponDiscount = res['discount'];
          isCouponDiscount = true;
          couponApplied();
          couponController.clear();
        } else {
          couponCode = "";
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          if (res['active_status'] == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }
        }
      } else {
        couponCode = "";
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      couponCode = "";
      print("Exception: $e");
    } finally {
      setState(() {
        isApiCalling = false;
      });
    }
  }

  propertyBookingApiCall() async {
    setState(() {
      isApiCalling = true;
    });

    Uri url = Uri.parse("${AppConfigProvider.apiUrl}property_booking");

    print("Url===> $url");

    try {
      http.MultipartRequest formData = http.MultipartRequest('POST', url);

      // final totalDates = widget.totalNights;
      final baseTotal = widget.grandTotal;
      final grandTotal = _applyDiscounts(baseTotal);

      formData.fields['user_id'] = userId.toString();
      formData.fields['property_ad_id'] = widget.propertyAdId.toString();
      formData.fields['pricing_type'] = widget.pricingType.toString();
      formData.fields['total_amount'] = grandTotal.toStringAsFixed(2);
      formData.fields['max_child'] = widget.childCount.toString();
      formData.fields['max_adult'] = widget.adultCount.toString();
      formData.fields['grand_total'] = grandTotal.toStringAsFixed(2);
      formData.fields['checkin_date'] = _checkInDateForApi();
      formData.fields['checkout_date'] = _checkOutDateForApi();
      formData.fields['selected_dates'] = _selectedDatesForApi();
      formData.fields['coupon_code'] = couponCode;
      formData.fields['coupon_discount'] = couponDiscount.toString();
      formData.fields['discount_percentage'] =
          widget.adDetails['discount_percentage'].toString();
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

  //!=============================Payment API===================================//
  Future<void> paymentStatusApiCall() async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}payment_hide_show");
    print("url $url");
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
          setState(() {
            isPayment = res['payment_data']['payment_status'];
          });
        } else {
          // ignore: use_build_context_synchronously
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Login()));
          }
        }
      } else {}
    } catch (e) {
      setState(() {
        isApiCalling = false;
      });
    }
  }

  //!======Create Payment==================
  Future<void> createPaymentApiCall() async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}create_payment");
    print("Url $url");

    if (selectedMethod == null) {
      return;
    }

    setState(() {
      isApiCalling = true;
    });

    String token = AppConstant.token;

    try {
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // 🔥 Important
      };
      var body = jsonEncode({
        'customerName': fullName,
        'customerEmail': email,
        'amount': _applyDiscounts(widget.grandTotal).toString(),
        'paymethod': selectedMethod.toString(),
      });

      print("Raw JSON Body: $body");
      http.Response response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      var res = jsonDecode(response.body);
      final baseTotal = widget.grandTotal;
      final grandTotal = _applyDiscounts(baseTotal);

      if (response.statusCode == 200) {
        log("Entringgg 2020202 ${res['success']}");
        // if (res['success'] == true) {
        log("Entringgg");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertySuccessPaymentScreen(
              webUrl: res['bookeeyResponse']['PayUrl'],
              userId: userId.toString(),
              checkInDates: _checkInDateForApi(),
              checkOutDate: _checkOutDateForApi(),
              couponCode: couponCode.toString(),
              couponDiscount: couponDiscount.toString(),
              discountPercentage:
                  widget.adDetails['discount_percentage'].toString(),
              grandTotalAmount: grandTotal.toStringAsFixed(2),
              maxAdult: widget.adultCount.toString(),
              maxChild: widget.childCount.toString(),
              pricingType: widget.pricingType.toString(),
              propertyAdId: widget.propertyAdId.toString(),
              selectedDates: _selectedDatesForApi(),
              totalAmount: grandTotal.toStringAsFixed(2),
            ),
          ),
        );
        // }
      } else {
        // Handle non-200 response
        SnackBarToastMessage.showSnackBar(
            context, "Something went wrong. Please try again.");
      }
    } catch (e) {
      print("Error: $e");
      SnackBarToastMessage.showSnackBar(
          context, "Failed to process the payment.");
    } finally {
      setState(() {
        isApiCalling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
        inAsyncCall: isApiCalling,
        opacity: 0.5,
        child: _buildUIScreen(context));
  }

  Widget _buildUIScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double screenWidth = MediaQuery.of(context).size.width;
    final totalDates = widget.totalNights;
    final double sw = MediaQuery.of(context).size.width;
    final double sh = MediaQuery.of(context).size.height;
    final selectedDateText = _checkInDateText();
    final baseTotal = widget.grandTotal;
    final grandTotal = _applyDiscounts(baseTotal);
    return Directionality(
      textDirection:
          language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                AppHeader(
                  text: AppLanguage.bookingDetailsText[language],
                  onPress: () {
                    Navigator.pop(context);
                  },
                ),

                // Status badge and View Details
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.06,
                      vertical: size.height * 0.01),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                  ),
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ViewPropertyDetailsScreen(
                                    adDetails: adDetails,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              AppLanguage.viewDetailsText[language],
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppFont.fontFamily,
                                  color: Color(0xFF17A2B8),
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColor.themeColor),
                            ),
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 2 / 100,
                          ),
                          Text(
                            adDetails['property_name_english'] ?? "",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          "${AppConfigProvider.imageURL}${adDetails['cover_image']}",
                          width: size.width * 0.25,
                          height: size.height * 0.1,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.02),

                // Location Address
                SizedBox(
                  width: MediaQuery.of(context).size.width * 90 / 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLanguage.locationAddressText[language],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFont.fontFamily,
                          // color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: size.height * 0.01),
                      Text(
                        adDetails['address'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFont.fontFamily,
                        ),
                      ),
                      SizedBox(height: size.height * 0.015),
                    ],
                  ),
                ),

                //!Map
                Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 18 / 100,
                      width: MediaQuery.of(context).size.width * 90 / 100,
                      child: GoogleMap(
                        mapToolbarEnabled: false,
                        zoomGesturesEnabled: false,
                        rotateGesturesEnabled: true,
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        compassEnabled: true,
                        initialCameraPosition: CameraPosition(
                          target: initialPosition,
                          zoom: 10.0,
                        ),
                        onMapCreated: (controller) {
                          //method called when map is created
                          setState(() {
                            mapController = controller;
                          });
                        },
                        markers: {
                          Marker(
                            markerId: const MarkerId(''),
                            position: LatLng(latitudex, longitudex),
                            draggable: true,
                            onDragEnd: (value) {
                              // value is the new position
                            },
                          ),
                        },
                      ),
                    ),
                  ),
                ]),

                SizedBox(height: size.height * 0.03),

                // Booking Details
                SizedBox(
                  width: MediaQuery.of(context).size.width * 90 / 100,
                  child: Text(
                    AppLanguage.bookingDetailsText[language],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: AppFont.fontFamily,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.02),

                _detailRow(
                    context,
                    AppImage.callenderIcon,
                    selectedDateText,
                    AppLanguage.checkInDateText[language],
                    AppLanguage.changeText[language],
                    1, () {
                  Navigator.pop(context);
                }),
                SizedBox(height: size.height * 0.02),

                _detailRow(
                    context,
                    AppImage.clockIcon,
                    '$totalDates ${AppLanguage.daysText[language]}',
                    AppLanguage.bookingDays[language],
                    AppLanguage.changeText[language],
                    0, () {
                  Navigator.pop(context);
                }),
                SizedBox(height: size.height * 0.02),

                _detailRow(
                    context,
                    AppImage.guestsIcon,
                    '${widget.adultCount} ${AppLanguage.adultText[language]} \u2022 ${widget.childCount} ${AppLanguage.childrenText[language]}',
                    AppLanguage.guestsText[language],
                    AppLanguage.changeText[language],
                    1, () {
                  Navigator.pop(context);
                }),
                SizedBox(height: size.height * 0.03),

                SizedBox(
                  width: MediaQuery.of(context).size.width * 90 / 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── DESCRIPTION ──────────────────────────────────────
                      if (language == 0) ...[
                        if (adDetails['description_english'] != null &&
                            adDetails['description_english'].isNotEmpty &&
                            adDetails['description_english'] != "NA") ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLanguage.descriptionText[language],
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w500,
                                  color: AppColor.primaryColor,
                                  fontFamily: AppFont.fontFamily,
                                ),
                              ),
                              SizedBox(height: sh * 0.01),
                              Text(
                                adDetails['description_english'] ?? "NA",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: AppColor.primaryColor,
                                  fontFamily: AppFont.fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ] else if (adDetails['description_arabic'] != null &&
                            adDetails['description_arabic'].isNotEmpty &&
                            adDetails['description_arabic'] != "NA") ...[
                          SizedBox(height: sh * 0.02),
                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: sw * 0.04),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLanguage.descriptionText[language],
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w500,
                                    color: AppColor.primaryColor,
                                    fontFamily: AppFont.fontFamily,
                                  ),
                                ),
                                SizedBox(height: sh * 0.01),
                                Text(
                                  adDetails['description_arabic'] ?? "NA",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: AppColor.primaryColor,
                                    fontFamily: AppFont.fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: sh * 0.02),
                      ],
                      //! Cancellation policy
                      Row(
                        children: [
                          Image.asset(AppImage.cancellationPolicyicon,
                              width: size.width * 0.04,
                              height: size.height * 0.04),
                          TextButton(
                            onPressed: _showCancellationPolicyDialog,
                            child: Text(
                              AppLanguage.cancellationPolicyText[language],
                              style: const TextStyle(
                                fontFamily: AppFont.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColor.themeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 1.5 / 100),
                    ],
                  ),
                ),

                //! total billing
                Container(
                  color: AppColor.themeColor.withOpacity(0.1),
                  width: MediaQuery.of(context).size.width * 100 / 100,
                  padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 2 / 100,
                      horizontal: MediaQuery.of(context).size.width * 5 / 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLanguage.billingDetailsText[language],
                        style: const TextStyle(
                            color: AppColor.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 2 / 100),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 1 / 100),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 1 / 100),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 90 / 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$totalDates ${AppLanguage.daysText[language]}",
                              style: const TextStyle(
                                  color: AppColor.primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFont.fontFamily),
                            ),
                            Text(
                              '${grandTotal.toStringAsFixed(2)} KWD',
                              style: const TextStyle(
                                  color: AppColor.primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppFont.fontFamily),
                            ),
                          ],
                        ),
                      ),
                      if (adDetails['discount_percentage'] > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "+${AppLanguage.withText[language]} ${adDetails['discount_percentage']}% ${AppLanguage.discountText[language]}",
                              style: const TextStyle(
                                  color: AppColor.primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppFont.fontFamily),
                            ),
                          ],
                        ),
                      if (isCouponDiscount)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "+${AppLanguage.withText[language]} $couponDiscount% ${AppLanguage.couponDiscountText[language]}",
                              style: const TextStyle(
                                  color: AppColor.primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppFont.fontFamily),
                            ),
                          ],
                        ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 1 / 100),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 1 / 100),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 1 / 100),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 1 / 100),
                      Divider(
                        color: AppColor.textColor,
                        height: MediaQuery.of(context).size.height * 0.01 / 100,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 1 / 100),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLanguage.grandTotalText[language],
                            style: const TextStyle(
                                color: AppColor.primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFont.fontFamily),
                          ),
                          Text(
                            '${grandTotal.toStringAsFixed(2)} KWD',
                            style: const TextStyle(
                                color: AppColor.primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFont.fontFamily),
                          ),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 1 / 100),
                      Divider(
                        color: AppColor.textColor,
                        height: MediaQuery.of(context).size.height * 0.01 / 100,
                      )
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 3 / 100),

                //!coupon text
                SizedBox(
                  width: screenWidth * 90 / 100,
                  child: Text(
                    AppLanguage.applyCouonText[language],
                    style: const TextStyle(
                        fontFamily: AppFont.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColor.primaryColor),
                  ),
                ),

                //!coupon text field
                SizedBox(
                  width: screenWidth * 90 / 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 60 / 100,
                        height: MediaQuery.of(context).size.height * 5.5 / 100,
                        child: TextFormField(
                          readOnly: false,
                          style: AppConstant.textFilledProfileHeading,
                          textAlignVertical: TextAlignVertical.center,
                          keyboardType: TextInputType.text,
                          controller: couponController,
                          maxLength: 8,
                          onTapOutside: (event) =>
                              FocusScope.of(context).unfocus(),
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: AppColor.textinputBorderColor),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: AppColor.textinputBorderColor),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: AppColor.textinputBorderColor),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            counterText: '',
                            hintText: AppLanguage.enterCodeMsg[language],
                            hintStyle: const TextStyle(
                                color: AppColor.hintTextinputColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                fontFamily: AppFont.fontFamily),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (couponController.text.isEmpty ||
                              couponController.text.length < 8) {
                            SnackBarToastMessage.showSnackBar(
                                context, AppLanguage.codeMsg[language]);
                            return;
                          } else {
                            if (isDiscountApplied) {
                              SnackBarToastMessage.showSnackBar(
                                  context, "Coupon is already applied!");
                            } else {
                              checkCouponApi(
                                  userId,
                                  couponController.text.toUpperCase(),
                                  widget.propertyAdId.toString());
                            }
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: MediaQuery.of(context).size.height * 4 / 100,
                          width: MediaQuery.of(context).size.width * 20 / 100,
                          decoration: BoxDecoration(
                            color: AppColor.themeColor,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            AppLanguage.applyText[language],
                            style: const TextStyle(
                                fontSize: 16,
                                color: AppColor.secondaryColor,
                                fontFamily: AppFont.fontFamily,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 3 / 100),

                //!grand total
                Container(
                  width: MediaQuery.of(context).size.width * 90 / 100,
                  padding:
                      const EdgeInsets.symmetric(vertical: 9, horizontal: 15),
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColor.grayColor),
                      borderRadius: BorderRadius.circular(50)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${grandTotal.toStringAsFixed(2)} KWD',
                            style: const TextStyle(
                              color: AppColor.primaryColor,
                              fontSize: 23,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily,
                            ),
                          ),
                          Text(
                            AppLanguage.payableAmountText[language],
                            style: const TextStyle(
                              color: AppColor.themeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFont.fontFamily,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 35 / 100,
                        child: AppButton(
                          text: AppLanguage.paynowText[language],
                          onPress: () {
                            if (isPayment == 0) {
                              SnackBarToastMessage.showSnackBar(
                                  context, "Booking Done");
                              AppConstant.selectFooterIndex = 0;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyFooterPage(),
                                ),
                              );
                              return;
                            }
                            FocusManager.instance.primaryFocus?.unfocus();
                            paymentMethodBottomSheet(context);
                            // createPaymentApiCall();
                            // tripBookingApiCall();
                            // propertyBookingApiCall();
                          },
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 2 / 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCancellationPolicyDialog() {
    final size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.all(size.width * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLanguage.cancellationPolicyText[language],
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFont.fontFamily,
                    color: AppColor.themeColor),
              ),
              SizedBox(height: size.height * 0.015),
              Text(
                AppLanguage.cancelDetailsText[language],
                style: const TextStyle(
                    fontSize: 13.8,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFont.fontFamily,
                    color: Colors.black87,
                    height: 1.5),
              ),
              SizedBox(height: size.height * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  String _checkInDateText() {
    return DateFormat('MMM dd, yyyy').format(widget.checkinDate);
  }

  String _checkInDateForApi() {
    return DateFormat('yyyy-MM-dd').format(widget.checkinDate);
  }

  String _checkOutDateForApi() {
    return DateFormat('yyyy-MM-dd').format(widget.checkoutDate);
  }

  String _selectedDatesForApi() {
    final days = DateSelectionService().buildSelectedDates(
      start: widget.checkinDate,
      end: widget.checkoutDate,
    );
    return days.map((d) => DateFormat('yyyy-MM-dd').format(d)).join(',');
  }

  Widget _detailRow(BuildContext context, String image, String value,
      String label, String action, int isAction, VoidCallback onTap) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 90 / 100,
      child: Row(
        children: [
          Image.asset(
            image,
            width: MediaQuery.of(context).size.width * 9 / 100,
            height: MediaQuery.of(context).size.width * 9 / 100,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFont.fontFamily,
                    // color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFont.fontFamily,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (isAction == 1)
            TextButton(
              onPressed: onTap,
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFont.fontFamily,
                  color: AppColor.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _addonItem(String title, String price, int quantity) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade300,
          ),
          child: Icon(Icons.image, color: Colors.grey.shade500),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: AppFont.fontFamily,
              color: Colors.black87,
            ),
          ),
        ),
        if (quantity > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Qty: $quantity',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: AppFont.fontFamily,
                color: Colors.black87,
              ),
            ),
          ),
        if (price.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            price,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: AppFont.fontFamily,
              color: Colors.black,
            ),
          ),
        ],
      ],
    );
  }

  Widget _billingRow(String label, String amount, String subtitle,
      {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                fontFamily: AppFont.fontFamily,
                color: Colors.black,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                fontFamily: AppFont.fontFamily,
                color: Colors.black,
              ),
            ),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              fontFamily: AppFont.fontFamily,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _billingSubRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            fontFamily: AppFont.fontFamily,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: AppFont.fontFamily,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  void paymentMethodBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Payment Method',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Payment Methods
                  _buildPaymentOption(
                    setState: setModalState, // Pass the setState function
                    method: 1,
                    title: 'Credit Card',
                    subtitle: 'Pay with your credit card',
                    icon: Icons.credit_card,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),

                  _buildPaymentOption(
                    setState: setModalState, // Pass the setState function
                    method: 2,
                    title: 'KNET',
                    subtitle: 'Kuwait National Electronic Transfer',
                    icon: Icons.account_balance,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),

                  _buildPaymentOption(
                    setState: setModalState, // Pass the setState function
                    method: 3,
                    title: 'American Express',
                    subtitle: 'Pay with Amex card',
                    icon: Icons.payment,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),

                  _buildPaymentOption(
                    setState: setModalState, // Pass the setState function
                    method: 4,
                    title: 'Bookeey',
                    subtitle: 'Pay with Bookeey wallet',
                    icon: Icons.wallet,
                    color: Colors.purple,
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedMethod != null
                              ? () {
                                  Navigator.pop(context);
                                  createPaymentApiCall();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedMethod != null
                                ? _getPaymentMethodColor(selectedMethod!)
                                : Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildPaymentOption({
    required Function(void Function()) setState,
    required int method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedMethod == method;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? color : Colors.grey.shade400,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _getPaymentMethodColor(int method) {
  switch (method) {
    case 1:
      return Colors.blue;
    case 2:
      return Colors.green;
    case 3:
      return Colors.orange;
    case 4:
      return Colors.purple;
    default:
      return Colors.grey;
  }
}
