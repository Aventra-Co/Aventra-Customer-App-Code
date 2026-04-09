import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '/controller/app_color.dart';
import '/controller/app_constant.dart';
import '/controller/app_font.dart';
import '/controller/app_header.dart';
import '/controller/app_image.dart';
import '/controller/app_language.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
// import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../authentication/login_screen.dart';
import '../other_screen/review.dart';
import 'property_booking_details.dart';
import 'dart:ui' as ui;

class RedirectionPropertyDetailsScreen extends StatefulWidget {
  const RedirectionPropertyDetailsScreen(
      {super.key, required this.propertyAdId});
  final int propertyAdId;

  @override
  State<RedirectionPropertyDetailsScreen> createState() =>
      _RedirectionPropertyDetailsScreenState();
}

class _RedirectionPropertyDetailsScreenState
    extends State<RedirectionPropertyDetailsScreen> {
  int currentImageIndex = 0;
  DateTime _focusedDay = DateTime.now();
  int imageSelected = 0;
  int _totalNights = 0;
  double _grandTotal = 0;
  int isSelected = 1;

  Set<DateTime> _selectedDays = {};

  // ── Time slot state ───────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────

  // Unavailable dates (non-selectable)
  Set<DateTime> _unavailableDates = {};

  int adultCount = 0;
  int childCount = 0;

  DateTime _normalise(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isUnavailable(DateTime day) =>
      _unavailableDates.any((d) => isSameDay(d, day));

  DateTime? _parseUnavailableDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }

    try {
      // yyyy-MM-dd
      if (value.split('-').first.length == 4) {
        return _normalise(DateFormat('yyyy-MM-dd').parseStrict(value));
      }
      // dd-MM-yy (e.g., 26-03-24)
      if (value.split('-').last.length == 2) {
        return _normalise(DateFormat('dd-MM-yy').parseStrict(value));
      }
      // dd-MM-yyyy
      return _normalise(DateFormat('dd-MM-yyyy').parseStrict(value));
    } catch (_) {
      return null;
    }
  }

  Set<DateTime> _buildUnavailableDates(dynamic rawList) {
    if (rawList is! List) {
      return {};
    }
    final result = <DateTime>{};
    for (final item in rawList) {
      final parsed = _parseUnavailableDate(item.toString());
      if (parsed != null) {
        result.add(parsed);
      }
    }
    return result;
  }

  bool _isSelectableDate(DateTime day) {
    final today = _normalise(DateTime.now());
    final lastAllowed = today.add(const Duration(days: 365));
    final normalisedDay = _normalise(day);
    if (normalisedDay.isBefore(today) || normalisedDay.isAfter(lastAllowed)) {
      return false;
    }
    if (_isUnavailable(day)) {
      return false;
    }
    return true;
  }

  bool _isWeekdayGroup(DateTime day) =>
      day.weekday == DateTime.sunday || day.weekday <= DateTime.wednesday;

  bool _isWeekendGroup(DateTime day) =>
      day.weekday >= DateTime.thursday && day.weekday <= DateTime.saturday;

  DateTime _startOfWeekSunday(DateTime day) {
    final normalisedDay = _normalise(day);
    final daysFromSunday = normalisedDay.weekday % 7;
    return normalisedDay.subtract(Duration(days: daysFromSunday));
  }

  Set<DateTime> _buildBlockFor(DateTime anchor) {
    final startOfWeek = _startOfWeekSunday(anchor);
    final dates = <DateTime>{};
    switch (isSelected) {
      case 1:
        dates.add(_normalise(anchor));
        break;
      case 2:
        for (int i = 0; i < 4; i++) {
          dates.add(startOfWeek.add(Duration(days: i)));
        }
        break;
      case 3:
        for (int i = 4; i < 7; i++) {
          dates.add(startOfWeek.add(Duration(days: i)));
        }
        break;
      case 4:
        for (int i = 0; i < 7; i++) {
          dates.add(startOfWeek.add(Duration(days: i)));
        }
        break;
      default:
        break;
    }
    return dates;
  }

  bool _isBlockSelectable(DateTime anchor) {
    final block = _buildBlockFor(anchor);
    if (block.isEmpty) {
      return false;
    }
    return block.every(_isSelectableDate);
  }

  void _selectPricingType(int type) {
    if (isSelected == type) {
      return;
    }
    setState(() {
      isSelected = type;
      _selectedDays = {};
      _totalNights = 0;
      _grandTotal = 0;
    });
  }

  void _applyBlockSelection(DateTime selectedDay, DateTime focusedDay) {
    final normalisedDay = _normalise(selectedDay);
    if (!_isSelectableDate(normalisedDay)) {
      return;
    }

    if (isSelected == 2 && !_isWeekdayGroup(normalisedDay)) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.selectDateMsg[language]);
      return;
    }
    if (isSelected == 3 && !_isWeekendGroup(normalisedDay)) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.selectDateMsg[language]);
      return;
    }

    if (!_isBlockSelectable(normalisedDay)) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.selectDateMsg[language]);
      return;
    }

    final block = _buildBlockFor(normalisedDay);
    setState(() {
      _focusedDay = focusedDay;
      _selectedDays = block;
      _totalNights = block.length;
      _recalculateGrandTotal();
    });
  }

  DateTime _clampFocusedDay(DateTime day) {
    final today = _normalise(DateTime.now());
    final lastAllowed = today.add(const Duration(days: 365));
    if (day.isBefore(today)) {
      return today;
    }
    if (day.isAfter(lastAllowed)) {
      return lastAllowed;
    }
    return day;
  }

  //=============add favorite trip API================//
  Future<void> addFavoriteApiCall(tripId, entity) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}add_favourite");
    print("Url $url");
    setState(() {
      isApiCalling = false;
    });
    String token = AppConstant.token;
    try {
      var headers = {
        'Authorization': 'Bearer $token',
      };

      var body = {
        'user_id': userId.toString(),
        'trip_id': tripId.toString(),
        'entity_type': entity.toString(),
      };

      print("body $body");

      http.Response response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      print("response--> $response");
      var res = jsonDecode(response.body);

      print("res333 : $res");
      if (response.statusCode == 200) {
        print("res : $res");
        if (res['success'] == true) {
          setState(() {
            adDetails['favourite_status'] = res['favourite_status'];
          });
          SnackBarToastMessage.showSnackBar(context, res['message'][language]);
          setState(() {
            isApiCalling = false;
          });
        } else {
          setState(() {
            isApiCalling = false;
          });
          // ignore: use_build_context_synchronously
          SnackBarToastMessage.showSnackBar(context, res['message'][language]);
          if (res['active_flag'] == 0) {
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

  void _recalculateGrandTotal() {
    if (_selectedDays.isEmpty || adDetails is! Map) {
      _grandTotal = 0;
      return;
    }
    switch (isSelected) {
      case 1:
        _grandTotal = _asDouble(adDetails['one_day_price']);
        break;
      case 2:
        _grandTotal = _asDouble(adDetails['weekday_price']);
        break;
      case 3:
        _grandTotal = _asDouble(adDetails['weekend_price']);
        break;
      case 4:
        _grandTotal = _asDouble(adDetails['full_week_price']);
        break;
      default:
        _grandTotal = 0;
    }
  }

  double _asDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }

  dynamic adDetails = {};
  String allActivity = "";
  bool isApiCalling = true;
  int selectedImageInd = 0;
  String showFormattedDates = '';
  List<dynamic> propertyImages = [];
  List<dynamic> offerings = [];
  dynamic userDetails;
  int userId = 0;

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
        "${AppConfigProvider.apiUrl}view_property_advertisements?user_id=$userId&property_ad_id=${widget.propertyAdId}");
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
          adDetails = (item != "NA") ? item : [];
          if (adDetails['one_day_active'] == 1) {
            isSelected = 1;
          } else if (adDetails['weekday_active'] == 1) {
            isSelected = 2;
          } else if (adDetails['weekend_active'] == 1) {
            isSelected = 3;
          } else if (adDetails['full_week_active'] == 1) {
            isSelected = 4;
          }
          if (adDetails is Map && adDetails['unavailable_dates'] != null) {
            _unavailableDates =
                _buildUnavailableDates(adDetails['unavailable_dates']);
          }
          if (adDetails['property_images'] != "NA") {
            propertyImages.addAll(adDetails['property_images']);
            offerings = adDetails['amenities'] ?? [];
          }
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

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
        inAsyncCall: isApiCalling,
        opacity: 0.5,
        child: _buildUIScreen(context));
  }

  Widget _buildUIScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // final double sw = MediaQuery.of(context).size.width;
    final double sw = MediaQuery.of(context).size.width;
    final double sh = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColor.secondaryColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Directionality(
        textDirection:
            language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Container(
              color: AppColor.secondaryColor,
              width: MediaQuery.of(context).size.width * 100 / 100,
              height: MediaQuery.of(context).size.height * 100 / 100,
              child: Column(
                children: [
                  AppHeader(
                      text: AppLanguage.detailsText[language],
                      onPress: () => Navigator.pop(context)),
                  SizedBox(height: size.height * 0.01),
                  if (!isApiCalling)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            //!==================IMAGE CODE=====================//
                            if (propertyImages.isNotEmpty)
                              propertyImages.isNotEmpty
                                  ? Container(
                                      color: AppColor.creamColor,
                                      width: MediaQuery.of(context).size.width *
                                          100 /
                                          100,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                90 /
                                                100,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                25 /
                                                100,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              image: DecorationImage(
                                                  image: propertyImages[
                                                                  imageSelected]
                                                              ['image_path'] !=
                                                          null
                                                      ? NetworkImage(
                                                          "${AppConfigProvider.imageURL}${propertyImages[imageSelected]['image_path']}")
                                                      : const AssetImage(AppImage
                                                              .imageFrameImage)
                                                          as ImageProvider,
                                                  fit: BoxFit.cover),
                                            ),
                                          ),
                                          SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  3 /
                                                  100),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                100 /
                                                100,
                                            child: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  100 /
                                                  100,
                                              child: SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Wrap(
                                                  spacing: 8,
                                                  runSpacing: 6,
                                                  children: List.generate(
                                                      propertyImages.length,
                                                      (index) {
                                                    return Padding(
                                                      padding: language == 0
                                                          ? EdgeInsets.only(
                                                              left: index == 0
                                                                  ? screenWidth >
                                                                          600
                                                                      ? 20
                                                                      : 18
                                                                  : 0,
                                                              right: index ==
                                                                      propertyImages
                                                                              .length -
                                                                          1
                                                                  ? 10
                                                                  : 0)
                                                          : EdgeInsets.only(
                                                              right: index == 0
                                                                  ? screenWidth >
                                                                          600
                                                                      ? 20
                                                                      : 18
                                                                  : 10,
                                                              left: index ==
                                                                      propertyImages
                                                                              .length -
                                                                          1
                                                                  ? 0
                                                                  : 0),
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            imageSelected =
                                                                index;
                                                          });
                                                        },
                                                        child: Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              18 /
                                                              100,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              18 /
                                                              100,
                                                          decoration: BoxDecoration(
                                                              image: DecorationImage(
                                                                  image: propertyImages[index]
                                                                              [
                                                                              'image_path'] !=
                                                                          null
                                                                      ? NetworkImage(
                                                                          "${AppConfigProvider.imageURL}${propertyImages[index]['image_path']}")
                                                                      : const AssetImage(
                                                                              AppImage.imageFrameImage)
                                                                          as ImageProvider,
                                                                  fit: BoxFit
                                                                      .cover),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16)),
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                                  : Container(),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100),

                            _partDetials(adDetails),

                            SizedBox(height: sh * 0.02),

                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                75 /
                                                100,
                                        child: Text(
                                          adDetails['property_name_english'] ??
                                              "",
                                          style: const TextStyle(
                                            fontSize: 23,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: AppFont.fontFamily,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          addFavoriteApiCall(
                                              adDetails['property_ad_id'], 1);
                                        },
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              8 /
                                              100,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              8 /
                                              100,
                                          child: Image.asset(
                                              adDetails['favourite_status'] == 0
                                                  ? AppImage.likeDeactiveIcon
                                                  : AppImage.likeActiveIcon),
                                        ),
                                      )
                                    ],
                                  ),
                                  Text(
                                    adDetails['property_type_name'][language] ??
                                        "",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFont.fontFamily,
                                    ),
                                  ),
                                  SizedBox(height: size.height * 0.01),
                                  Row(
                                    children: [
                                      Image.asset(AppImage.redLocationIcon,
                                          width: size.width * 0.04,
                                          height: size.height * 0.04),
                                      SizedBox(width: size.width * 0.01),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                85 /
                                                100,
                                        child: Text(
                                          adDetails['address'] ?? "",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: AppFont.fontFamily,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: size.height * 0.02),

                                  _detailGrid(adDetails),
                                  SizedBox(height: size.height * 0.04),

                                  // ── DESCRIPTION ──────────────────────────────────────
                                  if (language == 0) ...[
                                    if (adDetails['description_english'] !=
                                            null &&
                                        adDetails['description_english']
                                            .isNotEmpty &&
                                        adDetails['description_english'] !=
                                            "NA") ...[
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppLanguage
                                                .descriptionText[language],
                                            style: const TextStyle(
                                              fontSize: 21,
                                              fontWeight: FontWeight.w500,
                                              color: AppColor.primaryColor,
                                              fontFamily: AppFont.fontFamily,
                                            ),
                                          ),
                                          SizedBox(height: sh * 0.01),
                                          Text(
                                            adDetails['description_english'] ??
                                                "NA",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                              color: AppColor.primaryColor,
                                              fontFamily: AppFont.fontFamily,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else if (adDetails[
                                                'description_arabic'] !=
                                            null &&
                                        adDetails['description_arabic']
                                            .isNotEmpty &&
                                        adDetails['description_arabic'] !=
                                            "NA") ...[
                                      SizedBox(height: sh * 0.02),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: sw * 0.04),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLanguage
                                                  .descriptionText[language],
                                              style: const TextStyle(
                                                fontSize: 21,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.primaryColor,
                                                fontFamily: AppFont.fontFamily,
                                              ),
                                            ),
                                            SizedBox(height: sh * 0.01),
                                            Text(
                                              adDetails['description_arabic'] ??
                                                  "NA",
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

                                  // What this place offers
                                  Text(
                                    AppLanguage
                                        .whatThisplaceOfferText[language],
                                    style: const TextStyle(
                                      fontSize: 21.33,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFont.fontFamily,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: size.height * 0.01),
                                  _amenitiesGrid(offerings),
                                  SizedBox(height: size.height * 0.03),

                                  // Checkin checkout time
                                  // Text(
                                  //   "${AppLanguage.timingText[language]}:",
                                  //   style: const TextStyle(
                                  //     fontSize: 20,
                                  //     fontWeight: FontWeight.w700,
                                  //     fontFamily: AppFont.fontFamily,
                                  //   ),
                                  // ),
                                  // SizedBox(height: size.height * 0.01),
                                  // Text(
                                  //   AppLanguage
                                  //       .checkinCheckoutTimeText[language],
                                  //   style: const TextStyle(
                                  //     fontSize: 16,
                                  //     fontWeight: FontWeight.w400,
                                  //     fontFamily: AppFont.fontFamily,
                                  //   ),
                                  // ),
                                  // SizedBox(height: size.height * 0.03),

                                  // Price
                                  Text(
                                    AppLanguage.priceText[language],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: AppFont.fontFamily,
                                    ),
                                  ),
                                  SizedBox(height: size.height * 0.01),

                                  //! One Day Pricing
                                  if (adDetails['one_day_price'] > 0) ...[
                                    GestureDetector(
                                      onTap: () => _selectPricingType(1),
                                      child: Container(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: size.width * 0.05,
                                              height: size.width * 0.05,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color:
                                                          AppColor.themeColor,
                                                      width: 2)),
                                              child: isSelected == 1
                                                  ? Center(
                                                      child: Container(
                                                        width:
                                                            size.width * 0.025,
                                                        height:
                                                            size.width * 0.025,
                                                        decoration:
                                                            const BoxDecoration(
                                                                color: AppColor
                                                                    .themeColor,
                                                                shape: BoxShape
                                                                    .circle),
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            SizedBox(width: size.width * 0.04),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      AppLanguage
                                                          .oneDayText[language],
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontFamily: AppFont
                                                              .fontFamily,
                                                          height: 1.4)),
                                                  SizedBox(
                                                      height:
                                                          size.height * 0.005),
                                                  Text(
                                                      "${adDetails['one_day_price']?.toString() ?? "0"} KWD",
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontFamily: AppFont
                                                              .fontFamily)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: size.height * 0.02),
                                  ],

                                  //! Week Day Pricing
                                  if (adDetails['weekday_price'] > 0) ...[
                                    GestureDetector(
                                      onTap: () => _selectPricingType(2),
                                      child: Container(
                                        // margin: EdgeInsets.only(
                                        //     bottom: size.height * 0.03),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: size.width * 0.05,
                                              height: size.width * 0.05,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color:
                                                          AppColor.themeColor,
                                                      width: 2)),
                                              child: isSelected == 2
                                                  ? Center(
                                                      child: Container(
                                                        width:
                                                            size.width * 0.025,
                                                        height:
                                                            size.width * 0.025,
                                                        decoration:
                                                            const BoxDecoration(
                                                                color: AppColor
                                                                    .themeColor,
                                                                shape: BoxShape
                                                                    .circle),
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            SizedBox(width: size.width * 0.04),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      AppLanguage.weekDaysText[
                                                          language],
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontFamily: AppFont
                                                              .fontFamily,
                                                          height: 1.4)),
                                                  SizedBox(
                                                      height:
                                                          size.height * 0.005),
                                                  Text(
                                                      "${adDetails['weekday_price']?.toString() ?? "0"} KWD",
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontFamily: AppFont
                                                              .fontFamily)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: size.height * 0.02),
                                  ],

                                  //! Weekend Day Pricing
                                  if (adDetails['weekend_price'] > 0) ...[
                                    GestureDetector(
                                      onTap: () => _selectPricingType(3),
                                      child: Container(
                                        // margin: EdgeInsets.only(
                                        //     bottom: size.height * 0.03),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: size.width * 0.05,
                                              height: size.width * 0.05,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color:
                                                          AppColor.themeColor,
                                                      width: 2)),
                                              child: isSelected == 3
                                                  ? Center(
                                                      child: Container(
                                                        width:
                                                            size.width * 0.025,
                                                        height:
                                                            size.width * 0.025,
                                                        decoration:
                                                            const BoxDecoration(
                                                                color: AppColor
                                                                    .themeColor,
                                                                shape: BoxShape
                                                                    .circle),
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            SizedBox(width: size.width * 0.04),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      AppLanguage
                                                              .weekendDaysText[
                                                          language],
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontFamily: AppFont
                                                              .fontFamily,
                                                          height: 1.4)),
                                                  SizedBox(
                                                      height:
                                                          size.height * 0.005),
                                                  Text(
                                                      "${adDetails['weekend_price']?.toString() ?? ""} KWD",
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontFamily: AppFont
                                                              .fontFamily)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: size.height * 0.02),
                                  ],

                                  //! Full Week Pricing
                                  if (adDetails['full_week_price'] > 0) ...[
                                    GestureDetector(
                                      onTap: () => _selectPricingType(4),
                                      child: Container(
                                        // margin: EdgeInsets.only(
                                        //     bottom: size.height * 0.03),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: size.width * 0.05,
                                              height: size.width * 0.05,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color:
                                                          AppColor.themeColor,
                                                      width: 2)),
                                              child: isSelected == 4
                                                  ? Center(
                                                      child: Container(
                                                        width:
                                                            size.width * 0.025,
                                                        height:
                                                            size.width * 0.025,
                                                        decoration:
                                                            const BoxDecoration(
                                                                color: AppColor
                                                                    .themeColor,
                                                                shape: BoxShape
                                                                    .circle),
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            SizedBox(width: size.width * 0.04),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      AppLanguage
                                                              .fullWeekDaysText[
                                                          language],
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontFamily: AppFont
                                                              .fontFamily,
                                                          height: 1.4)),
                                                  SizedBox(
                                                      height:
                                                          size.height * 0.005),
                                                  Text(
                                                      "${adDetails['full_week_price']?.toString() ?? ""} KWD",
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontFamily: AppFont
                                                              .fontFamily)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: size.height * 0.02),
                                  ],

                                  //! Cancellation policy
                                  Row(
                                    children: [
                                      Image.asset(
                                          AppImage.cancellationPolicyicon,
                                          width: size.width * 0.04,
                                          height: size.height * 0.04),
                                      TextButton(
                                        onPressed:
                                            _showCancellationPolicyDialog,
                                        child: Text(
                                          AppLanguage
                                              .cancellationPolicyText[language],
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

                                  // ── LEGEND ──────────────────────────────────────────
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _legendItem(
                                          AppLanguage.bookNowText[language],
                                          null),
                                      SizedBox(width: size.width * 0.08),
                                      _legendItem('Availability',
                                          const Color(0xFF009FE3)),
                                      _legendItem(
                                          'Selected', AppColor.themeColor),
                                    ],
                                  ),

                                  SizedBox(height: size.height * 0.02),

                                  // ── CALENDAR (Figma style) ───────────────────────────
                                  _buildCalendar(size),
                                  SizedBox(height: size.height * 0.02),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColor.themeColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppColor.themeColor
                                              .withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _totalNights > 0
                                              ? '${AppLanguage.forText[language]} $_totalNights ${AppLanguage.daysText[language]}'
                                              : AppLanguage
                                                  .selectDatesText[language],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: AppFont.fontFamily,
                                          ),
                                        ),
                                        Text(
                                          _totalNights > 0
                                              ? '${_grandTotal.toStringAsFixed(2)} KWD'
                                              : '--',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: AppFont.fontFamily,
                                            color: AppColor.themeColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: size.height * 0.03),

                                  // Guests
                                  Text(
                                    AppLanguage.guestsext[language],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: AppFont.fontFamily,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: size.height * 0.012),

                                  _guestCounterRow(context, adultCount,
                                      adDetails['max_adult'],
                                      label: AppLanguage.adultText[language],
                                      count: adultCount, onDecrement: () {
                                    if (adultCount > 0) {
                                      setState(() => adultCount--);
                                    }
                                  }, onIncrement: () {
                                    if (adultCount < adDetails['max_adult']) {
                                      setState(() => adultCount++);
                                    }
                                  }),
                                  Divider(
                                      color: AppColor.boaderColor,
                                      height: size.height * 0.04),

                                  _guestCounterRow(context, childCount,
                                      adDetails['max_child'],
                                      label: AppLanguage.childText[language],
                                      count: childCount, onDecrement: () {
                                    if (childCount > 0) {
                                      setState(() => childCount--);
                                    }
                                  }, onIncrement: () {
                                    if (childCount < adDetails['max_child']) {
                                      setState(() => childCount++);
                                    }
                                  }),

                                  const Divider(color: AppColor.boaderColor),
                                  SizedBox(height: size.height * 0.06),

                                  // Book Now button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_selectedDays.isEmpty ||
                                            _totalNights < 1) {
                                          SnackBarToastMessage.showSnackBar(
                                              context,
                                              AppLanguage
                                                  .selectDateMsg[language]);
                                          return;
                                        }
                                        if (adultCount == 0 &&
                                            childCount == 0) {
                                          SnackBarToastMessage.showSnackBar(
                                              context,
                                              AppLanguage
                                                  .numberOfGuestMsg[language]);
                                          return;
                                        }
                                        final sortedDays = _selectedDays
                                            .toList()
                                          ..sort((a, b) => a.compareTo(b));
                                        final checkinDate = sortedDays.first;
                                        final checkoutDate = checkinDate
                                            .add(Duration(days: _totalNights));

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PropertyBookingDetails(
                                              adDetails: adDetails,
                                              adultCount: adultCount,
                                              childCount: childCount,
                                              checkinDate: checkinDate,
                                              checkoutDate: checkoutDate,
                                              totalNights: _totalNights,
                                              grandTotal: _grandTotal,
                                              propertyAdId: widget.propertyAdId,
                                              pricingType: isSelected,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColor.themeColor,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(25)),
                                      ),
                                      child: Text(
                                        AppLanguage.bookNowText[language],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: AppFont.fontFamily,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: size.height * 0.04),
                                ],
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

  // ── Sub image helper ─────────────────────────────────────────────────
  Widget _subImg(Size size, String path) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(path, height: size.height * 0.1, fit: BoxFit.cover),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // CALENDAR — matches Figma design
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildCalendar(Size size) {
    final today = _normalise(DateTime.now());
    final lastAllowed = today.add(const Duration(days: 365));
    return TableCalendar(
      firstDay: today,
      lastDay: lastAllowed,
      focusedDay: _focusedDay,
      availableGestures: AvailableGestures.none,
      enabledDayPredicate: (day) {
        final normalisedDay = _normalise(day);
        if (!_isSelectableDate(normalisedDay)) {
          return false;
        }
        switch (isSelected) {
          case 1:
            return true;
          case 2:
            return _isWeekdayGroup(normalisedDay) &&
                _isBlockSelectable(normalisedDay);
          case 3:
            return _isWeekendGroup(normalisedDay) &&
                _isBlockSelectable(normalisedDay);
          case 4:
            return _isBlockSelectable(normalisedDay);
          default:
            return false;
        }
      },
      rangeSelectionMode: RangeSelectionMode.disabled,
      selectedDayPredicate: (day) {
        return _selectedDays.any((d) => isSameDay(d, day));
      },
      onDaySelected: (selectedDay, focusedDay) {
        _applyBlockSelection(selectedDay, focusedDay);
      },
      onPageChanged: (focusedDay) =>
          setState(() => _focusedDay = _clampFocusedDay(focusedDay)),
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},

      // ── Custom day cells ──────────────────────────────────────────────
      calendarBuilders: CalendarBuilders(
        // Centered "Month Year" header with chevrons on both sides
        headerTitleBuilder: (context, date) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Left chevron
                GestureDetector(
                  onTap: () => setState(() {
                    final target =
                        DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                    _focusedDay = _clampFocusedDay(target);
                  }),
                  child: const Icon(Icons.chevron_left,
                      color: AppColor.primaryColor, size: 22),
                ),

                SizedBox(
                  width: size.width * 0.03,
                ),

                // Month + Year centred
                Text(
                  DateFormat('MMMM yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFont.fontFamily,
                    color: Colors.black,
                  ),
                ),

                SizedBox(
                  width: size.width * 0.03,
                ),

                // Right chevron
                GestureDetector(
                  onTap: () => setState(() {
                    final target =
                        DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                    _focusedDay = _clampFocusedDay(target);
                  }),
                  child: const Icon(Icons.chevron_right,
                      color: AppColor.primaryColor, size: 22),
                ),
              ],
            ),
          );
        },

        // Default day cell (available dates)
        defaultBuilder: (context, day, focusedDay) {
          return _dayCell(
            day,
            bgColor: AppColor.blueColor,
            textColor: Colors.white,
          );
        },

        // Today (unselected)
        todayBuilder: (context, day, focusedDay) {
          return _dayCell(
            day,
            bgColor: AppColor.blueColor,
            textColor: Colors.white,
            borderColor: AppColor.blueColor,
          );
        },

        // Selected day
        selectedBuilder: (context, day, focusedDay) {
          return _dayCell(
            day,
            bgColor: AppColor.themeColor,
            textColor: Colors.white,
          );
        },

        // Range start
        rangeStartBuilder: (context, day, focusedDay) {
          return _dayCell(
            day,
            bgColor: AppColor.themeColor,
            textColor: Colors.white,
          );
        },

        // Range end
        rangeEndBuilder: (context, day, focusedDay) {
          return _dayCell(
            day,
            bgColor: AppColor.themeColor,
            textColor: Colors.white,
          );
        },

        // Days in range
        withinRangeBuilder: (context, day, focusedDay) {
          return _dayCell(
            day,
            bgColor: AppColor.themeColor.withOpacity(0.15),
            textColor: Colors.black87,
          );
        },

        // Outside-month days
        outsideBuilder: (context, day, focusedDay) {
          return _dayCell(day, bgColor: null, textColor: Colors.grey.shade400);
        },

        // Disabled days (unavailable or out of range)
        disabledBuilder: (context, day, focusedDay) {
          if (_isUnavailable(day)) {
            return _dayCell(
              day,
              bgColor: Colors.grey.shade200,
              textColor: Colors.grey.shade500,
            );
          }
          return _dayCell(day, bgColor: null, textColor: Colors.grey.shade500);
        },
      ),

      // ── Header ───────────────────────────────────────────────────────
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        headerPadding: EdgeInsets.symmetric(vertical: size.height * 0.015),
        // Hide the built-in chevrons — we draw our own inside headerTitleBuilder
        leftChevronIcon: const SizedBox.shrink(),
        rightChevronIcon: const SizedBox.shrink(),
        leftChevronMargin: EdgeInsets.zero,
        rightChevronMargin: EdgeInsets.zero,
        leftChevronPadding: EdgeInsets.zero,
        rightChevronPadding: EdgeInsets.zero,
      ),

      // ── Day-of-week row: plain dark text, no background ───────────────
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: AppFont.fontFamily,
          color: Colors.grey.shade600,
        ),
        weekendStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: AppFont.fontFamily,
          color: Colors.grey.shade600,
        ),
        // Transparent row — no colour block
        decoration: const BoxDecoration(color: Colors.transparent),
      ),

      // ── Calendar style (fallback / spacing) ───────────────────────────
      calendarStyle: const CalendarStyle(
        // All actual day rendering is handled in calendarBuilders above
        cellMargin: EdgeInsets.all(5),
        outsideDaysVisible: true,
      ),
    );
  }

  /// Shared day cell builder: circle with optional bg, border, text colour.
  Widget _dayCell(
    DateTime day, {
    Color? bgColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          // border: borderColor != null
          //     ? Border.all(color: borderColor, width: 1.5)
          //     : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: AppFont.fontFamily,
            color: textColor,
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // EXISTING HELPERS (unchanged)
  // ────────────────────────────────────────────────────────────────────────
  Widget _detailGrid(dynamic adDetails) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        _detailRow("${AppLanguage.guestsText[language]}:",
            "${adDetails['max_adult']} ${AppLanguage.adultText[language]} \u2022 ${adDetails['max_child']} ${AppLanguage.childText[language]}"),
        SizedBox(height: size.height * 0.03),
        _detailRow("${AppLanguage.roomsText[language]}:",
            "${adDetails['no_of_rooms']?.toString() ?? "0"} ${AppLanguage.roomsText[language]}"),
        SizedBox(height: size.height * 0.03),
        _detailRow("${AppLanguage.washroomsText[language]}:",
            "${adDetails['no_of_washroom']?.toString() ?? "0"} ${AppLanguage.washroomsText[language]}"),
        SizedBox(height: size.height * 0.03),
        _detailRow("${AppLanguage.hallsText[language]}:",
            "${adDetails['no_of_halls']?.toString() ?? "0"} ${AppLanguage.hallsText[language]}"),
        SizedBox(height: size.height * 0.03),
        _detailRow(AppLanguage.outdoorSeatingText[language],
            adDetails['outdoor_seating'] ?? "NA"),
        SizedBox(height: size.height * 0.03),
        _detailRow(AppLanguage.poolText[language], adDetails['pool'] ?? "NA"),
        SizedBox(height: size.height * 0.03),
        _detailRow("${AppLanguage.guardText[language]}:",
            adDetails['guard_name_english']),
        SizedBox(height: size.height * 0.03),
        _detailRow(
            AppLanguage.petFriendlyCOLONText[language],
            adDetails['pet_friendly'] == 0
                ? AppLanguage.noText[language]
                : AppLanguage.yesText[language]),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontFamily: AppFont.fontFamily,
                color: Colors.black87)),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: AppFont.fontFamily,
                color: AppColor.primaryColor)),
      ],
    );
  }

  Widget _guestCounterRow(BuildContext context, int value, int max,
      {required String label,
      required int count,
      required VoidCallback onDecrement,
      required VoidCallback onIncrement}) {
    final size = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: AppFont.fontFamily,
                color: Colors.black87)),
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: AppColor.primaryColor, width: 1),
              borderRadius: BorderRadius.circular(5)),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onDecrement,
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Image.asset(value == 0
                          ? AppImage.disableDecreamentIcon
                          : AppImage.decreamentIcon)),
                ),
                SizedBox(width: size.width * 0.04),
                Text('$count',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFont.fontFamily,
                        color: Colors.black)),
                SizedBox(width: size.width * 0.04),
                GestureDetector(
                  onTap: onIncrement,
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Image.asset(max == value
                          ? AppImage.disableIncreamentIcon
                          : AppImage.increamentIcon)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _priceRow({
    required String title,
    required String price,
  }) {
    final size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.03),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        fontFamily: AppFont.fontFamily,
                        height: 1.4)),
                SizedBox(height: size.height * 0.005),
                Text(price,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFont.fontFamily)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color? dotColor) {
    final size = MediaQuery.of(context).size;
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: AppFont.fontFamily,
                color: Colors.black87)),
        if (dotColor != null) ...[
          SizedBox(width: size.width * 0.015),
          Container(
            width: size.width * 0.035,
            height: size.width * 0.035,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ],
      ],
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

  Widget _amenitiesGrid(List<dynamic> offerings) {
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

  Widget _partDetials(dynamic adDetails) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 85 / 100,
      // color: Colors.pink,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                "${(adDetails["max_adult"] + adDetails['max_child'])}",
                style: const TextStyle(
                    color: AppColor.primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFont.fontFamily),
              ),
              Text(
                AppLanguage.memberstext[language],
                style: const TextStyle(
                    color: AppColor.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFont.fontFamily),
              )
            ],
          ),
          Container(
            color: AppColor.primaryColor,
            width: MediaQuery.of(context).size.width * 0.3 / 100,
            height: MediaQuery.of(context).size.height * 7 / 100,
          ),
          if (adDetails["rating"] != 0)
            GestureDetector(
              onTap: () {
                if (adDetails["rating"] != 0) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Review(
                                tripId: widget.propertyAdId.toString(),
                                tripImages: propertyImages,
                                isProperty: true,
                              )));
                }
              },
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 5 / 100,
                        height: MediaQuery.of(context).size.width * 5 / 100,
                        child: Image.asset(AppImage.ratingIcon),
                      ),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 1 / 100),
                      Text(
                        adDetails["rating"].toString(),
                        style: const TextStyle(
                            color: AppColor.primaryColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFont.fontFamily),
                      ),
                    ],
                  ),
                  Text(
                    AppLanguage.reviewsText[language],
                    style: const TextStyle(
                        color: AppColor.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFont.fontFamily),
                  )
                ],
              ),
            ),
          if (adDetails["rating"] != 0)
            Container(
              color: AppColor.primaryColor,
              width: MediaQuery.of(context).size.width * 0.3 / 100,
              height: MediaQuery.of(context).size.height * 7 / 100,
            ),
          Column(
            children: [
              Text(
                "${adDetails["starting_price"].toString()} KWD",
                style: const TextStyle(
                    color: AppColor.primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFont.fontFamily),
              ),
              Text(
                AppLanguage.pricehrText[language],
                style: const TextStyle(
                    color: AppColor.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFont.fontFamily),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  const FeatureItem({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor,
    this.textColor,
  });

  final String icon;
  final Color? iconColor;
  final Color? textColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Row(
      children: [
        Image.network(
          '${AppConfigProvider.imageURL}$icon',
          fit: BoxFit.cover,
          height: 20,
          loadingBuilder: (BuildContext context, Widget child,
              ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              return child;
            } else {
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  color: Colors.grey.shade300,
                ),
              );
            }
          },
        ),
        SizedBox(width: size.width * 0.02),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontFamily: AppFont.fontFamily,
              fontWeight: FontWeight.w500,
              color: textColor ?? Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
