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
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controller/app_config_provider.dart';
import '../../controller/app_footer.dart';
import '../../controller/app_loader.dart';
import '../authentication/login_screen.dart';

class PropertyBookingDetails extends StatefulWidget {
  final dynamic adDetails;
  final int adultCount;
  final int childCount;
  final Set<DateTime> selectedDays;
  final int priceType;
  final String perDayPrice;
  final int propertyAdId;
  const PropertyBookingDetails(
      {super.key,
      required this.adDetails,
      required this.adultCount,
      required this.childCount,
      required this.selectedDays,
      required this.priceType,
      required this.perDayPrice,
      required this.propertyAdId});

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

  //map
  double longitudex = 77.4126;
  double latitudex = 23.2599;
  GoogleMapController? mapController;
  LatLng initialPosition = const LatLng(23.2599, 77.4126);

  @override
  void initState() {
    super.initState();
    adDetails = widget.adDetails;
    latitudex = double.parse(adDetails['latitude']);
    longitudex = double.parse(adDetails['longitude']);
    initialPosition = LatLng(latitudex, longitudex);
    getUserDetails();
  }

  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userDetails = prefs.getString("userDetails");
    if (userDetails != null) {
      dynamic data = json.decode(userDetails);
      userId = data['user_id'];
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
        "${AppConfigProvider.apiUrl}check_coupon_discount?user_id=$userId&coupon_code=$couponCode&trip_id=$propertyAdId");

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

      final totalDates = widget.selectedDays.length;
      final baseTotal = totalDates * double.parse(widget.perDayPrice);
      final grandTotal = isDiscountApplied
          ? (baseTotal - (baseTotal * (couponDiscount / 100)))
          : baseTotal;

      formData.fields['user_id'] = userId.toString();
      formData.fields['property_ad_id'] = widget.propertyAdId.toString();
      formData.fields['pricing_type'] = widget.priceType.toString();
      formData.fields['total_amount'] = baseTotal.toStringAsFixed(2);
      formData.fields['max_child'] = widget.childCount.toString();
      formData.fields['max_adult'] = widget.adultCount.toString();
      formData.fields['grand_total'] = grandTotal.toStringAsFixed(2);
      formData.fields['checkin_date'] = _firstSelectedDateForApi();
      formData.fields['checkout_date'] = _lastSelectedDateForApi();
      formData.fields['selected_dates'] = _selectedDatesForApi();
      formData.fields['coupon_code'] = couponCode;
      formData.fields['coupon_discount'] = couponDiscount.toString();
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
    return ProgressHUD(
        inAsyncCall: isApiCalling,
        opacity: 0.5,
        child: _buildUIScreen(context));
  }

  Widget _buildUIScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double screenWidth = MediaQuery.of(context).size.width;
    final totalDates = widget.selectedDays.length;
    final selectedDateText = _firstSelectedDateText();
    final baseTotal = totalDates * double.parse(widget.perDayPrice);
    final grandTotal = isDiscountApplied
        ? (baseTotal - (baseTotal * (couponDiscount / 100)))
        : baseTotal;
    return Scaffold(
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
                            Navigator.pop(context);
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
                          height: MediaQuery.of(context).size.height * 2 / 100,
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
                    // Description
                    Text(
                      AppLanguage.descriptionText[language],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppFont.fontFamily,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      language == 0
                          ? (((adDetails['description_english'] ?? '')
                                  .toString()
                                  .trim()
                                  .isEmpty)
                              ? "NA"
                              : adDetails['description_english'])
                          : (((adDetails['description_arabic'] ?? '')
                                  .toString()
                                  .trim()
                                  .isEmpty)
                              ? "N/A"
                              : adDetails['description_arabic']),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        fontFamily: AppFont.fontFamily,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
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
                          propertyBookingApiCall();
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
              const Text(
                'Cancellations made more than 5 days before the check-in date will receive a full refund of the total booking amount. Cancellations made between 2 to 5 days before the check-in date will receive a 50% refund. No refunds will be issued for cancellations made within 2 days of the check-in date.',
                style: TextStyle(
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

  String _firstSelectedDateText() {
    if (widget.selectedDays.isEmpty) {
      return "N/A";
    }
    final days = widget.selectedDays.toList()..sort((a, b) => a.compareTo(b));
    return DateFormat('MMM dd, yyyy').format(days.first);
  }

  String _firstSelectedDateForApi() {
    if (widget.selectedDays.isEmpty) {
      return "";
    }
    final days = widget.selectedDays.toList()..sort((a, b) => a.compareTo(b));
    return DateFormat('yyyy-MM-dd').format(days.first);
  }

  String _lastSelectedDateForApi() {
    if (widget.selectedDays.isEmpty) {
      return "";
    }
    final days = widget.selectedDays.toList()..sort((a, b) => a.compareTo(b));
    return DateFormat('yyyy-MM-dd').format(days.last);
  }

  String _selectedDatesForApi() {
    if (widget.selectedDays.isEmpty) {
      return "";
    }
    final days = widget.selectedDays.toList()..sort((a, b) => a.compareTo(b));
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
}
