import 'dart:convert';
import 'dart:developer';
import '/view/other_screen/cancel_booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../chat/chat_screen.dart';
import '../../controller/app_button.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../../model/chat_user.dart';
import '../authentication/login_screen.dart';
import 'package:http/http.dart' as http;
import 'boat_details.dart';
import 'dart:ui' as ui;

class UpComingDetailsScreen extends StatefulWidget {
  static String routeName = "./DetailsScreen";
  final String tripId;
  const UpComingDetailsScreen({super.key, required this.tripId});

  @override
  State<UpComingDetailsScreen> createState() => _UpComingDetailsScreenState();
}

class _UpComingDetailsScreenState extends State<UpComingDetailsScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController messageTextEditingController = TextEditingController();
  bool isApiCalling = true;
  int userId = 0;
  dynamic data;
  dynamic userDataArr;
  dynamic tripDetails = {};
  double longitudex = 77.4126;
  double latitudex = 23.2599;
  GoogleMapController? mapController;
  LatLng initialPosition = const LatLng(23.2599, 77.4126);
  List<dynamic> selectedAddons = <dynamic>[];
  List<dynamic> finalAddons = [];
  int totalSlotsCount = 0;

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  //----------------------------GET USER DETAILS--------------------------------//
  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    data = prefs.getString("userDetails");

    if (data == null) {
    } else {
      userDataArr = jsonDecode(data);
      userId = userDataArr['user_id'] ?? 0;
    }

    // print("userDataArr $userDataArr");
    tripDetailsApiCall(userId);
    setState(() {});
  }

  //------------------------Upcoming trip Details API CALL--------------------------------//
  Future<void> tripDetailsApiCall(userId) async {
    setState(() {
      isApiCalling = true;
    });
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}view_booking_details?user_id=$userId&trip_booking_id=${widget.tripId}");
    print("url $url");

    String token = AppConstant.token;

    if (token.isEmpty) {
      print("Token is missing!");
      // return;
    }

    Map<String, String> headers = {
      'Authorization': 'Bearer $token', // Use 'Bearer' if required
    };

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
          if (tripDetails.isNotEmpty) {
            log('tripDetails$tripDetails');
            latitudex = double.parse(tripDetails['latitude']);
            longitudex = double.parse(tripDetails['longitude']);
            initialPosition = LatLng(latitudex, longitudex);
            selectedAddons = (tripDetails['selected_addons'] != "NA")
                ? tripDetails['selected_addons']
                : [];
            totalSlotsCount = tripDetails['slots_booked'].length;
            finalAddonsCal();
          }
          setState(() {
            isApiCalling = false;
          });
        } else {
          setState(() {
            isApiCalling = false;
          });
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

  finalAddonsCal() {
    finalAddons.clear();
    for (var entry in selectedAddons) {
      double total = 0;
      if (entry['subAddons'].isNotEmpty) {
        for (var subEntry in entry['subAddons']) {
          total += subEntry['quantity'] * double.parse(subEntry["price"]);
        }
        finalAddons.add({
          "addOnName": entry['addon_name'],
          "amount": total,
        });
        // finalAddonsPrice += total;
      }
    }
    log("finalAddons$finalAddons");
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
    // double screenWidth = MediaQuery.of(context).size.width;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColor.secondaryColor,
        statusBarIconBrightness: Brightness.dark));
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        body: SafeArea(
          child: Directionality(
            textDirection:
                language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            child: Container(
              width: MediaQuery.of(context).size.width * 100 / 100,
              height: MediaQuery.of(context).size.height * 100 / 100,
              color: AppColor.secondaryColor,
              child: Column(
                children: [
                  const NoInternetBanner(),
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
                              height:
                                  MediaQuery.of(context).size.width * 5 / 100,
                              width:
                                  MediaQuery.of(context).size.width * 5 / 100,
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
                        Text("ID: #${tripDetails['random_booking_id'] ?? ""}",
                            style: const TextStyle(
                                color: AppColor.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                fontFamily: AppFont.fontFamily)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 2 / 100,
                  ),
                  if (tripDetails.isNotEmpty)
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100),

                            //!status details
                            Container(
                              alignment: Alignment.center,
                              width:
                                  MediaQuery.of(context).size.width * 100 / 100,
                              color: const Color(0xffEFF9F8),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    85 /
                                    100,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                63 /
                                                100,
                                        child: Column(
                                          children: [
                                            //status view details
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    tripDetails[
                                                            "trip_status_label"] ??
                                                        "",
                                                    style: const TextStyle(
                                                        fontFamily:
                                                            AppFont.fontFamily,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: AppColor
                                                            .yellowColor),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      4 /
                                                      100,
                                                  child: const Text(
                                                    " \u2022 ",
                                                    style: TextStyle(
                                                        fontFamily:
                                                            AppFont.fontFamily,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            Color(0xffE7E3E3)),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => BoatDetailsScreen(
                                                            boatName: tripDetails[
                                                                'boat_name_english'],
                                                            boatBrand: tripDetails[
                                                                'boat_brand'],
                                                            toilet: tripDetails['toilet']
                                                                .toString(),
                                                            cabins: tripDetails[
                                                                    'cabins']
                                                                .toString(),
                                                            capacity: tripDetails[
                                                                    'boat_capacity']
                                                                .toString(),
                                                            size: tripDetails[
                                                                    'boat_size']
                                                                .toString(),
                                                            year: tripDetails[
                                                                    'boat_year']
                                                                .toString(),
                                                            registration:
                                                                tripDetails['boat_registration_number']
                                                                    .toString()),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    child: Text(
                                                      AppLanguage
                                                              .viewDetailsText[
                                                          language],
                                                      style: const TextStyle(
                                                          fontFamily: AppFont
                                                              .fontFamily,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: AppColor
                                                              .themeColor,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                          decorationColor:
                                                              AppColor
                                                                  .themeColor),
                                                    ),
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

                                            //name
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  63 /
                                                  100,
                                              child: Text(
                                                tripDetails[
                                                        'boat_name_english'] ??
                                                    "",
                                                style: const TextStyle(
                                                    fontFamily:
                                                        AppFont.fontFamily,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColor.primaryColor),
                                              ),
                                            ),
                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    1 /
                                                    100),

                                            //details
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  63 /
                                                  100,
                                              child: Row(
                                                children: [
                                                  Text(
                                                    AppLanguage
                                                        .boatBrand[language],
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            AppColor.textColor,
                                                        fontFamily:
                                                            AppFont.fontFamily),
                                                  ),
                                                  const Text(
                                                    " \u2022 ",
                                                    style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            AppColor.textColor,
                                                        fontFamily:
                                                            AppFont.fontFamily),
                                                  ),
                                                  Text(
                                                    tripDetails['boat_brand'] ??
                                                        "",
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            AppColor.textColor,
                                                        fontFamily:
                                                            AppFont.fontFamily),
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              2 /
                                              100),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100),

                            //! Advertisement type
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 85 / 100,
                              child: Text(
                                AppLanguage.tripTypeText[language],
                                style: const TextStyle(
                                    fontFamily: AppFont.fontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColor.primaryColor),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    1 /
                                    100),

                            //!address text
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 85 / 100,
                              child: Text(
                                tripDetails['advertisement_type'] == 0
                                    ? AppLanguage.privateText[language]
                                    : AppLanguage.publicText[language],
                                style: const TextStyle(
                                    fontFamily: AppFont.fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColor.primaryColor),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    1 /
                                    100),

                            //!destination
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 85 / 100,
                              child: Text(
                                AppLanguage.destinationText[language],
                                style: const TextStyle(
                                    fontFamily: AppFont.fontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColor.primaryColor),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    1 /
                                    100),

                            //!address text
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 85 / 100,
                              child: Text(
                                tripDetails['destination'][language] ?? "",
                                style: const TextStyle(
                                    fontFamily: AppFont.fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColor.primaryColor),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100),

                            //!location address
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 85 / 100,
                              child: Text(
                                AppLanguage.locationAddressText[language],
                                style: const TextStyle(
                                    fontFamily: AppFont.fontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColor.primaryColor),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    1 /
                                    100),

                            //!address text
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 85 / 100,
                              child: Text(
                                tripDetails['pickup_point'] ?? "",
                                style: const TextStyle(
                                    fontFamily: AppFont.fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColor.primaryColor),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100),

                            //!View Location
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    openMap(tripDetails['latitude'],
                                        tripDetails['longitude']);
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    width: MediaQuery.of(context).size.width *
                                        42 /
                                        100,
                                    alignment: Alignment.center,
                                    child: Text(
                                      AppLanguage.getDirectionsText[language],
                                      style: const TextStyle(
                                          fontFamily: AppFont.fontFamily,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.themeColor,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColor.themeColor),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    1 /
                                    100),

                            //!map
                            Stack(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      15 /
                                      100,
                                  width: MediaQuery.of(context).size.width *
                                      85 /
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
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100),

                            //!booking details
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 85 / 100,
                              child: Text(
                                AppLanguage.bookingDetailsText[language],
                                style: const TextStyle(
                                    fontFamily: AppFont.fontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.primaryColor),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100),

                            //!date time
                            GestureDetector(
                              onTap: () {},
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    85 /
                                    100,
                                child: Row(
                                  children: [
                                    //image
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          6 /
                                          100,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              6 /
                                              100,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.asset(
                                          AppImage.dateTimeIcon,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          3 /
                                          100,
                                    ),

                                    //!left side
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          60 /
                                          100,
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                60 /
                                                100,
                                            child: Text(
                                              tripDetails['formated_date'] ??
                                                  "",
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.primaryColor,
                                                  fontFamily:
                                                      AppFont.fontFamily),
                                            ),
                                          ),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                .5 /
                                                100,
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                60 /
                                                100,
                                            child: Text(
                                              AppLanguage.bookingDateStartTime[
                                                  language],
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.textColor,
                                                  fontFamily:
                                                      AppFont.fontFamily),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    //right side
                                    SizedBox(
                                      // color: Colors.red,
                                      width: MediaQuery.of(context).size.width *
                                          13 /
                                          100,
                                      child: Text(
                                        AppLanguage.changeText[language],
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                AppColor.secondaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColor.secondaryColor,
                                            fontFamily: AppFont.fontFamily),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100),

                            //!hours
                            GestureDetector(
                              onTap: () {},
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    85 /
                                    100,
                                child: Row(
                                  children: [
                                    //!image
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          7 /
                                          100,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              7 /
                                              100,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.asset(
                                          AppImage.clockIcon,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          3 /
                                          100,
                                    ),

                                    //!left side
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          60 /
                                          100,
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                60 /
                                                100,
                                            child: Text(
                                              "${(tripDetails['hours'] * totalSlotsCount)} hours",
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.primaryColor,
                                                  fontFamily:
                                                      AppFont.fontFamily),
                                            ),
                                          ),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                .5 /
                                                100,
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                60 /
                                                100,
                                            child: Text(
                                              AppLanguage
                                                  .bookingHoursTime[language],
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.textColor,
                                                  fontFamily:
                                                      AppFont.fontFamily),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    //!right side
                                    SizedBox(
                                      // color: Colors.red,
                                      width: MediaQuery.of(context).size.width *
                                          13 /
                                          100,
                                      child: Text(
                                        AppLanguage.changeText[language],
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                AppColor.secondaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColor.secondaryColor,
                                            fontFamily: AppFont.fontFamily),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100),

                            //!add-on text
                            if (selectedAddons.isNotEmpty)
                              Column(
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        85 /
                                        100,
                                    child: Text(
                                      AppLanguage.addOnText[language],
                                      style: const TextStyle(
                                          fontFamily: AppFont.fontFamily,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColor.primaryColor),
                                    ),
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              2 /
                                              100),
                                ],
                              ),

                            //!addons list
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Wrap(
                                children: List.generate(
                                  selectedAddons.length,
                                  (index) {
                                    return Column(
                                      children: [
                                        if (selectedAddons[index]['subAddons']
                                            .isNotEmpty)
                                          Container(
                                            alignment: Alignment.centerLeft,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                90 /
                                                100,
                                            child: Text(
                                              "${selectedAddons[index]['addon_name'][language]} (${selectedAddons[index]['subAddons'].length})",
                                              style: const TextStyle(
                                                color: AppColor.primaryColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: AppFont.fontFamily,
                                              ),
                                            ),
                                          ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                1 /
                                                100),
                                        if (selectedAddons[index]['subAddons']
                                            .isNotEmpty)
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                90 /
                                                100,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Wrap(
                                                spacing: 15.0,
                                                children: List.generate(
                                                    selectedAddons[index]
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
                                                                .boaderColor),
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
                                                              15 /
                                                              100,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              15 /
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
                                                                ? Image.network(
                                                                    '${AppConfigProvider.imageURL}${selectedAddons[index]['subAddons'][subIndex]['image']}',
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    loadingBuilder: (BuildContext
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
                                                                          highlightColor: Colors
                                                                              .grey
                                                                              .shade100,
                                                                          child:
                                                                              Container(
                                                                            color:
                                                                                Colors.grey.shade300,
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
                                                                selectedAddons[index]['subAddons'][subIndex]
                                                                            [
                                                                            'subAddon_name']
                                                                        [
                                                                        language] ??
                                                                    "",
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style:
                                                                    const TextStyle(
                                                                  color: AppColor
                                                                      .primaryColor,
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontFamily:
                                                                      AppFont
                                                                          .fontFamily,
                                                                ),
                                                              ),
                                                              Text(
                                                                "${selectedAddons[index]['subAddons'][subIndex]['price'].toString()} KWD",
                                                                style:
                                                                    const TextStyle(
                                                                  color: AppColor
                                                                      .textColor,
                                                                  fontSize: 12,
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
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          2,
                                                                      horizontal:
                                                                          4),
                                                              decoration: BoxDecoration(
                                                                  color: AppColor
                                                                      .themeColor
                                                                      .withOpacity(
                                                                          0.2),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              4)),
                                                              child: Text(
                                                                AppLanguage.qtyText[
                                                                        language] +
                                                                    selectedAddons[index]['subAddons'][subIndex]
                                                                            [
                                                                            'quantity']
                                                                        .toString(),
                                                                style:
                                                                    const TextStyle(
                                                                  color: AppColor
                                                                      .themeColor,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontFamily:
                                                                      AppFont
                                                                          .fontFamily,
                                                                ),
                                                              ),
                                                            ),
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
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100),

                            //!billing details
                            Container(
                              width:
                                  MediaQuery.of(context).size.width * 100 / 100,
                              color: const Color(0xffEFF9F8),
                              child: Column(
                                children: [
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              2 /
                                              100),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        85 /
                                        100,
                                    child: Text(
                                      AppLanguage.billingDetailsText[language],
                                      style: const TextStyle(
                                          fontFamily: AppFont.fontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.primaryColor),
                                    ),
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              2 /
                                              100),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        85 /
                                        100,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              42 /
                                              100,
                                          child: Text(
                                            "${(tripDetails['hours'] * totalSlotsCount)} hours",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.textColor),
                                          ),
                                        ),
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              42 /
                                              100,
                                          alignment: language == 1
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                          child: Text(
                                            "${tripDetails['price_per_hour'] * totalSlotsCount} KWD",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        85 /
                                        100,
                                    child: Text(
                                      "${AppLanguage.priceText[language]}${tripDetails['price_per_hour']}KWD",
                                      style: const TextStyle(
                                          fontFamily: AppFont.fontFamily,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: AppColor.themeColor),
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        85 /
                                        100,
                                    child: const Text(
                                      "-------------------------------------------------------------------------------------------",
                                      maxLines: 1,
                                      style: TextStyle(
                                          fontFamily: AppFont.fontFamily,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: AppColor.boaderColor),
                                    ),
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              1 /
                                              100),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        85 /
                                        100,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              42 /
                                              100,
                                          child: Text(
                                            tripDetails['advertisement_type'] ==
                                                    0
                                                ? AppLanguage
                                                    .membersText[language]
                                                : AppLanguage
                                                    .ticketText[language],
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.textColor),
                                          ),
                                        ),
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              42 /
                                              100,
                                          alignment: language == 1
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                          child: Text(
                                            "x${tripDetails['ticket_count']}",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              .5 /
                                              100),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        85 /
                                        100,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              42 /
                                              100,
                                          child: Text(
                                            AppLanguage.addOnText[language],
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.textColor),
                                          ),
                                        ),
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              42 /
                                              100,
                                          alignment: language == 1
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                          child: Text(
                                            "${tripDetails['addon_total_amount']} KWD",
                                            style: const TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        85 /
                                        100,
                                    child: Wrap(
                                      children: List.generate(
                                        finalAddons.length,
                                        (index) {
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                finalAddons[index]['addOnName']
                                                        [language] ??
                                                    "",
                                                style: const TextStyle(
                                                    color:
                                                        AppColor.primaryColor,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    fontFamily:
                                                        AppFont.fontFamily),
                                              ),
                                              Text(
                                                "${finalAddons[index]['amount']} KWD",
                                                style: const TextStyle(
                                                    color:
                                                        AppColor.primaryColor,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily:
                                                        AppFont.fontFamily),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  if ((double.tryParse(
                                              tripDetails['insurance_amount']
                                                      ?.toString() ??
                                                  '') ??
                                          0) >
                                      0)
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          85 /
                                          100,
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                42 /
                                                100,
                                            child: Text(
                                              "${AppLanguage.insuranceText[language]}${tripDetails['insurance_refunded'] == 1 ? " (${AppLanguage.insuranceRefundedText[language]})" : ""}",
                                              style: const TextStyle(
                                                  fontFamily: AppFont.fontFamily,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColor.textColor),
                                            ),
                                          ),
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                42 /
                                                100,
                                            alignment: language == 1
                                                ? Alignment.centerLeft
                                                : Alignment.centerRight,
                                            child: Text(
                                              "${tripDetails['insurance_amount']} KWD",
                                              style: const TextStyle(
                                                  fontFamily: AppFont.fontFamily,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColor.primaryColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              2 /
                                              100),
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        85 /
                                        100,
                                    height: MediaQuery.of(context).size.height *
                                        .1 /
                                        100,
                                    color: AppColor.boaderColor,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          85 /
                                          100,
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                30 /
                                                100,
                                            // color: Colors.red,
                                            child: Text(
                                              AppLanguage
                                                  .grandTotalText[language],
                                              style: const TextStyle(
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColor.primaryColor),
                                            ),
                                          ),
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                55 /
                                                100,
                                            // color: Colors.green,
                                            alignment: language == 1
                                                ? Alignment.centerLeft
                                                : Alignment.centerRight,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "${tripDetails['total_amount']} KWD",
                                                  style: const TextStyle(
                                                      fontFamily:
                                                          AppFont.fontFamily,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColor
                                                          .primaryColor),
                                                ),
                                                if (tripDetails['discount'] !=
                                                    0)
                                                  Text(
                                                    "+${AppLanguage.withText[language]} ${tripDetails['discount']}% ${AppLanguage.discountText[language]}",
                                                    style: const TextStyle(
                                                        fontFamily:
                                                            AppFont.fontFamily,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColor
                                                            .primaryColor),
                                                  ),
                                                if (tripDetails[
                                                        'coupon_code'] !=
                                                    "NA")
                                                  Text(
                                                    "+${AppLanguage.withText[language]} ${tripDetails['coupon_discount']}% ${AppLanguage.couponDiscountText[language]}",
                                                    style: const TextStyle(
                                                        fontFamily:
                                                            AppFont.fontFamily,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColor
                                                            .primaryColor),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        85 /
                                        100,
                                    height: MediaQuery.of(context).size.height *
                                        .1 /
                                        100,
                                    color: AppColor.boaderColor,
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              2 /
                                              100),
                                ],
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    3 /
                                    100),

                            //!cancel booking
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => CancelBooking(
                                              cancelType: 1,
                                              tripBookingId: widget.tripId,
                                              propertyBookingId: 1,
                                            )));
                              },
                              child: Container(
                                color: Colors.transparent,
                                width: MediaQuery.of(context).size.width *
                                    85 /
                                    100,
                                child: Row(
                                  children: [
                                    Text(
                                      AppLanguage.cancelBookingText[language],
                                      style: const TextStyle(
                                          fontFamily: AppFont.fontFamily,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColor.primaryColor),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          1 /
                                          100,
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          4 /
                                          100,
                                      height:
                                          MediaQuery.of(context).size.height *
                                              2 /
                                              100,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Image.asset(
                                          AppImage.infoIcon,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          4 /
                                          100,
                                      height:
                                          MediaQuery.of(context).size.height *
                                              2 /
                                              100,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Image.asset(
                                          AppImage.nextArrowImage,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    3 /
                                    100),

                            //!chat button
                            AppButton(
                                text: AppLanguage.chatText[language],
                                onPress: () {
                                  navigateToChatScreen(
                                      tripDetails['owner_id'].toString());
                                }),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100),
                          ],
                        ),
                      ),
                    ),
                  if (tripDetails.isEmpty && !isApiCalling)
                    Column(
                      children: [
                        SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 20 / 100),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 20 / 100,
                          height: MediaQuery.of(context).size.width * 20 / 100,
                          child: Image.asset(
                            AppImage.noDataIcon,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
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
