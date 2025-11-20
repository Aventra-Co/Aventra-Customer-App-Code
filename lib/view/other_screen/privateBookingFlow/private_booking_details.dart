import 'dart:convert';
import 'dart:developer';
import 'package:boatapp/view/other_screen/success_payment_screen.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../controller/app_config_provider.dart';
import '../../../controller/app_loader.dart';
import '../../../controller/app_snack_bar_toast_message.dart';
import '../../authentication/login_screen.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../controller/app_button.dart';
import '../../../controller/app_color.dart';
import '../../../controller/app_constant.dart';
import '../../../controller/app_font.dart';
import '../../../controller/app_header.dart';
import '../../../controller/app_image.dart';
import '../../../controller/app_language.dart';
import 'dart:ui' as ui;
import '../boat_details.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PrivateBookingDetails extends StatefulWidget {
  static String routeName = './PrivateBookingDetails';
  final dynamic tripDetails;
  final String date;
  final String time;
  final String allTimeSlots;
  final List<dynamic> selectedAddons;
  final List<dynamic> sendAddons;
  final String showDate;
  final String selectedSlotId;
  final String sendSelectedTime;
  final String sendTicketsCount;
  final String sendSlotIds;
  const PrivateBookingDetails(
      {super.key,
      required this.tripDetails,
      required this.date,
      required this.time,
      required this.selectedAddons,
      required this.sendAddons,
      required this.showDate,
      required this.selectedSlotId,
      required this.sendSelectedTime,
      required this.sendTicketsCount,
      required this.sendSlotIds,
      required this.allTimeSlots});

  @override
  State<PrivateBookingDetails> createState() => PrivateBookingDetailsState();
}

class PrivateBookingDetailsState extends State<PrivateBookingDetails> {
  TextEditingController couponController = TextEditingController();
  bool isApiCalling = false;
  double longitudex = 77.4126;
  double latitudex = 23.2599;
  GoogleMapController? mapController;
  LatLng initialPosition = const LatLng(23.2599, 77.4126);
  List<dynamic> selectedAddons = [];
  List<dynamic> timeSlots = <dynamic>[];
  List<int> selectedSlotIds = <int>[];
  List<String> availableDates = <String>[];
  List<String> selectedTimesShow = <String>[];
  List<dynamic> finalAddons = [];
  DateTime today = DateTime.now();
  String markedDatesString = "";
  String selectedDate = "";
  String showSelectedDate = "";
  String selectedTime = "";
  String sendSelectedTime = "";
  bool showSlots = false;
  double finalAddonsPrice = 0;
  late final Set<DateTime> markedDates;
  String selectedSlotId = "";
  double greatGrandTotal = 0;
  double totalHoursPrice = 0;
  int userId = 0;
  dynamic userDetails;
  dynamic tripDetails = {};
  int mainIndex = 0;
  String grandTotal = "0";
  bool isCouponDiscount = false;
  bool isDiscountApplied = false;
  int couponDiscount = 0;
  int discount = 0;
  String couponCode = '';
  String email = '';
  int? selectedMethod;
  String fullName = '';

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
    today = DateTime.parse(widget.date);
    log("asfafasfd$today and ${widget.date}");
    print("userDetails $userDetails");
    if (userDetails != null) {
      dynamic data = json.decode(userDetails);
      userId = data['user_id'];
      email = data['email'] ?? "";
      fullName = data['name'] ?? "";
      tripDetails = widget.tripDetails;
      print("tripDetails $tripDetails");
      latitudex = double.parse(tripDetails['latitude']);
      longitudex = double.parse(tripDetails['longitude']);
      initialPosition = LatLng(latitudex, longitudex);
      selectedAddons = widget.selectedAddons;
      selectedSlotId = widget.selectedSlotId;
      selectedTime = widget.time;
      discount = tripDetails['discount'];
      couponDiscount = tripDetails['coupon_discount'];
      sendSelectedTime = widget.sendSelectedTime;
      showSelectedDate = widget.showDate;
      log("showSelectedDate$showSelectedDate");
      timeSlots = (tripDetails['slot'] != "NA") ? tripDetails['slot'] : [];
      markedDatesString = tripDetails['dates'];
      availableDates = markedDatesString.split(",");
      selectedSlotIds = widget.sendSlotIds.isNotEmpty
          ? widget.sendSlotIds.split(",").map((e) => int.parse(e)).toList()
          : [];
      selectedTimesShow = widget.allTimeSlots.isNotEmpty
          ? widget.allTimeSlots.split(", ").map((e) => e).toList()
          : [];
      fillDates();
      finalAddonsCal();
      setState(() {
        isApiCalling = false;
      });
      log("availbledates$availableDates");
      getAvailableSlotsApi(userId, tripDetails['boat_id'], widget.date);
      markedDates = markedDatesString
          .split(',')
          .map((dateStr) => DateTime.parse(dateStr.trim()))
          .toSet();
    }

    log("$selectedAddons");
    setState(() {
      isApiCalling = false;
    });
    setState(() {});
  }

  //=============================GET Trips DETAILS===================================//
  Future<void> getAvailableSlotsApi(userId, boatId, date) async {
    print("Line155");
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_available_slot_status?trip_id=${tripDetails['trip_id']}&user_id=$userId&boat_id=$boatId&date=$date");
    print("url $url");

    String token = AppConstant.token;

    if (token.isEmpty) {
      print("Token is missing!");
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
          var item = res['slots'];
          timeSlots = (item != "NA") ? item : [];
          if (timeSlots.isEmpty) {
            // SnackBarToastMessage.showSnackBar(
            //     context, AppLanguage.boatTimingNotAvailableText[language]);
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

  fillDates() {
    log("working");
    if (tripDetails['trip_date'] == 0) {
      selectedDate = widget.date;
      showSelectedDate = widget.showDate;
    } else if (tripDetails['trip_date'] == 1) {
      final DateTime selected = DateTime.parse(widget.date);
      if (availableDates
          .map((e) => e.trim())
          .contains(DateFormat('yyyy-MM-dd').format(selected))) {
        log('inserted');
        setState(() {
          selectedDate = widget.date;
          showSelectedDate = widget.showDate;
          log("showSelectedDate$showSelectedDate");
        });
      } else {
        log('deleted');
        setState(() {
          selectedDate = '';
          showSelectedDate = '';
        });
      }
    } else if (tripDetails['trip_date'] == 2) {
      setState(() {
        final DateTime selected = DateTime.parse(widget.date);

        final int dayOfWeek = selected.weekday;
        log("weekday: $dayOfWeek");
        bool isValidDate =
            (dayOfWeek == DateTime.friday || dayOfWeek == DateTime.saturday);
        log("Selected day is ${isValidDate ? '' : 'not '}valid (Friday or Saturday)");

        if (isValidDate) {
          selectedDate = widget.date;
          showSelectedDate = widget.showDate;
        } else {
          selectedDate = '';
          showSelectedDate = '';
        }
      });
    }
    log('filladfasd$showSelectedDate');
  }

//======================date time validation==========
  dateTimeValidation() {
    // int tickets = enteredTickets.isEmpty ? 0 : int.parse(enteredTickets);
    if (selectedDate.isEmpty || selectedSlotIds.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.selectDateTimeMsg[language]);
      return;
    } else {
      paymentMethodBottomSheet(context);
    }
  }

  void deleteSubAddOn(int addOnId, int subAddOnId) {
    int addonIndex =
        selectedAddons.indexWhere((addon) => addon['addon_id'] == addOnId);

    if (addonIndex != -1) {
      List<dynamic> subAddons = selectedAddons[addonIndex]['subAddons'];

      // Remove sub-addon by subAddOnId
      subAddons.removeWhere((sub) => sub['subAddOnId'] == subAddOnId);

      // If no subAddons left, remove the entire addon
      if (subAddons.isEmpty) {
        selectedAddons.removeAt(addonIndex);
      } else {
        selectedAddons[addonIndex]['subAddons'] = subAddons;
      }
    }
    finalAddonsCal();
    setState(() {});
  }

  finalAddonsCal() {
    finalAddons.clear();
    finalAddonsPrice = 0;
    for (var entry in selectedAddons) {
      double total = 0;
      if (entry['subAddons'].isNotEmpty) {
        for (var subEntry in entry['subAddons']) {
          total += subEntry['quantity'] * subEntry["price"];
        }
        finalAddons.add({
          "addOnName": entry['addon_name'],
          "amount": total,
        });
        finalAddonsPrice += total;
      }
    }
    if (discount > 0) {
      totalHoursPrice =
          ((tripDetails['minimum_hours'] * selectedTimesShow.length) *
              double.parse(tripDetails['price_per_hour']));
      totalHoursPrice =
          (totalHoursPrice - (totalHoursPrice * (discount / 100)));
      // totalHoursPrice = totalHoursPrice.roundToDouble();
      log("totalHoursPrice328$totalHoursPrice");
    } else {
      totalHoursPrice =
          ((tripDetails['minimum_hours'] * selectedTimesShow.length) *
              double.parse(tripDetails['price_per_hour']));
      log("totalHoursPrice$totalHoursPrice");
    }
    greatGrandTotal = finalAddonsPrice + totalHoursPrice;
    // greatGrandTotal = greatGrandTotal.roundToDouble();
    setState(() {});
    log("greatGrandTotal$greatGrandTotal");
    log("finalAddons$finalAddons");
    log("converted${convert()}");
  }

  couponApplied() {
    if (isCouponDiscount) {
      setState(() {
        totalHoursPrice =
            ((tripDetails['minimum_hours'] * selectedTimesShow.length) *
                double.parse(tripDetails['price_per_hour']));
        log("totalHoursPrice351 $totalHoursPrice");
        totalHoursPrice =
            (totalHoursPrice - (totalHoursPrice * (couponDiscount / 100)));
        log("totalHoursPrice354 $totalHoursPrice");
        // totalHoursPrice = totalHoursPrice.roundToDouble();
        log("totalHoursPrice356 $totalHoursPrice");
        log("totalHoursPrice$totalHoursPrice");
        isDiscountApplied = true;
        couponCode = couponController.text.toUpperCase();
      });
    } else {
      return;
    }
    setState(() {
      greatGrandTotal = finalAddonsPrice + totalHoursPrice;
      log("greatGrandTotalWithoutRoundOf$greatGrandTotal");
      // greatGrandTotal = greatGrandTotal.roundToDouble();
      log("greatGrandTotal$greatGrandTotal");
    });
  }

  List<dynamic> convert() {
    List<dynamic> result = [];
    for (var entry in selectedAddons) {
      if (entry['subAddons'].isNotEmpty) {
        for (var subEntry in entry['subAddons']) {
          result.add(
            {
              "addon_id": entry['addon_id'],
              "sub_addon_id": subEntry['subAddOnId'],
              "quantity": subEntry['quantity'],
              "price": subEntry['price']
            },
          );
        }
      }
    }
    return result;
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
        'amount': greatGrandTotal.toString(),
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

      if (response.statusCode == 200) {
        // if (res['success'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessPaymentScreen(
                webUrl: res['bookeeyResponse']['PayUrl'],
                userId: userId.toString(),
                tripId: tripDetails['trip_id'].toString(),
                bookingDate: selectedDate.toString(),
                hours: tripDetails['minimum_hours'].toString(),
                bookingTime: sendSelectedTime,
                grandTotal: greatGrandTotal.toString(),
                addonArr: jsonEncode(convert()),
                addonTotalAmount: finalAddonsPrice.toString(),
                captainFees: "0",
                couponCode: couponCode,
                discount: discount.toString(),
                couponDiscount: couponDiscount.toString(),
                hoursPrice: (double.parse(tripDetails['price_per_hour']) *
                        tripDetails['minimum_hours'])
                    .toString(),
                sendTicketsCount: widget.sendTicketsCount,
                sendSlotIds: selectedSlotIds.join(',')),
          ),
        );
        // } else {
        //   SnackBarToastMessage.showSnackBar(context, res['message'][language]);
        //   if (res['active_flag'] == 0) {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(builder: (context) => const Login()),
        //     );
        //   }
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

  //!=============================Coupon API===================================//
  Future<void> checkCouponApi(userId, couponCode, tripId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}check_coupon_discount?user_id=$userId&coupon_code=$couponCode&trip_id=$tripId");
    print("url $url");

    String token = AppConstant.token;

    if (token.isEmpty) {
      print("Token is missing!");
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
          couponDiscount = res['discount'];
          isCouponDiscount = true;
          couponApplied();
          couponController.clear();
          setState(() {
            isApiCalling = false;
          });
        } else {
          couponCode = "";
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          if (res['active_status'] == 0) {
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
        couponCode = "";
        print("Error: ${response.statusCode}");
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (e) {
      couponCode = "";
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColor.secondaryColor,
        statusBarIconBrightness: Brightness.dark));
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Directionality(
            textDirection:
                language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            child: Container(
              color: AppColor.secondaryColor,
              width: MediaQuery.of(context).size.width * 100 / 100,
              height: MediaQuery.of(context).size.height * 100 / 100,
              child: Column(
                children: [
                  const NoInternetBanner(),
                  AppHeader(
                      text: AppLanguage.bookingDetailsText[language],
                      onPress: () {
                        Navigator.pop(context);
                      }),
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          //! boat details
                          Container(
                            color: AppColor.creamColor.withOpacity(0.4),
                            width:
                                MediaQuery.of(context).size.width * 100 / 100,
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 25),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            tripDetails['boat_name_english'] ??
                                                "",
                                            style: const TextStyle(
                                                color: AppColor.primaryColor,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                fontFamily:
                                                    AppFont.fontFamily)),
                                        Row(
                                          children: [
                                            Text(
                                                tripDetails['boat_brand'] ?? "",
                                                style: const TextStyle(
                                                    color: AppColor.grayColor,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w400,
                                                    fontFamily:
                                                        AppFont.fontFamily)),
                                            SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    1 /
                                                    100),
                                            // Container(
                                            //   width: MediaQuery.of(context).size.width *
                                            //       1 /
                                            //       100,
                                            //   height: MediaQuery.of(context).size.width *
                                            //       1 /
                                            //       100,
                                            //   decoration: BoxDecoration(
                                            //       color: AppColor.grayColor,
                                            //       shape: BoxShape.circle),
                                            // ),
                                            SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    1 /
                                                    100),
                                          ],
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => BoatDetailsScreen(
                                                  boatName: tripDetails[
                                                          'boat_name_english'] ??
                                                      "",
                                                  boatBrand: tripDetails[
                                                          'boat_brand'] ??
                                                      "",
                                                  toilet: tripDetails['toilet']
                                                      .toString(),
                                                  cabins: tripDetails['cabins']
                                                      .toString(),
                                                  capacity:
                                                      tripDetails['boat_capacity']
                                                          .toString(),
                                                  size: tripDetails['boat_size']
                                                      .toString(),
                                                  year: tripDetails['boat_year']
                                                      .toString(),
                                                  registration: tripDetails[
                                                          'boat_registration_number']
                                                      .toString())),
                                        );
                                      },
                                      child: Text(
                                        AppLanguage.viewDetailsText[language],
                                        style: const TextStyle(
                                            color: AppColor.themeColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: AppFont.fontFamily,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                AppColor.themeColor),
                                      ),
                                    ),
                                    // Container(
                                    //   width: MediaQuery.of(context).size.width * 18 / 100,
                                    //   height:
                                    //       MediaQuery.of(context).size.width * 18 / 100,
                                    //   decoration: BoxDecoration(
                                    //       image: DecorationImage(
                                    //           image: AssetImage(
                                    //             './assets/icons/ship_image1.png',
                                    //           ),
                                    //           fit: BoxFit.cover),
                                    //       borderRadius: BorderRadius.circular(16)),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 1 / 100),

                          //! location & nap
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 90 / 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLanguage.destinationText[language],
                                  style: const TextStyle(
                                    color: AppColor.textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: AppFont.fontFamily,
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  child: Text(
                                    tripDetails['destination'][language] ?? "",
                                    style: const TextStyle(
                                      color: AppColor.primaryColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFont.fontFamily,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: screenHeight * 1.5 / 100,
                                ),
                                Text(
                                  AppLanguage.locationAddressText[language],
                                  style: const TextStyle(
                                    color: AppColor.textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: AppFont.fontFamily,
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  child: Text(
                                    tripDetails['pickup_point'] ?? "",
                                    style: const TextStyle(
                                      color: AppColor.primaryColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFont.fontFamily,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        2 /
                                        100),
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
                              ],
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 3 / 100),

                          //! Booking Details
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 90 / 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //booking details
                                Text(
                                  AppLanguage.bookingDetailsText[language],
                                  style: const TextStyle(
                                    color: AppColor.primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: AppFont.fontFamily,
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        2 /
                                        100),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          9 /
                                          100,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              9 /
                                              100,
                                      child:
                                          Image.asset(AppImage.callenderIcon),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          65 /
                                          100,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (showSelectedDate.isNotEmpty)
                                            Text(
                                              "$showSelectedDate at ${selectedTimesShow.join(', ')}",
                                              style: const TextStyle(
                                                color: AppColor.primaryColor,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: AppFont.fontFamily,
                                              ),
                                            ),
                                          Text(
                                            AppLanguage
                                                .bookingDateText[language],
                                            style: const TextStyle(
                                              color: AppColor.textColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: AppFont.fontFamily,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        changeDateTimeBottomSheet(
                                            context, screenWidth);
                                      },
                                      child: Text(
                                        AppLanguage.changeText[language],
                                        style: const TextStyle(
                                            color: AppColor.primaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: AppFont.fontFamily,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                AppColor.primaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        2 /
                                        100),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          9 /
                                          100,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              9 /
                                              100,
                                      child: Image.asset(AppImage.clockIcon),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          65 /
                                          100,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${(tripDetails['minimum_hours'] * selectedSlotIds.length)} hours",
                                            style: const TextStyle(
                                              color: AppColor.primaryColor,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: AppFont.fontFamily,
                                            ),
                                          ),
                                          Text(
                                            AppLanguage
                                                .bookingHoursText[language],
                                            style: const TextStyle(
                                              color: AppColor.textColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: AppFont.fontFamily,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      AppLanguage.changeText[language],
                                      style: const TextStyle(
                                          color: AppColor.secondaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: AppFont.fontFamily,
                                          decoration: TextDecoration.underline,
                                          decorationColor:
                                              AppColor.secondaryColor),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100),

                                //addons
                                if (selectedAddons.isNotEmpty)
                                  Column(
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                90 /
                                                100,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLanguage.addonsText[language],
                                              style: const TextStyle(
                                                color: AppColor.primaryColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: AppFont.fontFamily,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              1 /
                                              100),
                                    ],
                                  ),

                                //addons list
                                Wrap(
                                  children: List.generate(
                                    selectedAddons.length,
                                    (index) {
                                      return Column(
                                        children: [
                                          if (widget
                                              .selectedAddons[index]
                                                  ['subAddons']
                                              .isNotEmpty)
                                            Container(
                                              alignment: Alignment.centerLeft,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  90 /
                                                  100,
                                              child: Text(
                                                "${selectedAddons[index]['addon_name']} (${selectedAddons[index]['subAddons'].length})",
                                                style: const TextStyle(
                                                  color: AppColor.grayColor,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                ),
                                              ),
                                            ),
                                          SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  1 /
                                                  100),
                                          if (widget
                                              .selectedAddons[index]
                                                  ['subAddons']
                                              .isNotEmpty)
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  100 /
                                                  100,
                                              child: SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Wrap(
                                                  spacing: 15.0,
                                                  children: List.generate(
                                                      widget
                                                          .selectedAddons[index]
                                                              ['subAddons']
                                                          .length, (subIndex) {
                                                    return Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 7,
                                                          horizontal: 7),
                                                      decoration: BoxDecoration(
                                                          border: Border.all(
                                                              color: AppColor
                                                                  .grayColor),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8)),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                12 /
                                                                100,
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                12 /
                                                                100,
                                                            decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12)),
                                                            child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              child: selectedAddons[index]['subAddons']
                                                                              [
                                                                              subIndex]
                                                                          [
                                                                          'image'] !=
                                                                      null
                                                                  ? Image
                                                                      .network(
                                                                      '${AppConfigProvider.imageURL}${selectedAddons[index]['subAddons'][subIndex]['image']}',
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      loadingBuilder: (BuildContext context,
                                                                          Widget
                                                                              child,
                                                                          ImageChunkEvent?
                                                                              loadingProgress) {
                                                                        if (loadingProgress ==
                                                                            null) {
                                                                          return child;
                                                                        } else {
                                                                          return Shimmer
                                                                              .fromColors(
                                                                            baseColor:
                                                                                Colors.grey.shade300,
                                                                            highlightColor:
                                                                                Colors.grey.shade100,
                                                                            child:
                                                                                Container(
                                                                              color: Colors.grey.shade300,
                                                                            ),
                                                                          );
                                                                        }
                                                                      },
                                                                    )
                                                                  : Image.asset(
                                                                      AppImage
                                                                          .imageFrameImage),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  1 /
                                                                  100),
                                                          SizedBox(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                35 /
                                                                100,
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  selectedAddons[index]
                                                                              [
                                                                              'subAddons']
                                                                          [
                                                                          subIndex]
                                                                      [
                                                                      'subAddon_name'],
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style:
                                                                      const TextStyle(
                                                                    color: AppColor
                                                                        .primaryColor,
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontFamily:
                                                                        AppFont
                                                                            .fontFamily,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  "${selectedAddons[index]['subAddons'][subIndex]['price'].toStringAsFixed(2)} KWD",
                                                                  style:
                                                                      const TextStyle(
                                                                    color: AppColor
                                                                        .themeColor,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontFamily:
                                                                        AppFont
                                                                            .fontFamily,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  1 /
                                                                  100),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .end,
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    vertical: 2,
                                                                    horizontal:
                                                                        4),
                                                                decoration: BoxDecoration(
                                                                    color: AppColor
                                                                        .themeColor
                                                                        .withOpacity(
                                                                            0.2),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            4)),
                                                                child: Text(
                                                                  AppLanguage.qtyText[
                                                                          language] +
                                                                      widget
                                                                          .selectedAddons[
                                                                              index]
                                                                              [
                                                                              'subAddons']
                                                                              [
                                                                              subIndex]
                                                                              [
                                                                              'quantity']
                                                                          .toString(),
                                                                  style:
                                                                      const TextStyle(
                                                                    color: AppColor
                                                                        .themeColor,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontFamily:
                                                                        AppFont
                                                                            .fontFamily,
                                                                  ),
                                                                ),
                                                              ),
                                                              GestureDetector(
                                                                onTap: () {
                                                                  deleteSubAddOn(
                                                                      selectedAddons[
                                                                              index]
                                                                          [
                                                                          'addon_id'],
                                                                      selectedAddons[
                                                                              index]['subAddons'][subIndex]
                                                                          [
                                                                          'subAddOnId']);
                                                                },
                                                                child: SizedBox(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      5 /
                                                                      100,
                                                                  height: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      5 /
                                                                      100,
                                                                  child: Image.asset(
                                                                      AppImage
                                                                          .deleteAccountIcon),
                                                                ),
                                                              )
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    );
                                                  }),
                                                ),
                                              ),
                                            ),
                                          SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  1 /
                                                  100),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 1 / 100),

                          //! total billing
                          Container(
                            color: AppColor.themeColor.withOpacity(0.1),
                            width:
                                MediaQuery.of(context).size.width * 100 / 100,
                            padding: EdgeInsets.symmetric(
                                vertical: MediaQuery.of(context).size.height *
                                    2 /
                                    100,
                                horizontal: MediaQuery.of(context).size.width *
                                    5 /
                                    100),
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
                                    height: MediaQuery.of(context).size.height *
                                        2 /
                                        100),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${(tripDetails['minimum_hours'] * selectedSlotIds.length)} hours",
                                          style: const TextStyle(
                                              color: AppColor.primaryColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: AppFont.fontFamily),
                                        ),
                                        Text(
                                          "${AppLanguage.priceText[language]}${tripDetails['price_per_hour']} KWD/Hr",
                                          style: const TextStyle(
                                              color: AppColor.themeColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: AppFont.fontFamily),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "$totalHoursPrice KWD",
                                          style: const TextStyle(
                                              color: AppColor.primaryColor,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: AppFont.fontFamily),
                                        ),
                                        if (discount > 0)
                                          Text(
                                            "+${AppLanguage.withText[language]} $discount% ${AppLanguage.discountText[language]}",
                                            style: const TextStyle(
                                                color: AppColor.primaryColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: AppFont.fontFamily),
                                          ),
                                        if (isCouponDiscount)
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
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100),
                                const DottedLine(
                                  dashColor: AppColor.textColor,
                                  dashLength: 3.0,
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLanguage.membersText[language],
                                        style: const TextStyle(
                                            color: AppColor.primaryColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: AppFont.fontFamily),
                                      ),
                                      Text(
                                        widget.sendTicketsCount,
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
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100),
                                const DottedLine(
                                  dashColor: AppColor.textColor,
                                  dashLength: 3.0,
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100),
                                Wrap(
                                  children: List.generate(
                                    finalAddons.length,
                                    (index) {
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            finalAddons[index]['addOnName'],
                                            style: const TextStyle(
                                                color: AppColor.primaryColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: AppFont.fontFamily),
                                          ),
                                          Text(
                                            "${finalAddons[index]['amount']} KWD",
                                            style: const TextStyle(
                                                color: AppColor.primaryColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: AppFont.fontFamily),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                if (finalAddonsPrice != 0)
                                  Column(
                                    children: [
                                      SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              1 /
                                              100),
                                      const DottedLine(
                                        dashColor: AppColor.textColor,
                                        dashLength: 3.0,
                                      ),
                                      SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              1 /
                                              100),
                                    ],
                                  ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLanguage.totalAddonsText[language],
                                      style: const TextStyle(
                                          color: AppColor.textColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily),
                                    ),
                                    Text(
                                      "${finalAddonsPrice.toStringAsFixed(2)} KWD",
                                      style: const TextStyle(
                                          color: AppColor.primaryColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: AppFont.fontFamily),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100),
                                Divider(
                                  color: AppColor.textColor,
                                  height: MediaQuery.of(context).size.height *
                                      0.01 /
                                      100,
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                      "${greatGrandTotal.toStringAsFixed(2)} KWD",
                                      style: const TextStyle(
                                          color: AppColor.primaryColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: AppFont.fontFamily),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100),
                                Divider(
                                  color: AppColor.textColor,
                                  height: MediaQuery.of(context).size.height *
                                      0.01 /
                                      100,
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 3 / 100),

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
                                  width: MediaQuery.of(context).size.width *
                                      60 /
                                      100,
                                  height: MediaQuery.of(context).size.height *
                                      5.5 /
                                      100,
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
                                            color:
                                                AppColor.textinputBorderColor),
                                      ),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                AppColor.textinputBorderColor),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                AppColor.textinputBorderColor),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      counterText: '',
                                      hintText:
                                          AppLanguage.enterCodeMsg[language],
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
                                      SnackBarToastMessage.showSnackBar(context,
                                          AppLanguage.codeMsg[language]);
                                      return;
                                    } else {
                                      if (isDiscountApplied) {
                                        SnackBarToastMessage.showSnackBar(
                                            context,
                                            "Coupon is already applied!");
                                      } else {
                                        checkCouponApi(
                                            userId,
                                            couponController.text.toUpperCase(),
                                            tripDetails['trip_id'].toString());
                                      }
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: MediaQuery.of(context).size.height *
                                        4 /
                                        100,
                                    width: MediaQuery.of(context).size.width *
                                        20 /
                                        100,
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
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 3 / 100),

                          //!grand total
                          Container(
                            width: MediaQuery.of(context).size.width * 90 / 100,
                            padding: const EdgeInsets.symmetric(
                                vertical: 9, horizontal: 15),
                            decoration: BoxDecoration(
                                border: Border.all(color: AppColor.grayColor),
                                borderRadius: BorderRadius.circular(50)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      "${greatGrandTotal.toStringAsFixed(2)} KWD",
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
                                  width: MediaQuery.of(context).size.width *
                                      35 /
                                      100,
                                  child: AppButton(
                                    text: AppLanguage.paynowText[language],
                                    onPress: () {
                                      log("sendSlotIds${selectedSlotIds.join(',')}");
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      dateTimeValidation();
                                      // createPaymentApiCall();
                                      // tripBookingApiCall();
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  setDates(selectedDay, focusedDay) {
    setState(() {});
    // Navigator.pop(context);
  }

  setTime() {
    setState(() {});
    isCouponDiscount ? couponApplied() : finalAddonsCal();
    // Navigator.pop(context);
  }

  void changeDateTimeBottomSheet(BuildContext context, screenWidth) {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      constraints: BoxConstraints.expand(
          width: screenWidth,
          height: MediaQuery.of(context).size.height * 95 / 100),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 95 / 100,
              width: MediaQuery.of(context).size.width * 100 / 100,
              decoration: const BoxDecoration(
                color: AppColor.secondaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 2 / 100,
                  ),
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          //table calendar
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 90 / 100,
                            child: TableCalendar(
                              availableGestures: AvailableGestures.none,
                              focusedDay: today,
                              firstDay: DateTime.now(),
                              lastDay: DateTime.utc(2100, 12, 31),
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                              ),
                              calendarStyle: const CalendarStyle(
                                // todayDecoration: BoxDecoration(
                                //   color: AppColor.blueColor,
                                //   shape: BoxShape.circle,
                                // ),
                                selectedDecoration: BoxDecoration(
                                  color: AppColor.themeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              selectedDayPredicate: (day) =>
                                  isSameDay(today, day),
                              onDaySelected: (selectedDay, focusedDay) {
                                getAvailableSlotsApi(
                                        userId,
                                        tripDetails['boat_id'],
                                        DateFormat('yyyy-MM-dd')
                                            .format(selectedDay))
                                    .then((value) => {
                                          setState(() {
                                            selectedTimesShow.clear();
                                            selectedSlotIds.clear();
                                            selectedSlotId = '';
                                            selectedTime = '';
                                          })
                                        });
                                if (tripDetails['trip_date'] == 1) {
                                  setState(() {
                                    today = selectedDay;
                                    log("aasfdasdasgd${DateFormat('yyyy-MM-dd').format(selectedDay)}");
                                    if (availableDates
                                        .map((e) => e.trim())
                                        .contains(DateFormat('yyyy-MM-dd')
                                            .format(selectedDay))) {
                                      log('inserted');
                                      setState(() {
                                        selectedDate = DateFormat('yyyy-MM-dd')
                                            .format(selectedDay);
                                        showSelectedDate =
                                            DateFormat('MMM dd, yyyy')
                                                .format(selectedDay);
                                        log("showSelectedDate$showSelectedDate");
                                      });
                                    } else {
                                      log('deleted');
                                      setState(() {
                                        selectedDate = '';
                                        showSelectedDate = '';
                                      });
                                    }
                                  });
                                } else if (tripDetails['trip_date'] == 2) {
                                  setState(() {
                                    today = selectedDay;
                                    final int dayOfWeek = selectedDay
                                        .weekday; // 1 = Monday ... 7 = Sunday
                                    bool isValidDate =
                                        (dayOfWeek == DateTime.friday ||
                                            dayOfWeek == DateTime.saturday);
                                    log("Selected day is ${isValidDate ? '' : 'not '}valid (Friday or Saturday)");

                                    if (isValidDate) {
                                      selectedDate = DateFormat('yyyy-MM-dd')
                                          .format(selectedDay);
                                      showSelectedDate =
                                          DateFormat('MMM dd, yyyy')
                                              .format(selectedDay);
                                      log("showSelectedDate$showSelectedDate");
                                    } else {
                                      selectedDate = '';
                                      showSelectedDate = '';
                                    }
                                  });
                                } else if (tripDetails['trip_date'] == 0) {
                                  setState(() {
                                    today = selectedDay;
                                    bool isValidDate = !selectedDay.isBefore(
                                        DateTime.now()
                                            .subtract(const Duration(days: 1)));
                                    log("Selected day is ${isValidDate ? '' : 'not '}valid (today/future)");

                                    if (isValidDate) {
                                      selectedDate = DateFormat('yyyy-MM-dd')
                                          .format(selectedDay);
                                      showSelectedDate =
                                          DateFormat('MMM dd, yyyy')
                                              .format(selectedDay);
                                      log("showSelectedDate$showSelectedDate");
                                    } else {
                                      showSelectedDate = '';
                                    }
                                  });
                                }
                                setDates(selectedDay, focusedDay);
                              },

                              // if (tripDetails['trip_date'] == 1)
                              calendarBuilders: CalendarBuilders(
                                defaultBuilder: (context, day, focusedDay) {
                                  final int tripDateType =
                                      tripDetails['trip_date'];

                                  bool shouldHighlight = false;

                                  if (tripDateType == 1) {
                                    // Case 1: Use markedDates
                                    shouldHighlight = markedDates.any(
                                        (markedDay) =>
                                            markedDay.year == day.year &&
                                            markedDay.month == day.month &&
                                            markedDay.day == day.day);
                                  } else if (tripDateType == 0) {
                                    // Case 0: Highlight today and future dates
                                    shouldHighlight = !day.isBefore(
                                        DateTime.now()
                                            .subtract(const Duration(days: 1)));
                                  } else if (tripDateType == 2) {
                                    // Case 2: Highlight future Fridays and Saturdays (weekday 5 and 6)
                                    bool isFridayOrSaturday =
                                        day.weekday == DateTime.friday ||
                                            day.weekday == DateTime.saturday;
                                    shouldHighlight = isFridayOrSaturday &&
                                        !day.isBefore(DateTime.now()
                                            .subtract(const Duration(days: 1)));
                                  }

                                  if (shouldHighlight) {
                                    return Container(
                                      margin: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppColor.blueColor,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${day.day}',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    );
                                  }

                                  return null;
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 3 / 100),

                          if (timeSlots.isNotEmpty && selectedDate.isNotEmpty)
                            Column(
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  child: Text(
                                    AppLanguage
                                        .startTimeForBookingText[language],
                                    style: const TextStyle(
                                        color: AppColor.primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: AppFont.fontFamily),
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        2 /
                                        100),
                              ],
                            ),

                          if (timeSlots.isNotEmpty && selectedDate.isNotEmpty)
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Wrap(
                                runSpacing: 15.0,
                                spacing: 6,
                                // alignment: WrapAlignment.spaceBetween,
                                children:
                                    List.generate(timeSlots.length, (index) {
                                  return Column(
                                    children: [
                                      // SizedBox(
                                      //   width: MediaQuery.of(context)
                                      //           .size
                                      //           .width *
                                      //       21 /
                                      //       100,
                                      //   child: Text(
                                      //     "${AppLanguage.ticketText[language]} (${timeSlots[index]['available_ticket_count']})",
                                      //     textAlign: TextAlign.center,
                                      //     style: const TextStyle(
                                      //         fontFamily: AppFont.fontFamily,
                                      //         fontSize: 13,
                                      //         fontWeight: FontWeight.w500,
                                      //         color: AppColor.primaryColor),
                                      //   ),
                                      // ),
                                      GestureDetector(
                                        onTap: () {
                                          if (timeSlots[index]
                                                  ['available_ticket_count'] >
                                              0) {
                                            if (selectedSlotIds.contains(
                                                timeSlots[index]['slot_id'])) {
                                              selectedSlotIds.remove(
                                                  timeSlots[index]['slot_id']);
                                              selectedTimesShow.remove(
                                                  timeSlots[index]
                                                      ['start_time']);
                                            } else {
                                              selectedSlotIds.add(
                                                  timeSlots[index]['slot_id']);
                                              selectedTimesShow.add(
                                                  timeSlots[index]
                                                      ['start_time']);
                                              selectedTime = timeSlots[index]
                                                  ['start_time_formated'];
                                              sendSelectedTime =
                                                  timeSlots[index]
                                                      ['start_time_formated'];
                                            }
                                            setTime();
                                            setState(() {});
                                            // if (selectedSlotId ==
                                            //     timeSlots[index]['slot_id']
                                            //         .toString()) {
                                            //   setState(() {
                                            //     selectedSlotId = '';
                                            //     selectedTime = '';
                                            //     availableTicketsCount = 0;
                                            //   });
                                            // } else {
                                            //   setState(() {
                                            //     selectedSlotId = timeSlots[index]
                                            //             ['slot_id']
                                            //         .toString();
                                            //     selectedTime =
                                            //         timeSlots[index]['start_time'];
                                            //     sendSelectedTime =
                                            //         timeSlots[index]['start_time'];
                                            //     availableTicketsCount =
                                            //         timeSlots[index]
                                            //             ['available_ticket_count'];
                                            //   });
                                            // }
                                          }
                                        },
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              21 /
                                              100,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              6 /
                                              100,
                                          decoration: BoxDecoration(
                                              color: selectedSlotIds.contains(
                                                      timeSlots[index]
                                                          ['slot_id'])
                                                  ? AppColor.themeColor
                                                  : AppColor.secondaryColor,
                                              border: Border.all(
                                                color: timeSlots[index][
                                                            'available_ticket_count'] <=
                                                        0
                                                    ? AppColor.lightGray2
                                                    : AppColor.lightBlackColor,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Center(
                                            child: Text(
                                              timeSlots[index]['start_time'],
                                              style: TextStyle(
                                                  color: timeSlots[index][
                                                              'available_ticket_count'] <=
                                                          0
                                                      ? AppColor.lightGray2
                                                      : selectedSlotIds.contains(
                                                              timeSlots[index]
                                                                  ['slot_id'])
                                                          ? AppColor
                                                              .secondaryColor
                                                          : AppColor
                                                              .lightBlackColor,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                  fontFamily:
                                                      AppFont.fontFamily),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 3 / 100),

                          AppButton(
                            text: AppLanguage.continueText[language],
                            onPress: () {
                              Navigator.pop(context);
                            },
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
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
