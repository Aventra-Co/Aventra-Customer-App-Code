import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../chat/chat_screen.dart';
import '../../controller/app_button.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../../model/chat_user.dart';
import '../authentication/login_screen.dart';
import '../other_screen/cancel_booking.dart';
import 'property_detail_screen.dart';
import 'view_property_details_screen.dart';
import 'dart:ui' as ui;

class PropertyPendingDetailsScreen extends StatefulWidget {
  final int propertyBookingId;
  const PropertyPendingDetailsScreen(
      {super.key, required this.propertyBookingId});

  @override
  State<PropertyPendingDetailsScreen> createState() =>
      _PropertyPendingDetailsScreenState();
}

class _PropertyPendingDetailsScreenState
    extends State<PropertyPendingDetailsScreen> {
  dynamic bookingDetails = {};
  String allActivity = "";
  bool isApiCalling = true;
  int selectedImageInd = 0;
  String showFormattedDates = '';
  List<dynamic> tripImages = [];
  List<dynamic> offerings = [];
  dynamic userDetails;
  int userId = 0;

  //map
  double longitudex = 77.4126;
  double latitudex = 23.2599;
  GoogleMapController? mapController;
  LatLng initialPosition = const LatLng(23.2599, 77.4126);

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

//--------------------GET USER DETAILS-----------------------//
  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userDetails = prefs.getString("userDetails");
    setState(() {
      isApiCalling = true;
    });

    // print("userDetails $userDetails");
    if (userDetails != null) {
      dynamic data = json.decode(userDetails);
      print("up $data");
      userId = data['user_id'];
    }
    setState(() {
      isApiCalling = false;
    });
    getAdDetailsApi(userId);
    setState(() {});
  }

  //=============================GET Advertisement DETAILS===================================//
  Future<void> getAdDetailsApi(userId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}view_property_booking_by_bookingid?user_id=$userId&property_booking_id=${widget.propertyBookingId}");
    print("url $url");

    String token = AppConstant.token;

    if (token.isEmpty) {
      print("Token is missing!");
      return;
    }

    Map<String, String> headers = {
      'Authorization': 'Bearer $token', // Use 'Bearer' if required
    };

    setState(() {
      isApiCalling = true;
    });

    print("headers $headers");

    try {
      final response = await http.get(url, headers: headers);
      print("response $response");

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print("res $res");

        if (res['success'] == true) {
          var item = res['data'];
          bookingDetails = (item != "NA") ? item : [];
          offerings = bookingDetails['amenities'] ?? [];
          latitudex = double.parse(bookingDetails['latitude']);
          longitudex = double.parse(bookingDetails['longitude']);
          initialPosition = LatLng(latitudex, longitudex);
          setState(() {
            isApiCalling = false;
          });
        } else {
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }
          setState(() {
            isApiCalling = false;
          });
        }
      } else {
        print("Error: ${response.statusCode}");
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (e) {
      print("Exception: $e");
      setState(() {
        isApiCalling = false;
      });
    }
  }

  //!Open Map
  //!Open Map
  Future<void> openMap(String latitude, String longitude) async {
    final String device = AppConstant.deviceType;

    Uri? appUri;
    final Uri webUri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude",
    );

    if (device == "android") {
      // Google Maps app (Android)
      appUri = Uri.parse("google.navigation:q=$latitude,$longitude");
    } else if (device == "ios") {
      // Apple Maps (iOS)
      appUri = Uri.parse("maps://?q=$latitude,$longitude");
    }

    try {
      if (appUri != null && await canLaunchUrl(appUri)) {
        await launchUrl(
          appUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
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

    return Directionality(
      textDirection:
          language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 100 / 100,
            height: MediaQuery.of(context).size.height * 100 / 100,
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 7 / 100,
                  width: MediaQuery.of(context).size.width * 90 / 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Transform.rotate(
                          angle: language == 1 ? 3.1416 : 0,
                          child: SizedBox(
                            height: MediaQuery.of(context).size.width * 5 / 100,
                            width: MediaQuery.of(context).size.width * 5 / 100,
                            child: Image.asset(
                              AppImage.navigateBackIcon,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.width * 4 / 100,
                        width: MediaQuery.of(context).size.width * 4 / 100,
                      ),
                      Text(AppLanguage.detailsText[language],
                          style: const TextStyle(
                              color: AppColor.primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily)),
                      const Spacer(),
                      Text("ID: #${bookingDetails['booking_random_id'] ?? ""}",
                          style: const TextStyle(
                              color: AppColor.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              fontFamily: AppFont.fontFamily)),
                    ],
                  ),
                ),
                if (bookingDetails.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: size.height * 0.01),
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: size.width * 0.05),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            AppLanguage.upcomingText[language],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: AppFont.fontFamily,
                                              color: AppColor.pendingColor,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ViewPropertyDetailsScreen(
                                                          adDetails:
                                                              bookingDetails),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              AppLanguage
                                                  .viewDetailsText[language],
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  color: Color(0xFF17A2B8),
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor:
                                                      AppColor.completedColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bookingDetails[
                                                    'property_name_english'] ??
                                                "",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: AppFont.fontFamily,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            bookingDetails['property_type_name']
                                                    [language] ??
                                                "",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: AppFont.fontFamily,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${AppLanguage.guardText[language]} \u2022 ${language == 0 ? (((bookingDetails['guard_name_english'] ?? "").toString().trim().isEmpty) ? "NA" : bookingDetails['guard_name_english'] ?? "") : (((bookingDetails['guard_name_arabic'] ?? "").toString().trim().isEmpty) ? "N/A" : bookingDetails['guard_name_arabic'] ?? "")}",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: AppFont.fontFamily,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    "${AppConfigProvider.imageURL}${bookingDetails['cover_image']}",
                                    width: size.width * 0.18,
                                    height: size.width * 0.18,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: size.height * 0.02),

                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.05),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Location Address
                                Text(
                                  AppLanguage.locationAddressText[language],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: AppFont.fontFamily,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: size.height * 0.01),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  child: Text(
                                    bookingDetails['address'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFont.fontFamily,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                SizedBox(height: size.height * 0.02),

                                //!View Location
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        openMap(bookingDetails['latitude'],
                                            bookingDetails['longitude']);
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                42 /
                                                100,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          AppLanguage
                                              .getDirectionsText[language],
                                          style: const TextStyle(
                                              fontFamily: AppFont.fontFamily,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColor.themeColor,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  AppColor.themeColor),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100),

                                //!Map
                                Stack(children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              18 /
                                              100,
                                      width: MediaQuery.of(context).size.width *
                                          90 /
                                          100,
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
                                            position:
                                                LatLng(latitudex, longitudex),
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
                                Text(
                                  AppLanguage.bookingDetailsText[language],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: AppFont.fontFamily,
                                    // color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: size.height * 0.02),

                                _detailRow(
                                    context,
                                    AppImage.callenderIcon,
                                    bookingDetails['booking_date'] ?? '',
                                    AppLanguage.checkInDateText[language],
                                    AppLanguage.changeText[language],
                                    0, () {
                                  Navigator.pop(context);
                                }),
                                SizedBox(height: size.height * 0.02),

                                _detailRow(
                                    context,
                                    AppImage.clockIcon,
                                    bookingDetails['booking_time_label'] ?? "",
                                    // '$totalDates ${AppLanguage.daysText[language]}',
                                    AppLanguage.bookingDays[language],
                                    AppLanguage.changeText[language],
                                    0, () {
                                  Navigator.pop(context);
                                }),
                                SizedBox(height: size.height * 0.02),

                                _detailRow(
                                    context,
                                    AppImage.guestsIcon,
                                    '${bookingDetails['max_adult'] ?? "0"} ${AppLanguage.adultText[language]} \u2022 ${bookingDetails['max_child'] ?? "0"} ${AppLanguage.childrenText[language]}',
                                    AppLanguage.guestsText[language],
                                    AppLanguage.changeText[language],
                                    0, () {
                                  Navigator.pop(context);
                                }),
                                SizedBox(height: size.height * 0.03),

                                // Description
                                if (bookingDetails['description_english']
                                            [language] !=
                                        null &&
                                    bookingDetails['description_english']
                                            [language]
                                        .isNotEmpty &&
                                    bookingDetails['description_english']
                                            [language] !=
                                        "NA") ...[
                                  Text(
                                    AppLanguage.descriptionText[language],
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFont.fontFamily,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: size.height * 0.015),
                                  Text(
                                    (bookingDetails['description_english']
                                                    [language]
                                                ?.toString()
                                                .trim()
                                                .isNotEmpty ??
                                            false)
                                        ? bookingDetails['description_english']
                                            [language]
                                        : "NA",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: AppFont.fontFamily,
                                      color: Colors.grey.shade700,
                                      height: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: size.height * 3 / 100),
                                ],
                                Text(
                                  AppLanguage.whatThisplaceOfferText[language],
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: AppFont.fontFamily,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: size.height * 0.01),
                                _amenitiesGrid(context),

                                SizedBox(height: size.height * 0.03),

                                GestureDetector(
                                  onTap: () =>
                                      _showCancellationPolicyDialog(context),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Image.asset(
                                        AppImage.cancellationPolicyicon,
                                        width: size.width * 0.045,
                                      ),
                                      SizedBox(width: size.width * 0.02),
                                      Text(
                                        AppLanguage
                                            .cancellationPolicyText[language],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily,
                                          color: AppColor.themeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: size.height * 0.03),

                          // Billing Details
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: size.height * 0.02,
                                horizontal: size.width * 0.04),
                            color: AppColor.lightGreen,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: size.height * 0.018),
                                  Text(
                                    AppLanguage.billingDetailsText[language],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: AppFont.fontFamily,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: size.height * 2 / 100),
                                  _billingRow(
                                      size,
                                      bookingDetails['booking_time_label'] ??
                                          "",
                                      '${bookingDetails['total_amount'] ?? "0"} KWD',
                                      ''),
                                  Divider(height: size.height * 2 / 100),
                                  _billingRow(
                                      size,
                                      AppLanguage.grandTotalText[language],
                                      '${bookingDetails['total_amount'] ?? "0"} KWD',
                                      '',
                                      isBold: true),
                                  if (bookingDetails['discount_percentage'] !=
                                          0 &&
                                      bookingDetails['discount_percentage'] !=
                                          null &&
                                      bookingDetails['discount_percentage'] !=
                                          "NA")
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "+${AppLanguage.withText[language]} ${bookingDetails['discount_percentage']}% ${AppLanguage.discountText[language]}",
                                          style: const TextStyle(
                                              color: AppColor.primaryColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: AppFont.fontFamily),
                                        ),
                                      ],
                                    ),
                                  if (bookingDetails['coupon_code'] != null &&
                                      bookingDetails['coupon_code']
                                          .isNotEmpty &&
                                      bookingDetails['coupon_code'] != "NA")
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "+${AppLanguage.withText[language]} ${bookingDetails['coupon_discount']}% ${AppLanguage.couponDiscountText[language]}",
                                          style: const TextStyle(
                                              color: AppColor.primaryColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: AppFont.fontFamily),
                                        ),
                                      ],
                                    ),
                                  Divider(height: size.height * 2 / 100),
                                  SizedBox(height: size.height * 0.02),
                                ]),
                          ),

                          SizedBox(height: size.height * 0.02),

                          // Cancel Booking
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CancelBooking(
                                            cancelType: 2,
                                            tripBookingId: "0",
                                            propertyBookingId:
                                                widget.propertyBookingId,
                                          )));
                              // _showCancelBookingModal(context);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: size.height * 0.014,
                                  horizontal: size.width * 0.05),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Cancel Booking',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily,
                                          // color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(width: size.width * 0.015),
                                      const Icon(Icons.info_outline,
                                          size: 16, color: Colors.grey),
                                    ],
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),
                          Center(
                            child: AppButton(
                                text: AppLanguage.chatText[language],
                                onPress: () {
                                  log("bookingDetails['owner_id'] ${bookingDetails['owner_id']}");
                                  navigateToChatScreen(
                                      bookingDetails['owner_id'].toString());
                                }),
                          ),
                          SizedBox(height: size.height * 0.05),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _amenitiesGrid(context) {
    return Wrap(
      runSpacing: 10,
      spacing: 20,
      children: List.generate(offerings.length, (index) {
        var sub = offerings[index];
        final amenityName = sub['name']?.toString() ?? '';
        final image = sub['amenity_icon']?.toString() ?? '';
        return SizedBox(
            width: MediaQuery.of(context).size.width * 42 / 100,
            child: FeatureItem(title: amenityName, icon: image));
      }),
    );
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

  Widget _buildDottedLine() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 2.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade400),
              ),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }

  Widget _billingRow(Size size, String label, String amount, String subtitle,
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
                fontSize: 16,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                fontFamily: AppFont.fontFamily,
                color: Colors.black,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppFont.fontFamily,
              ),
            ),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          SizedBox(height: size.height * 0.005),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              fontFamily: AppFont.fontFamily,
              color: AppColor.completedColor,
            ),
          ),
        ],
      ],
    );
  }

  void _showCancellationPolicyDialog(context) {
    final size = MediaQuery.of(context).size;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, //
              borderRadius: BorderRadius.circular(16),
            ),
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
                    color: AppColor.themeColor,
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                Text(
                  AppLanguage.cancelDetailsText[language],
                  style: const TextStyle(
                    fontSize: 13.8,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFont.fontFamily,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _billingSubRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            fontFamily: AppFont.fontFamily,
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: AppFont.fontFamily,
          ),
        ),
      ],
    );
  }

  void _showBookingTimeModal(BuildContext context) {
    String selectedPrice = 'One day (2pm till next day 12 afternoon)';

    final List<Map<String, String>> priceOptions = [
      {
        'title': 'One day (2pm till next day 12 afternoon)',
        'price': '200 KWD',
      },
      {
        'title': 'Weekday (Sun-Wed)',
        'price': '300 KWD',
      },
      {
        'title': 'Weekend (Thu-Sat)',
        'price': '350 KWD',
      },
      {
        'title': 'Full week (Sun-Sat)',
        'price': '500 KWD',
      },
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final size = MediaQuery.of(context).size;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: size.width * 8 / 100,
                    height: size.height * 8 / 100,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.01),

                // ✅ Main bottomsheet container
                Container(
                  padding: EdgeInsets.all(size.width * 0.05),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: size.height * 0.01),

                      // Title
                      const Text(
                        'Booking Time',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppFont.fontFamily,
                          color: Colors.black,
                        ),
                      ),

                      SizedBox(height: size.height * 0.02),

                      // Radio options
                      ...priceOptions.map((option) {
                        final isSelected = selectedPrice == option['title'];
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedPrice = option['title']!;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: size.height * 0.012),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColor.themeColor
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 11,
                                            height: 11,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColor.themeColor,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                SizedBox(width: size.width * 0.03),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option['title']!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        option['price']!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: AppFont.fontFamily,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      SizedBox(height: size.height * 0.025),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        height: size.height * 0.06,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.themeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCalenderDateModal(BuildContext context) {
    DateTime _selectedDay = DateTime.now();
    DateTime _focusedDay = DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final size = MediaQuery.of(context).size;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Floating close button center mein
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: size.width * 0.08,
                    height: size.height * 0.08,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.01),

                // ✅ Main white container
                Container(
                  padding: EdgeInsets.all(size.width * 0.05),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: size.height * 0.01),

                      // Title
                      const Text(
                        'Booking Date',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppFont.fontFamily,
                          color: Colors.black,
                        ),
                      ),

                      SizedBox(height: size.height * 0.02),

                      // Legend row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _legendItem(
                              context, AppLanguage.bookNowText[language], null),
                          SizedBox(width: size.width * 0.08),
                          _legendItem(
                              context, 'Availability', const Color(0xFF009FE3)),
                          _legendItem(context, 'Selected', AppColor.themeColor),
                        ],
                      ),

                      SizedBox(height: size.height * 0.01),

                      // Calendar
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setModalState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          setModalState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month',
                        },
                        calendarBuilders: CalendarBuilders(
                          headerTitleBuilder: (context, date) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.02),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMMM').format(date),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: AppFont.fontFamily,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('yyyy').format(date),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFont.fontFamily,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: false,
                          headerPadding: EdgeInsets.symmetric(
                              vertical: size.height * 0.01),
                          leftChevronIcon: const SizedBox.shrink(),
                          rightChevronIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.017,
                                  vertical: size.height * 0.008,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.chevron_left,
                                    color: AppColor.themeColor, size: 20),
                              ),
                              SizedBox(width: size.width * 0.01),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.017,
                                  vertical: size.height * 0.008,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.chevron_right,
                                    color: AppColor.themeColor, size: 20),
                              ),
                            ],
                          ),
                          leftChevronMargin: EdgeInsets.zero,
                          rightChevronMargin: EdgeInsets.zero,
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.white,
                          ),
                          weekendStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.white,
                          ),
                          decoration: BoxDecoration(color: AppColor.themeColor),
                        ),
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: AppColor.themeColor.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.black87,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppColor.themeColor,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.white,
                          ),
                          defaultTextStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.black87,
                          ),
                          weekendTextStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.black87,
                          ),
                          outsideTextStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.grey.shade400,
                          ),
                          cellMargin: const EdgeInsets.all(6),
                        ),
                      ),

                      SizedBox(height: size.height * 0.025),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        height: size.height * 0.06,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.themeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.02),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGuestModal(BuildContext context) {
    int adultCount = 0;
    int childCount = 4;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final size = MediaQuery.of(context).size;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: size.width * 0.08,
                    height: size.height * 0.08,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.black, size: 18),
                  ),
                ),

                SizedBox(height: size.height * 0.01),

                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.05,
                    vertical: size.height * 0.025,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: size.height * 0.01),

                      // Title
                      const Text(
                        'Guests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppFont.fontFamily,
                          color: Colors.black,
                        ),
                      ),

                      SizedBox(height: size.height * 0.03),

                      // Adult row
                      _guestCounterRow(
                        context,
                        label: 'Adult',
                        count: adultCount,
                        onDecrement: () {
                          if (adultCount > 0) {
                            setModalState(() => adultCount--);
                          }
                        },
                        onIncrement: () {
                          setModalState(() => adultCount++);
                        },
                      ),

                      Divider(
                          color: Colors.grey.shade200,
                          height: size.height * 0.04),

                      // Child row
                      _guestCounterRow(
                        context,
                        label: 'Child',
                        count: childCount,
                        onDecrement: () {
                          if (childCount > 0) {
                            setModalState(() => childCount--);
                          }
                        },
                        onIncrement: () {
                          setModalState(() => childCount++);
                        },
                      ),

                      SizedBox(height: size.height * 0.03),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        height: size.height * 0.06,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.themeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.02),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _guestCounterRow(
    BuildContext context, {
    required String label,
    required int count,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    final size = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: AppFont.fontFamily,
            color: Colors.black87,
          ),
        ),
        Row(
          children: [
            // Decrement button
            GestureDetector(
              onTap: onDecrement,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child:
                    const Icon(Icons.remove, size: 16, color: Colors.black87),
              ),
            ),

            SizedBox(width: size.width * 0.04),

            // Count
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppFont.fontFamily,
                color: Colors.black,
              ),
            ),

            SizedBox(width: size.width * 0.04),

            // Increment button
            GestureDetector(
              onTap: onIncrement,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(BuildContext context, label, Color? dotColor) {
    final size = MediaQuery.of(context).size;
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: AppFont.fontFamily,
            color: Colors.black87,
          ),
        ),
        if (dotColor != null) ...[
          SizedBox(width: size.width * 0.015),
          Container(
            width: size.width * 0.035,
            height: size.width * 0.035,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  void _showCancelBookingModal(BuildContext context) {
    String selectedReason = '';
    final TextEditingController descController = TextEditingController();

    final List<String> cancelReasons = [
      'Found another property',
      'Price too high',
      'Location not suitable',
      'Location too far',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final size = MediaQuery.of(context).size;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Floating close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: size.width * 0.08,
                      height: size.height * 0.08,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.black, size: 18),
                    ),
                  ),

                  SizedBox(height: size.height * 0.01),

                  // Main white container
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.05,
                      vertical: size.height * 0.025,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: size.height * 0.01),

                        // Title
                        const Center(
                          child: Text(
                            'Cancel Reasons',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: AppFont.fontFamily,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        SizedBox(height: size.height * 0.02),

                        // Radio options
                        ...cancelReasons.map((reason) {
                          final isSelected = selectedReason == reason;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedReason = reason;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: size.height * 0.012),
                              child: Row(
                                children: [
                                  // Radio button
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColor.themeColor
                                            : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 11,
                                              height: 11,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColor.themeColor,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: size.width * 0.03),
                                  Text(
                                    reason,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFont.fontFamily,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        SizedBox(height: size.height * 0.02),

                        // Describe the issue label
                        const Text(
                          'Describe the issue',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: size.height * 0.01),

                        // Text field
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: descController,
                            maxLines: 4,
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: AppFont.fontFamily,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Write more details here to help us understand the problem...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                fontFamily: AppFont.fontFamily,
                                color: Colors.grey.shade400,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(size.width * 0.03),
                            ),
                          ),
                        ),

                        SizedBox(height: size.height * 0.025),

                        // Confirm Cancel button
                        SizedBox(
                          width: double.infinity,
                          height: size.height * 0.06,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigator.pushReplacement(
                              //   context,
                              //   MaterialPageRoute(
                              //       builder: (context) =>
                              //           PropertyBookingHistoryDetailScreen(
                              //               iscompleted: false)),
                              // );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.themeColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              'Confirm Booking Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFont.fontFamily,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: size.height * 0.02),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// ================navigationchat==========//
  void navigateToChatScreen(String userId) {
    print(userId);
    // Flag to prevent multiple navigations
    bool isNavigated = false;

    // Listen for changes in the Firestore collection "users"
    FirebaseFirestore.instance
        .collection("users")
        .snapshots()
        .listen((snapshot) {
      // If already navigated, return early to prevent further navigation
      if (isNavigated) return;

      // Find the user with the matching ID
      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data['id'] == userId) {
          // Create the ChatUser object from the matched document data
          ChatUser user = ChatUser.fromJson(data);

          // Navigate to ChatScreen with the user data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(user: user),
            ),
          );

          // Set the flag to true to prevent further navigation
          isNavigated = true;
          break; // Exit loop once the user is found and the screen is navigated
        }
      }
    });
  }
}
