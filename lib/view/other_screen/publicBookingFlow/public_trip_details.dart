import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../controller/app_button.dart';
import '../../../controller/app_color.dart';
import '../../../controller/app_config_provider.dart';
import '../../../controller/app_constant.dart';
import '../../../controller/app_font.dart';
import '../../../controller/app_header.dart';
import '../../../controller/app_image.dart';
import '../../../controller/app_language.dart';
import '../../../controller/app_loader.dart';
import '../../../controller/app_snack_bar_toast_message.dart';
import '../../../controller/custom_input.dart';
import '../../authentication/login_screen.dart';
import 'public_add_ons.dart';
import 'public_booking_details.dart';
import '../review.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

class PublicTripDetailsScreen extends StatefulWidget {
  static String routeName = './PublicTripDetailsScreen';
  final String tripId;
  const PublicTripDetailsScreen({super.key, required this.tripId});

  @override
  State<PublicTripDetailsScreen> createState() =>
      _PublicTripDetailsScreenState();
}

class _PublicTripDetailsScreenState extends State<PublicTripDetailsScreen> {
  TextEditingController timeTextEditingController = TextEditingController();
  TextEditingController maxPeopleTextController = TextEditingController();

  int changeIndex = 1;
  String selectedSlotId = "";
  int imageSelected = 0;
  bool isCheckBox = false;
  DateTime today = DateTime.now();
  bool isApiCalling = false;
  List<dynamic> tripImages = <dynamic>[];
  List<dynamic> timeSlots = <dynamic>[];
  String markedDatesString = "";
  late final Set<DateTime> markedDates;
  List<String> availableDates = <String>[];
  List<int> selectedSlotIds = <int>[];
  String selectedDate = "";
  String showSelectedDate = "";
  String selectedTime = "";
  List<String> selectedTimesShow = <String>[];
  String sendSelectedTime = "";
  int availableTicketsCount = 0;
  List<Map<String, dynamic>> availableSlots = [];

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  int userId = 0;
  int boatId = 0;
  dynamic userDetails;
  dynamic tripDetails = {};

  //!--------------------GET USER DETAILS-----------------------//
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
    getTripsApi(userId);
    setState(() {});
  }

  //!=============================GET Trips DETAILS===================================//
  Future<void> getTripsApi(userId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}view_trip_by_id?user_id=$userId&trip_id=${widget.tripId}");
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
          var item = res['trip_arr'];
          tripDetails = (item != "NA") ? item : {};
          String coverImage = tripDetails['trip_image'];
          tripImages.add({"trip_image_id": 0, "image": coverImage});
          if (tripDetails['tripImages'] != "NA") {
            tripImages.addAll(tripDetails['tripImages']);
          }
          boatId = tripDetails['boat_id'];
          // markedDatesString = tripDetails['dates'];
          // availableDates = markedDatesString.split(",");
          availableDates = List<String>.from(item['date_arr'] ?? []);
          log("availbledates$availableDates");
          if (availableDates
              .contains(DateFormat('yyyy-MM-dd').format(DateTime.now()))) {
            getAvailableSlotsApi(userId, boatId,
                DateFormat('yyyy-MM-dd').format(DateTime.now()));
          }
          fillDates();
          markedDates = availableDates
              .map((dateStr) =>
                  DateTime.parse(dateStr)) // parse string → DateTime
              .toSet(); // convert list → set

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
    if (tripDetails['trip_date'] == 0) {
      getAvailableSlotsApi(
          userId, boatId, DateFormat('yyyy-MM-dd').format(DateTime.now()));
      selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      showSelectedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
    } else if (tripDetails['trip_date'] == 1) {
      if (availableDates
          .map((e) => e.trim())
          .contains(DateFormat('yyyy-MM-dd').format(DateTime.now()))) {
        log('inserted');
        setState(() {
          getAvailableSlotsApi(
              userId, boatId, DateFormat('yyyy-MM-dd').format(DateTime.now()));
          selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
          showSelectedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
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
        final int dayOfWeek =
            DateTime.now().weekday; // 1 = Monday ... 7 = Sunday
        bool isValidDate =
            (dayOfWeek == DateTime.friday || dayOfWeek == DateTime.saturday);
        log("Selected day is ${isValidDate ? '' : 'not '}valid (Friday or Saturday)");

        if (isValidDate) {
          getAvailableSlotsApi(
              userId, boatId, DateFormat('yyyy-MM-dd').format(DateTime.now()));
          selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
          showSelectedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
        } else {
          selectedDate = '';
          showSelectedDate = '';
        }
      });
    }
  }

//!======================date time validation==========
  dateTimeValidation(String enteredTickets) {
    log("selectedTimeSlots$selectedTimesShow");
    // int tickets = enteredTickets.isEmpty ? 0 : int.parse(enteredTickets);
    if (selectedDate.isEmpty || selectedSlotIds.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.selectDateTimeMsg[language]);
      return;
    } else if (enteredTickets.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.pleaseEnterTicketsRequired[language]);
      return;
    } else if (!isCheckBox) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.selectCheckBoxMsg[language]);
      return;
    } else {
      checkSlotsAvailabilityApiCall(widget.tripId, selectedDate,
          selectedSlotIds.join(","), enteredTickets);
    }
  }

  //!=============add favorite trip API================//
  Future<void> addFavoriteApiCall(tripId) async {
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
        'entity_type': 0.toString(),
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
            tripDetails['favourite_status'] = res['favourite_status'];
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

  //!=============================GET Trips DETAILS===================================//
  Future<void> getAvailableSlotsApi(userId, boatId, date) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_available_slot_status?trip_id=${widget.tripId}&user_id=$userId&boat_id=$boatId&date=$date");
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

  //! Check Slot Availability
  Future<void> checkSlotsAvailabilityApiCall(
      tripId, date, slotIds, ticketCount) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}check_availability_slots?trip_id=$tripId&date=$date&slot_ids=$slotIds&ticket_count=$ticketCount");
    print("url $url");
    setState(() {
      isApiCalling = true;
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
          if (tripDetails['addone'] == "NA") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PublicBookingDetails(
                  selectedAddons: const [],
                  sendAddons: const [],
                  sendSelectedTime: sendSelectedTime,
                  selectedSlotId: selectedSlotId,
                  showDate: showSelectedDate,
                  date: selectedDate,
                  time: selectedTime,
                  tripDetails: tripDetails,
                  sendTicketsCount: ticketCount,
                  sendSlotIds: selectedSlotIds.join(","),
                  allTimeSlots: selectedTimesShow.join(', '),
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PublicAddOns(
                  sendSelectedTime: sendSelectedTime,
                  selectedSlotId: selectedSlotId,
                  showDate: showSelectedDate,
                  date: selectedDate,
                  time: selectedTime,
                  tripDetails: tripDetails,
                  sendTicketsCount: ticketCount,
                  sendSlotIds: selectedSlotIds.join(","),
                  allTimeSlots: selectedTimesShow.join(', '),
                ),
              ),
            );
          }
          setState(() {
            isApiCalling = false;
          });
        } else {
          setState(() {
            isApiCalling = false;
          });
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          // ignore: use_build_context_synchronously
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
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
    double screenWidth = MediaQuery.of(context).size.width;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColor.secondaryColor,
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
                  text: AppLanguage.detailsText[language],
                  onPress: () {
                    Navigator.pop(context);
                  },
                ),
                if (tripDetails.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          tripImages.isNotEmpty
                              ? Container(
                                  color: AppColor.creamColor,
                                  width: MediaQuery.of(context).size.width *
                                      100 /
                                      100,
                                  // height:
                                  //     MediaQuery.of(context).size.height * 33 / 100,
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
                                                          ['image'] !=
                                                      null
                                                  ? NetworkImage(
                                                      "${AppConfigProvider.imageURL}${tripImages[imageSelected]['image']}")
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
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
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
                                                  spacing: 8,
                                                  runSpacing: 6,
                                                  children: List.generate(
                                                      tripImages.length,
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
                                                                  image: tripImages[index]
                                                                              [
                                                                              'image'] !=
                                                                          null
                                                                      ? NetworkImage(
                                                                          "${AppConfigProvider.imageURL}${tripImages[index]['image']}")
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
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              : Container(),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 85 / 100,
                            // color: Colors.pink,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      tripDetails["max_people"].toString(),
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
                                  width: MediaQuery.of(context).size.width *
                                      0.3 /
                                      100,
                                  height: MediaQuery.of(context).size.height *
                                      7 /
                                      100,
                                ),
                                if (tripDetails["rating"] != "0.00")
                                  GestureDetector(
                                    onTap: () {
                                      if (tripDetails["rating"] != "0.00") {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => Review(
                                                      tripId: widget.tripId,
                                                      tripImages: tripImages,
                                                      isProperty: false,
                                                    )));
                                      }
                                    },
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  5 /
                                                  100,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  5 /
                                                  100,
                                              child: Image.asset(
                                                  AppImage.ratingIcon),
                                            ),
                                            SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    1 /
                                                    100),
                                            Text(
                                              tripDetails["rating"].toString(),
                                              style: const TextStyle(
                                                  color: AppColor.primaryColor,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily:
                                                      AppFont.fontFamily),
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
                                if (tripDetails["rating"] != "0.00")
                                  Container(
                                    color: AppColor.primaryColor,
                                    width: MediaQuery.of(context).size.width *
                                        0.3 /
                                        100,
                                    height: MediaQuery.of(context).size.height *
                                        7 /
                                        100,
                                  ),
                                Column(
                                  children: [
                                    Text(
                                      "${tripDetails["price_per_hour"].toString()} KWD",
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
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 90 / 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        80 /
                                        100,
                                    child: Text(
                                      tripDetails["boat_name_english"]
                                          .toString(),
                                      style: const TextStyle(
                                          color: AppColor.primaryColor,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: AppFont.fontFamily),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      addFavoriteApiCall(
                                          tripDetails['trip_id']);
                                    },
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          8 /
                                          100,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              8 /
                                              100,
                                      child: Image.asset(
                                          tripDetails['favourite_status'] == 0
                                              ? AppImage.likeDeactiveIcon
                                              : AppImage.likeActiveIcon),
                                    ),
                                  )
                                ]),
                                Row(
                                  children: [
                                    Text(
                                      AppLanguage.boatBrand[language],
                                      style: const TextStyle(
                                          color: AppColor.grayColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily),
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                1 /
                                                100),
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          1 /
                                          100,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              1 /
                                              100,
                                      decoration: const BoxDecoration(
                                          color: AppColor.grayColor,
                                          shape: BoxShape.circle),
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                1 /
                                                100),
                                    Text(
                                      tripDetails['boat_brand'] ?? "",
                                      style: const TextStyle(
                                          color: AppColor.grayColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily),
                                    )
                                  ],
                                ),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: AppLanguage.pickupText[language],
                                        style: const TextStyle(
                                          color: AppColor.grayColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: " \u2022 ",
                                        style: TextStyle(
                                          color: AppColor.grayColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily,
                                        ),
                                      ),
                                      TextSpan(
                                        text: tripDetails['pickup_point'],
                                        style: const TextStyle(
                                          color: AppColor.grayColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100),
                                Text(
                                  AppLanguage.tripTypeText[language],
                                  style: const TextStyle(
                                      color: AppColor.primaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: AppFont.fontFamily),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100),
                                Text(
                                  tripDetails['advertisement_type'] == 0
                                      ? AppLanguage.privateText[language]
                                      : AppLanguage.publicText[language],
                                  style: const TextStyle(
                                      color: AppColor.primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: AppFont.fontFamily),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        2 /
                                        100),
                                Text(
                                  AppLanguage.descriptionText[language],
                                  style: const TextStyle(
                                      color: AppColor.primaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: AppFont.fontFamily),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tripDetails['description_english']
                                            [language],
                                        style: const TextStyle(
                                            color: AppColor.primaryColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: AppFont.fontFamily),
                                      ),
                                      SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              2 /
                                              100),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                5 /
                                                100,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                5 /
                                                100,
                                            child: Image.asset(
                                                AppImage.changePasswordIcon),
                                          ),
                                          SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  1 /
                                                  100),
                                          GestureDetector(
                                            onTap: () {
                                              _cancelPolicyBottomSheet(context);
                                            },
                                            child: Text(
                                              AppLanguage
                                                      .cancellationPolicyText[
                                                  language],
                                              style: const TextStyle(
                                                  color: AppColor.themeColor,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily:
                                                      AppFont.fontFamily),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              2 /
                                              100),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),

                          if (tripDetails['addone'] != "NA")
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  alignment: language == 0
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: Text(
                                    AppLanguage.amenitiesText[language],
                                    style: const TextStyle(
                                        color: AppColor.primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: AppFont.fontFamily),
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        2 /
                                        100),
                              ],
                            ),

                          if (tripDetails['addone'] != "NA")
                            Column(
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      100 /
                                      100,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Wrap(
                                      spacing: 10,
                                      runSpacing: 12.0,
                                      children: List.generate(
                                          tripDetails['addone'].length,
                                          (index) {
                                        return Row(
                                          children: [
                                            if (index == 0)
                                              SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      5 /
                                                      100),
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  32 /
                                                  100,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  12 /
                                                  100,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: AppColor.grayColor,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            12 /
                                                            100,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            12 /
                                                            100,
                                                    child: tripDetails['addone']
                                                                    [index][
                                                                'icon_image'] !=
                                                            null
                                                        ? Image.network(
                                                            '${AppConfigProvider.imageURL}${tripDetails['addone'][index]['icon_image']}',
                                                            fit: BoxFit.cover,
                                                            loadingBuilder:
                                                                (BuildContext
                                                                        context,
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
                                                                  baseColor: Colors
                                                                      .grey
                                                                      .shade300,
                                                                  highlightColor:
                                                                      Colors
                                                                          .grey
                                                                          .shade100,
                                                                  child:
                                                                      Container(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade300,
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                          )
                                                        : Image.asset(
                                                            AppImage.dummyIcon),
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              1 /
                                                              100),
                                                  Text(
                                                    tripDetails['addone'][index]
                                                            ['addon_name']
                                                        [language],
                                                    style: const TextStyle(
                                                        color: AppColor
                                                            .primaryColor,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontFamily:
                                                            AppFont.fontFamily),
                                                  )
                                                ],
                                              ),
                                            ),
                                            if (index ==
                                                tripDetails['addone'].length -
                                                    1)
                                              SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      2 /
                                                      100),
                                          ],
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        3 /
                                        100),
                              ],
                            ),

                          //!company details
                          Container(
                            color: AppColor.themeColor.withOpacity(0.1),
                            width:
                                MediaQuery.of(context).size.width * 100 / 100,
                            padding: EdgeInsets.symmetric(
                                vertical: MediaQuery.of(context).size.height *
                                    1 /
                                    100,
                                horizontal: MediaQuery.of(context).size.width *
                                    5 /
                                    100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLanguage.companyProfileText[language],
                                  style: const TextStyle(
                                      color: AppColor.primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: AppFont.fontFamily),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tripDetails['owner_company_name'] ??
                                              "",
                                          style: const TextStyle(
                                              color: AppColor.primaryColor,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: AppFont.fontFamily),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          18 /
                                          100,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              18 /
                                              100,
                                      decoration: BoxDecoration(
                                        // color: Colors.amber,
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                            image: tripDetails['image'] != null
                                                ? NetworkImage(
                                                    "${AppConfigProvider.imageURL}${tripDetails['image']}")
                                                : const AssetImage(AppImage
                                                        .imageFrameImage)
                                                    as ImageProvider,
                                            fit: BoxFit.cover),
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 1 / 100),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 90 / 100,
                            child: Row(
                              children: [
                                Text(
                                  AppLanguage.bookNowText[language],
                                  style: const TextStyle(
                                      color: AppColor.primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: AppFont.fontFamily),
                                ),
                                const Spacer(),
                                Container(
                                  child: Row(
                                    children: [
                                      Text(
                                        AppLanguage.availabilitytext[language],
                                        style: const TextStyle(
                                            color: AppColor.primaryColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: AppFont.fontFamily),
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                1 /
                                                100,
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                4 /
                                                100,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                4 /
                                                100,
                                        decoration: BoxDecoration(
                                            color: AppColor.blueColor,
                                            borderRadius:
                                                BorderRadius.circular(100)),
                                      )
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      3 /
                                      100,
                                ),
                                Container(
                                  child: Row(
                                    children: [
                                      Text(
                                        AppLanguage.selectedText[language],
                                        style: const TextStyle(
                                            color: AppColor.primaryColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: AppFont.fontFamily),
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                1 /
                                                100,
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                4 /
                                                100,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                4 /
                                                100,
                                        decoration: BoxDecoration(
                                            color: AppColor.themeColor,
                                            borderRadius:
                                                BorderRadius.circular(100)),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // SizedBox(
                          //     height: MediaQuery.of(context).size.height * 2 / 100),

                          //!table calendar
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
                                        boatId,
                                        DateFormat('yyyy-MM-dd')
                                            .format(selectedDay))
                                    .then((value) => {
                                          setState(() {
                                            selectedSlotIds.clear();
                                            selectedTimesShow.clear();
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
                                          markedDay.day == day.day,
                                    );
                                  } else if (tripDateType == 0) {
                                    // Case 0: Highlight today and future dates
                                    shouldHighlight = !day.isBefore(
                                      DateTime.now()
                                          .subtract(const Duration(days: 1)),
                                    );
                                  } else if (tripDateType == 2) {
                                    // Case 2: Highlight future Fridays and Saturdays
                                    bool isFridayOrSaturday =
                                        day.weekday == DateTime.friday ||
                                            day.weekday == DateTime.saturday;
                                    shouldHighlight = isFridayOrSaturday &&
                                        !day.isBefore(DateTime.now()
                                            .subtract(const Duration(days: 1)));
                                  }

                                  // 🚨 Extra check: If tripDateType == 0 or 2, remove highlight if in availableDates
                                  if ((tripDateType == 0 ||
                                          tripDateType == 2) &&
                                      availableDates.contains(
                                          DateFormat('yyyy-MM-dd')
                                              .format(day))) {
                                    shouldHighlight = false;
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
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                21 /
                                                100,
                                        child: Text(
                                          "${AppLanguage.ticketText[language]} (${timeSlots[index]['available_ticket_count']})",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontFamily: AppFont.fontFamily,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColor.primaryColor),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          if (timeSlots[index][
                                                      'available_ticket_count'] >
                                                  0 &&
                                              !timeSlots[index]
                                                  ['booking_status']) {
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
                                            setState(() {});
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
                                                color: (timeSlots[index][
                                                                'available_ticket_count'] <=
                                                            0 ||
                                                        timeSlots[index]
                                                            ['booking_status'])
                                                    ? AppColor.lightGray2
                                                    : AppColor.lightBlackColor,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Center(
                                            child: Text(
                                              timeSlots[index]['start_time'],
                                              style: TextStyle(
                                                  color: (timeSlots[index][
                                                                  'available_ticket_count'] <=
                                                              0 ||
                                                          timeSlots[index][
                                                              'booking_status'])
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

                          //! Number of people textfield
                          Column(
                            children: [
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      1 /
                                      100),
                              CustomFormatterTextFormField(
                                controller: maxPeopleTextController,
                                fillColorStatus: 0,
                                hintText:
                                    AppLanguage.enterTicketsRequired[language],
                                keyboardtype: TextInputType.number,
                                maxLength: 4,
                                inputFormatter: AppConstant.onlyDigitFormatter,
                                readOnly: false,
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      3 /
                                      100),
                            ],
                          ),

                          //! Check Box
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 90 / 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isCheckBox = !isCheckBox;
                                    });
                                  },
                                  child: SizedBox(
                                    width: screenWidth > 600
                                        ? MediaQuery.of(context).size.width *
                                            5 /
                                            100
                                        : MediaQuery.of(context).size.width *
                                            7 /
                                            100,
                                    height: screenWidth > 600
                                        ? MediaQuery.of(context).size.width *
                                            5 /
                                            100
                                        : MediaQuery.of(context).size.width *
                                            7 /
                                            100,
                                    child: Image.asset(isCheckBox
                                        ? AppImage.tickIcon
                                        : AppImage.checkBookIcon),
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      80 /
                                      100,
                                  child: Text(
                                    AppLanguage.agreeText[language],
                                    style: const TextStyle(
                                        color: AppColor.primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: AppFont.fontFamily),
                                  ),
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 4 / 100),

                          AppButton(
                            text: AppLanguage.bookNowText[language],
                            onPress: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              if (userId == 0) {
                                SnackBarToastMessage.showSnackBar(
                                    context, AppLanguage.loginMsg[language]);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const Login()));
                                return;
                              }
                              if (timeSlots.isEmpty) {
                                SnackBarToastMessage.showSnackBar(
                                    context,
                                    AppLanguage
                                        .boatTimingNotAvailableText[language]);
                              } else {
                                dateTimeValidation(
                                    maxPeopleTextController.text.trim());
                              }
                            },
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        )),
      ),
    );
  }

  // cancel policy bottom sheet
  void _cancelPolicyBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColor.secondaryColor.withOpacity(0.1),
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Directionality(
                textDirection:
                    language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                child: Container(
                  width: MediaQuery.of(context).size.width * 100 / 100,
                  height: MediaQuery.of(context).size.height * 100 / 100,
                  color: AppColor.secondaryColor.withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 80 / 100,
                        //    height: MediaQuery.of(context).size.height * 36 / 100,
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 15),
                        decoration: BoxDecoration(
                            color: AppColor.secondaryColor,
                            borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLanguage.cancellationPolicyText[language],
                              style: const TextStyle(
                                  color: AppColor.themeColor,
                                  fontFamily: AppFont.fontFamily,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    1 /
                                    100),
                            Text(
                              AppLanguage.cancelDetailsText[language],
                              style: const TextStyle(
                                  color: AppColor.primaryColor,
                                  fontFamily: AppFont.fontFamily,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    3 /
                                    100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }
}
