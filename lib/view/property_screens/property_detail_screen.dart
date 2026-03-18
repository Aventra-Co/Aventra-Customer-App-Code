import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:boatapp/controller/app_color.dart';
import 'package:boatapp/controller/app_constant.dart';
import 'package:boatapp/controller/app_font.dart';
import 'package:boatapp/controller/app_header.dart';
import 'package:boatapp/controller/app_image.dart';
import 'package:boatapp/controller/app_language.dart';
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

class PropertyDetailsScreen extends StatefulWidget {
  const PropertyDetailsScreen({super.key, required this.propertyAdId});
  final int propertyAdId;

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  int currentImageIndex = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _selectedDays = {};
  int imageSelected = 0;
  int isSelected = 1;

  // ── Time slot state ───────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────

  // Unavailable dates (non-selectable, not blue)
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

  bool _isPastDate(DateTime day) {
    final today = _normalise(DateTime.now());
    return day.isBefore(today);
  }

  bool _isWeekdayAllowed(DateTime day) =>
      day.weekday == DateTime.sunday ||
      day.weekday == DateTime.monday ||
      day.weekday == DateTime.tuesday ||
      day.weekday == DateTime.wednesday;

  bool _isWeekendAllowed(DateTime day) =>
      day.weekday == DateTime.thursday ||
      day.weekday == DateTime.friday ||
      day.weekday == DateTime.saturday;

  bool _canStartFullWeek(DateTime day) {
    if (_isUnavailable(day)) {
      return false;
    }
    for (int i = 0; i < 7; i++) {
      final checkDay = _normalise(day.add(Duration(days: i)));
      if (_isUnavailable(checkDay)) {
        return false;
      }
    }
    return true;
  }

  bool _isSelectableDate(DateTime day) {
    if (_isPastDate(day)) {
      return false;
    }
    if (_isUnavailable(day)) {
      return false;
    }
    if (isSelected == 2) {
      return _isWeekdayAllowed(day);
    }
    if (isSelected == 3) {
      return _isWeekendAllowed(day);
    }
    if (isSelected == 4) {
      return _canStartFullWeek(day);
    }
    return true;
  }

  bool _isSelectedDay(DateTime day) =>
      _selectedDays.any((d) => isSameDay(d, day));

  Set<DateTime> _buildFullWeekRange(DateTime start) {
    return List.generate(
      7,
      (index) => _normalise(start.add(Duration(days: index))),
    ).toSet();
  }

  void _logSelectedDays(String source) {
    final formattedDays = _selectedDays
        .map((d) => DateFormat('yyyy-MM-dd').format(d))
        .toList()
      ..sort();
    debugPrint("PropertyDetails _selectedDays ($source): $formattedDays");
  }

  void _setInitialSelectionForMode() {
    final today = _normalise(DateTime.now());
    if (!_isSelectableDate(today)) {
      _selectedDay = null;
      _selectedDays = {};
      _logSelectedDays("setInitialSelectionForMode");
      return;
    }

    if (isSelected == 4) {
      if (_canStartFullWeek(today)) {
        _selectedDay = today;
        _selectedDays = _buildFullWeekRange(today);
      } else {
        _selectedDay = null;
        _selectedDays = {};
      }
      _logSelectedDays("setInitialSelectionForMode");
      return;
    }

    _selectedDay = today;
    _selectedDays = {today};
    _logSelectedDays("setInitialSelectionForMode");
  }

  void _updateSelectionMode(int mode) {
    setState(() {
      isSelected = mode;
      _setInitialSelectionForMode();
    });
  }

  dynamic adDetails = {};
  String allActivity = "";
  bool isApiCalling = true;
  int selectedImageInd = 0;
  String showFormattedDates = '';
  List<dynamic> tripImages = [];
  List<dynamic> offerings = [];
  dynamic userDetails;
  int userId = 0;

  @override
  void initState() {
    super.initState();
    _setInitialSelectionForMode();
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
          if (adDetails is Map && adDetails['unavailable_dates'] != null) {
            _unavailableDates =
                _buildUnavailableDates(adDetails['unavailable_dates']);
            final hasInvalidSelection =
                _selectedDays.any((d) => !_isSelectableDate(d));
            if (hasInvalidSelection || _selectedDays.isEmpty) {
              _setInitialSelectionForMode();
            }
          }
          isSelected = adDetails['one_day_active'] == 1
              ? 1
              : adDetails['weekday_active'] == 1
                  ? 2
                  : adDetails['weekend_active'] == 1
                      ? 3
                      : adDetails['full_week_active'] == 1
                          ? 4
                          : 0;
          if (adDetails['property_images'] != "NA") {
            tripImages.addAll(adDetails['property_images']);
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
    final double sh = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
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
                        if (tripImages.isNotEmpty)
                          tripImages.isNotEmpty
                              ? Container(
                                  color: AppColor.creamColor,
                                  width: MediaQuery.of(context).size.width *
                                      100 /
                                      100,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                90 /
                                                100,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                25 /
                                                100,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          image: DecorationImage(
                                              image: tripImages[imageSelected]
                                                          ['image_path'] !=
                                                      null
                                                  ? NetworkImage(
                                                      "${AppConfigProvider.imageURL}${tripImages[imageSelected]['image_path']}")
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
                                        width:
                                            MediaQuery.of(context).size.width *
                                                100 /
                                                100,
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              100 /
                                              100,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              children: List.generate(
                                                  tripImages.length, (index) {
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
                                                                  tripImages
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
                                                                  tripImages
                                                                          .length -
                                                                      1
                                                              ? 0
                                                              : 0),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        imageSelected = index;
                                                      });
                                                    },
                                                    child: Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              18 /
                                                              100,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              18 /
                                                              100,
                                                      decoration: BoxDecoration(
                                                          image: DecorationImage(
                                                              image: tripImages[
                                                                              index]
                                                                          [
                                                                          'image_path'] !=
                                                                      null
                                                                  ? NetworkImage(
                                                                      "${AppConfigProvider.imageURL}${tripImages[index]['image_path']}")
                                                                  : const AssetImage(
                                                                          AppImage
                                                                              .imageFrameImage)
                                                                      as ImageProvider,
                                                              fit:
                                                                  BoxFit.cover),
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
                            height:
                                MediaQuery.of(context).size.height * 2 / 100),

                        _partDetials(adDetails),

                        SizedBox(height: sh * 0.02),

                        SizedBox(
                          width: MediaQuery.of(context).size.width * 90 / 100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        75 /
                                        100,
                                    child: Text(
                                      adDetails['property_name_english'] ?? "",
                                      style: const TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: AppFont.fontFamily,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {},
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          8 /
                                          100,
                                      height:
                                          MediaQuery.of(context).size.width *
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
                                adDetails['property_type_name'][language] ?? "",
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
                                    width: MediaQuery.of(context).size.width *
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

                              // Description
                              Text(
                                AppLanguage.descriptionText[language],
                                style: const TextStyle(
                                  fontSize: 21,
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
                                  language == 0
                                      ? (((adDetails['description_english'] ??
                                                  '')
                                              .toString()
                                              .trim()
                                              .isEmpty)
                                          ? "NA"
                                          : adDetails['description_english'])
                                      : (((adDetails['description_arabic'] ??
                                                  '')
                                              .toString()
                                              .trim()
                                              .isEmpty)
                                          ? "N/A"
                                          : adDetails['description_arabic']),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: AppFont.fontFamily,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              SizedBox(height: size.height * 0.03),

                              // What this place offers
                              Text(
                                AppLanguage.whatThisplaceOfferText[language],
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

                              // Price
                              Text(
                                AppLanguage.priceText[language],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: AppFont.fontFamily,
                                ),
                              ),
                              SizedBox(height: size.height * 0.03),

                              //! One Day Pricing
                              if (adDetails['one_day_price'] > 0) ...[
                                GestureDetector(
                                  onTap: () => _updateSelectionMode(1),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                        bottom: size.height * 0.03),
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
                                                  color: AppColor.themeColor,
                                                  width: 2)),
                                          child: isSelected == 1
                                              ? Center(
                                                  child: Container(
                                                    width: size.width * 0.025,
                                                    height: size.width * 0.025,
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
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    90 /
                                                    100,
                                                color: AppColor.white,
                                                child: Text(
                                                    AppLanguage
                                                        .oneDayText[language],
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontFamily:
                                                            AppFont.fontFamily,
                                                        height: 1.4)),
                                              ),
                                              SizedBox(
                                                  height: size.height * 0.005),
                                              Text(
                                                  "${adDetails['one_day_price']?.toString() ?? "0"} KWD",
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontFamily:
                                                          AppFont.fontFamily)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              //! Week Day Pricing
                              if (adDetails['weekday_price'] > 0) ...[
                                GestureDetector(
                                  onTap: () => _updateSelectionMode(2),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                        bottom: size.height * 0.03),
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
                                                  color: AppColor.themeColor,
                                                  width: 2)),
                                          child: isSelected == 2
                                              ? Center(
                                                  child: Container(
                                                    width: size.width * 0.025,
                                                    height: size.width * 0.025,
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
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    90 /
                                                    100,
                                                color: AppColor.white,
                                                child: Text(
                                                    AppLanguage
                                                        .weekDaysText[language],
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontFamily:
                                                            AppFont.fontFamily,
                                                        height: 1.4)),
                                              ),
                                              SizedBox(
                                                  height: size.height * 0.005),
                                              Text(
                                                  "${adDetails['weekday_price']?.toString() ?? "0"} KWD",
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontFamily:
                                                          AppFont.fontFamily)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              //! Weekend Day Pricing
                              if (adDetails['weekend_price'] > 0) ...[
                                GestureDetector(
                                  onTap: () => _updateSelectionMode(3),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                        bottom: size.height * 0.03),
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
                                                  color: AppColor.themeColor,
                                                  width: 2)),
                                          child: isSelected == 3
                                              ? Center(
                                                  child: Container(
                                                    width: size.width * 0.025,
                                                    height: size.width * 0.025,
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
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    90 /
                                                    100,
                                                color: AppColor.white,
                                                child: Text(
                                                    AppLanguage.weekendDaysText[
                                                        language],
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontFamily:
                                                            AppFont.fontFamily,
                                                        height: 1.4)),
                                              ),
                                              SizedBox(
                                                  height: size.height * 0.005),
                                              Text(
                                                  "${adDetails['weekend_price']?.toString() ?? "0"} KWD",
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontFamily:
                                                          AppFont.fontFamily)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              //! Full Week Pricing
                              if (adDetails['full_week_price'] > 0) ...[
                                GestureDetector(
                                  onTap: () => _updateSelectionMode(4),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                        bottom: size.height * 0.03),
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
                                                  color: AppColor.themeColor,
                                                  width: 2)),
                                          child: isSelected == 4
                                              ? Center(
                                                  child: Container(
                                                    width: size.width * 0.025,
                                                    height: size.width * 0.025,
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
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    90 /
                                                    100,
                                                color: AppColor.white,
                                                child: Text(
                                                    AppLanguage
                                                            .fullWeekDaysText[
                                                        language],
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontFamily:
                                                            AppFont.fontFamily,
                                                        height: 1.4)),
                                              ),
                                              SizedBox(
                                                  height: size.height * 0.005),
                                              Text(
                                                  "${adDetails['full_week_price']?.toString() ?? "0"} KWD",
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontFamily:
                                                          AppFont.fontFamily)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
                                      AppLanguage.bookNowText[language], null),
                                  SizedBox(width: size.width * 0.08),
                                  _legendItem(
                                      'Availability', const Color(0xFF009FE3)),
                                  _legendItem('Selected', AppColor.themeColor),
                                ],
                              ),
                              SizedBox(height: size.height * 0.02),

                              // ── CALENDAR (Figma style) ───────────────────────────
                              _buildCalendar(size),

                              SizedBox(height: size.height * 0.03),

                              // ── TIME SLOT PICKER ────────────────────────────────

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

                              _guestCounterRow(
                                  context, adultCount, adDetails['max_adult'],
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
                                  color: Colors.grey.shade200,
                                  height: size.height * 0.04),

                              _guestCounterRow(
                                  context, childCount, adDetails['max_child'],
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
                                        _selectedDay == null) {
                                      SnackBarToastMessage.showSnackBar(context,
                                          AppLanguage.selectDateMsg[language]);
                                      return;
                                    }
                                    if (adultCount == 0 && childCount == 0) {
                                      SnackBarToastMessage.showSnackBar(
                                          context,
                                          AppLanguage
                                              .numberOfGuestMsg[language]);
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PropertyBookingDetails(
                                          adDetails: adDetails,
                                          adultCount: adultCount,
                                          childCount: childCount,
                                          priceType: isSelected,
                                          selectedDays: _selectedDays,
                                          propertyAdId: widget.propertyAdId,
                                          perDayPrice: isSelected == 1
                                              ? adDetails['one_day_price']
                                                  .toString()
                                              : isSelected == 2
                                                  ? adDetails['weekday_price']
                                                      .toString()
                                                  : isSelected == 3
                                                      ? adDetails[
                                                              'weekend_price']
                                                          .toString()
                                                      : adDetails[
                                                              'full_week_price']
                                                          .toString(),
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
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      availableGestures: AvailableGestures.none,
      selectedDayPredicate: (day) => _isSelectedDay(day),
      enabledDayPredicate: (day) => _isSelectableDate(day),
      onDaySelected: (selectedDay, focusedDay) {
        final normalisedDay = _normalise(selectedDay);
        if (!_isSelectableDate(normalisedDay)) {
          return;
        }
        setState(() {
          _focusedDay = focusedDay;
          if (isSelected == 1) {
            _selectedDay = normalisedDay;
            _selectedDays = {normalisedDay};
          } else if (isSelected == 2 || isSelected == 3) {
            final alreadySelected =
                _selectedDays.any((d) => isSameDay(d, normalisedDay));
            if (alreadySelected) {
              _selectedDays.removeWhere((d) => isSameDay(d, normalisedDay));
            } else {
              _selectedDays.add(normalisedDay);
            }
            _selectedDay = normalisedDay;
          } else if (isSelected == 4) {
            if (_canStartFullWeek(normalisedDay)) {
              _selectedDay = normalisedDay;
              _selectedDays = _buildFullWeekRange(normalisedDay);
            }
          }
          _logSelectedDays("onDaySelected");
        });
      },
      onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
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
                    _focusedDay =
                        DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
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
                    _focusedDay =
                        DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                  }),
                  child: const Icon(Icons.chevron_right,
                      color: AppColor.primaryColor, size: 22),
                ),
              ],
            ),
          );
        },

        // Default day cell
        defaultBuilder: (context, day, focusedDay) {
          if (_isSelectableDate(day)) {
            return _dayCell(
              day,
              bgColor: const Color(0xFF009FE3),
              textColor: Colors.white,
            );
          }
          return _dayCell(day, bgColor: null, textColor: Colors.black87);
        },

        // Today (unselected)
        todayBuilder: (context, day, focusedDay) {
          return _dayCell(
            day,
            bgColor: AppColor.themeColor.withOpacity(0.15),
            textColor: Colors.black87,
            borderColor: AppColor.themeColor,
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

        // Outside-month days
        outsideBuilder: (context, day, focusedDay) {
          return _dayCell(day, bgColor: null, textColor: Colors.grey.shade400);
        },

        // Disabled days (unavailable or not allowed by mode)
        disabledBuilder: (context, day, focusedDay) {
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
        _detailRow(
            AppLanguage.guardText[language], adDetails['guard_name_english']),
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

  Widget _priceOption({
    required String title,
    required String price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: size.height * 0.03),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: size.width * 0.05,
              height: size.width * 0.05,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.themeColor, width: 2)),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: size.width * 0.025,
                        height: size.width * 0.025,
                        decoration: const BoxDecoration(
                            color: AppColor.themeColor, shape: BoxShape.circle),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: size.width * 0.04),
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
                                tripImages: tripImages,
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
