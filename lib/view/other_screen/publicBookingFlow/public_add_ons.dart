import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../../controller/app_button.dart';
import '../../../controller/app_color.dart';
import '../../../controller/app_config_provider.dart';
import '../../../controller/app_constant.dart';
import '../../../controller/app_font.dart';
import '../../../controller/app_image.dart';
import '../../../controller/app_language.dart';
import '../boat_details.dart';
import 'public_booking_details.dart';
import 'dart:ui' as ui;

class PublicAddOns extends StatefulWidget {
  static String routeName = './PublicAddOns';
  final dynamic tripDetails;
  final String date;
  final String time;
  final String allTimeSlots;
  final String showDate;
  final String selectedSlotId;
  final String sendSelectedTime;
  final String sendTicketsCount;
  final String sendSlotIds;
  const PublicAddOns({
    super.key,
    this.tripDetails,
    required this.date,
    required this.time,
    required this.showDate,
    required this.selectedSlotId,
    required this.sendSelectedTime,
    required this.sendTicketsCount,
    required this.sendSlotIds,
    required this.allTimeSlots,
  });

  @override
  State<PublicAddOns> createState() => _PublicAddOnsState();
}

class _PublicAddOnsState extends State<PublicAddOns> {
  int selectCategory = 1;
  List<dynamic> addOnsList = <dynamic>[];
  List<dynamic> selectedAddons = <dynamic>[];
  List<dynamic> showSelectedAddons = <dynamic>[];
  List<String> selectedTimesShow = <String>[];

  bool isApiCalling = false;

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  int userId = 0;
  dynamic userDetails;
  dynamic tripDetails = {};
  int mainIndex = 0;
  String grandTotal = "0";

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
      tripDetails = widget.tripDetails;
      addOnsList = widget.tripDetails['selected_addons'];
      selectedTimesShow = widget.allTimeSlots.isNotEmpty
          ? widget.allTimeSlots.split(", ").map((e) => e).toList()
          : [];
          log("calculation ((${tripDetails['minimum_hours']} * ${selectedTimesShow.length}) * ${double.parse(tripDetails['price_per_hour'])}) * (${widget.sendTicketsCount})");
      grandTotal =
          (((tripDetails['minimum_hours'] * selectedTimesShow.length) *
                  double.parse(tripDetails['price_per_hour'])) * double.parse(widget.sendTicketsCount))
              .toStringAsFixed(1);

      resetQuantity();
      // getGrandTotal();
    }
    for (int i = 0; i < addOnsList.length; i++) {
      showSelectedAddons.add({
        "addon_id": addOnsList[i]['addon_id'],
        "addon_name": addOnsList[i]['addon_name'][language],
        "subAddons": []
      });
    }

    log("showSelectedAddons$showSelectedAddons");
    setState(() {
      isApiCalling = false;
    });
    setState(() {});
  }

  resetQuantity() {
    log('i am  run');
    for (var entry in addOnsList) {
      for (var subEntry in entry['subAddons']) {
        subEntry['quantity'] = 0;
        subEntry['total_price'] = subEntry['price'];
      }
    }
    log("addOnsList$addOnsList");
  }

  void getGrandTotal() {
    double total = 0;
    for (int i = 0; i < addOnsList.length; i++) {
      final subAddons = addOnsList[i]["subAddons"] as List<dynamic>;
      for (int j = 0; j < subAddons.length; j++) {
        if (subAddons[j]['quantity'] > 0) {
          total += subAddons[j]['total_price'];
        }
      }
    }
    grandTotal = ((((tripDetails['minimum_hours'] * selectedTimesShow.length) *
                  double.parse(tripDetails['price_per_hour'])) * double.parse(widget.sendTicketsCount)) +
            total)
        .toStringAsFixed(1);
    setState(() {});
  }

  void addData(int addonId, int subAddOnId, int quantity, double price) {
    for (var i = 0; i < selectedAddons.length; i++) {
      if (selectedAddons[i]['addon_id'] == addonId &&
          selectedAddons[i]['sub_addon_id'] == subAddOnId) {
        selectedAddons[i] = {
          'addon_id': addonId,
          'sub_addon_id': subAddOnId,
          'quantity': quantity,
          'price': price
        };
        log("$selectedAddons");
        selectedAddons.removeWhere((item) => item['quantity'] == 0);
        return;
      }
    }

    selectedAddons.add({
      'addon_id': addonId,
      'sub_addon_id': subAddOnId,
      'quantity': quantity,
      'price': price
    });
    selectedAddons.removeWhere((item) => item['quantity'] == 0);
    log("$selectedAddons");
  }

  void showAddData(int addonId, int subAddOnId, String image, String name,
      int quantity, double price) {
    // Find the addon with matching addon_id
    var addon = showSelectedAddons.firstWhere(
      (add) => add['addon_id'] == addonId,
      orElse: () => {},
    );

    if (addon.isNotEmpty) {
      // Get the list of subAddons, or initialize it if null
      List<Map<String, dynamic>> subAddons =
          List<Map<String, dynamic>>.from(addon['subAddons'] ?? []);

      // Check if subAddOnId already exists
      int existingIndex =
          subAddons.indexWhere((sub) => sub['subAddOnId'] == subAddOnId);

      Map<String, dynamic> newSubAddon = {
        'subAddOnId': subAddOnId,
        'image': image,
        'quantity': quantity,
        'price': price,
        'subAddon_name': name,
      };

      if (existingIndex != -1) {
        // Update existing sub-addon
        subAddons[existingIndex] = newSubAddon;
      } else {
        // Add new sub-addon
        subAddons.add(newSubAddon);
      }

      // Update the subAddons in the main addon object
      addon['subAddons'] = subAddons;
    } else {
      // Add new addon with this sub-addon
      showSelectedAddons.add({
        'addon_id': addonId,
        'subAddons': [
          {
            'subAddOnId': subAddOnId,
            'image': image,
            'quantity': quantity,
            'price': price,
            'subAddon_name': name,
          }
        ],
      });
    }
    log("showSelectedAddons$showSelectedAddons");
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColor.secondaryColor,
        statusBarIconBrightness: Brightness.dark));
    return WillPopScope(
      onWillPop: () {
        if (mainIndex == 0) {
          Navigator.pop(context);
        } else {
          setState(() {
            mainIndex--;
          });
        }
        return Future.value(false);
      },
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
                SizedBox(
                  height: MediaQuery.of(context).size.height * 7 / 100,
                  width: MediaQuery.of(context).size.width * 90 / 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (mainIndex == 0) {
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              mainIndex--;
                            });
                          }
                        },
                        child: Transform.rotate(
                          angle: language == 1 ? 3.1416 : 0,
                          child: Container(
                            height: MediaQuery.of(context).size.width * 5 / 100,
                            width: MediaQuery.of(context).size.width * 5 / 100,
                            child: Image.asset(
                              AppImage.navigateBackIcon,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        // color: Colors.red,
                        height: MediaQuery.of(context).size.width * 4 / 100,
                        width: MediaQuery.of(context).size.width * 5 / 100,
                      ),
                      Container(
                        // color: Colors.red,
                        width: MediaQuery.of(context).size.width * 20 / 100,
                        child: Text(AppLanguage.addOnText[language],
                            style: const TextStyle(
                                color: AppColor.primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFont.fontFamily)),
                      ),
                      Container(
                        // color: Colors.red,
                        alignment: Alignment.center,
                        width: MediaQuery.of(context).size.width * 30 / 100,
                        child: Text("(${mainIndex + 1}/${addOnsList.length})",
                            style: TextStyle(
                                color: AppColor.primaryColor,
                                fontSize: screenWidth > 600 ? 20 : 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFont.fontFamily)),
                      ),
                      Container(
                        // color: Colors.red,
                        height: MediaQuery.of(context).size.width * 5 / 100,
                        width: MediaQuery.of(context).size.width * 30 / 100,
                      ),
                    ],
                  ),
                ),
                Container(
                  color: AppColor.creamColor.withOpacity(0.4),
                  width: MediaQuery.of(context).size.width * 100 / 100,
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tripDetails['boat_name_english'] ?? "",
                                  style: const TextStyle(
                                      color: AppColor.primaryColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: AppFont.fontFamily)),
                              Row(
                                children: [
                                  Text(tripDetails['boat_brand'] ?? "",
                                      style: const TextStyle(
                                          color: AppColor.grayColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: AppFont.fontFamily)),
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
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
                                      width: MediaQuery.of(context).size.width *
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
                                        boatName:
                                            tripDetails['boat_name_english'],
                                        boatBrand: tripDetails['boat_brand'],
                                        toilet:
                                            tripDetails['toilet'].toString(),
                                        cabins:
                                            tripDetails['cabins'].toString(),
                                        capacity: tripDetails['boat_capacity']
                                            .toString(),
                                        size:
                                            tripDetails['boat_size'].toString(),
                                        year:
                                            tripDetails['boat_year'].toString(),
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
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColor.themeColor),
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
                Container(
                  color: AppColor.themeColor.withOpacity(0.20),
                  width: MediaQuery.of(context).size.width * 100 / 100,
                  child: Column(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 100 / 100,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Wrap(
                            spacing: 30,
                            children: List.generate(addOnsList.length, (index) {
                              return Row(
                                children: [
                                  if (index == 0)
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                5 /
                                                100),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              2 /
                                              100),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                18 /
                                                100,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                18 /
                                                100,
                                        child: addOnsList[index]
                                                    ['addon_image'] !=
                                                null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Image.network(
                                                  '${AppConfigProvider.imageURL}${addOnsList[index]['addon_image']}',
                                                  fit: BoxFit.cover,
                                                  loadingBuilder:
                                                      (BuildContext context,
                                                          Widget child,
                                                          ImageChunkEvent?
                                                              loadingProgress) {
                                                    if (loadingProgress ==
                                                        null) {
                                                      return child;
                                                    } else {
                                                      return Shimmer.fromColors(
                                                        baseColor: Colors
                                                            .grey.shade300,
                                                        highlightColor: Colors
                                                            .grey.shade100,
                                                        child: Container(
                                                          color: Colors
                                                              .grey.shade300,
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                              )
                                            : ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Image.asset(
                                                    AppImage.dummyIcon)),
                                      ),
                                      SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              1 /
                                              100),
                                      Text(
                                        addOnsList[index]['addon_name']
                                            [language],
                                        style: TextStyle(
                                            color: mainIndex == index
                                                ? AppColor.themeColor
                                                : AppColor.primaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: AppFont.fontFamily),
                                      )
                                    ],
                                  ),
                                  if (index == addOnsList.length - 1)
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                2 /
                                                100),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 3 / 100),
                    ],
                  ),
                ),
                Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100),
                          Container(
                            width: MediaQuery.of(context).size.width * 90 / 100,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              addOnsList[mainIndex]['addon_name'][language],
                              style: const TextStyle(
                                color: AppColor.primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFont.fontFamily,
                              ),
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100),
                          Container(
                            width: MediaQuery.of(context).size.width * 90 / 100,
                            child: Wrap(
                              runSpacing: 15.0,
                              children: List.generate(
                                  addOnsList[mainIndex]['subAddons'].length,
                                  (index) {
                                return Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              14 /
                                              100,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              14 /
                                              100,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16)),
                                          child: addOnsList[mainIndex]
                                                          ['subAddons'][index]
                                                      ['image'] !=
                                                  null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: Image.network(
                                                    '${AppConfigProvider.imageURL}${addOnsList[mainIndex]['subAddons'][index]['image']}',
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (BuildContext
                                                            context,
                                                        Widget child,
                                                        ImageChunkEvent?
                                                            loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      } else {
                                                        return Shimmer
                                                            .fromColors(
                                                          baseColor: Colors
                                                              .grey.shade300,
                                                          highlightColor: Colors
                                                              .grey.shade100,
                                                          child: Container(
                                                            color: Colors
                                                                .grey.shade300,
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                )
                                              : ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: Image.asset(
                                                    AppImage.imageFrameImage,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                        ),
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              50 /
                                              100,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                addOnsList[mainIndex]
                                                        ['subAddons'][index]
                                                    ['subAddon_name'][language],
                                                style: const TextStyle(
                                                  color: AppColor.primaryColor,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                ),
                                              ),
                                              Text(
                                                "${addOnsList[mainIndex]['subAddons'][index]['price'].toString()} KWD x ${addOnsList[mainIndex]['subAddons'][index]["quantity"].toString()}",
                                                style: const TextStyle(
                                                  color: AppColor.themeColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  if (addOnsList[mainIndex]
                                                              ['subAddons']
                                                          [index]["quantity"] >
                                                      0) {
                                                    addOnsList[mainIndex]
                                                            ['subAddons'][index]
                                                        ["quantity"]--;
                                                  }
                                                  addOnsList[mainIndex]
                                                          ['subAddons'][index]
                                                      ["total_price"] = double.parse(
                                                          addOnsList[mainIndex]
                                                                  ['subAddons'][
                                                              index]["price"]) *
                                                      addOnsList[mainIndex]
                                                              ['subAddons']
                                                          [index]["quantity"];
                                                });

                                                addData(
                                                    addOnsList[mainIndex]
                                                        ["addon_id"],
                                                    addOnsList[mainIndex]
                                                            ['subAddons'][index]
                                                        [
                                                        'addon_subcategory_id'],
                                                    addOnsList[mainIndex]
                                                            ['subAddons'][index]
                                                        ["quantity"],
                                                    double.parse(
                                                        addOnsList[mainIndex]
                                                                ['subAddons']
                                                            [index]["price"]));
                                                getGrandTotal();
                                                showAddData(
                                                    addOnsList[mainIndex]
                                                        ["addon_id"],
                                                    addOnsList[mainIndex]
                                                            ['subAddons'][index][
                                                        'addon_subcategory_id'],
                                                    addOnsList[mainIndex]['subAddons']
                                                        [index]['image'],
                                                    addOnsList[mainIndex]
                                                                ['subAddons'][index]
                                                            ['subAddon_name']
                                                        [language],
                                                    addOnsList[mainIndex]
                                                            ['subAddons'][index]
                                                        ["quantity"],
                                                    double.parse(
                                                        addOnsList[mainIndex]
                                                                ['subAddons']
                                                            [index]["price"]));
                                              },
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    6 /
                                                    100,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    6 /
                                                    100,
                                                child: Image.asset(
                                                    AppImage.minusIcon),
                                              ),
                                            ),
                                            SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    3 /
                                                    100),
                                            Text(
                                              addOnsList[mainIndex]['subAddons']
                                                      [index]['quantity']
                                                  .toString(),
                                              style: const TextStyle(
                                                color: AppColor.primaryColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: AppFont.fontFamily,
                                              ),
                                            ),
                                            SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    3 /
                                                    100),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  addOnsList[mainIndex]
                                                          ['subAddons'][index]
                                                      ["quantity"]++;

                                                  addOnsList[mainIndex]
                                                          ['subAddons'][index]
                                                      ["total_price"] = double.parse(
                                                          addOnsList[mainIndex]
                                                                  ['subAddons'][
                                                              index]["price"]) *
                                                      addOnsList[mainIndex]
                                                              ['subAddons']
                                                          [index]["quantity"];
                                                });
                                                log("addOnsListafasdf${addOnsList[mainIndex]['subAddons'][index]["total_price"].runtimeType}");
                                                addData(
                                                    addOnsList[mainIndex]
                                                        ["addon_id"],
                                                    addOnsList[mainIndex]
                                                            ['subAddons'][index]
                                                        [
                                                        'addon_subcategory_id'],
                                                    addOnsList[mainIndex]
                                                            ['subAddons'][index]
                                                        ["quantity"],
                                                    double.parse(
                                                        addOnsList[mainIndex]
                                                                ['subAddons']
                                                            [index]["price"]));
                                                getGrandTotal();
                                                showAddData(
                                                    addOnsList[mainIndex]
                                                        ["addon_id"],
                                                    addOnsList[mainIndex]
                                                            ['subAddons'][index][
                                                        'addon_subcategory_id'],
                                                    addOnsList[mainIndex]['subAddons']
                                                        [index]['image'],
                                                    addOnsList[mainIndex]
                                                                ['subAddons'][index]
                                                            ['subAddon_name']
                                                        [language],
                                                    addOnsList[mainIndex]
                                                            ['subAddons'][index]
                                                        ["quantity"],
                                                    double.parse(
                                                        addOnsList[mainIndex]
                                                                ['subAddons']
                                                            [index]["price"]));
                                              },
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    6 /
                                                    100,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    6 /
                                                    100,
                                                child: Image.asset(
                                                    AppImage.plusIcon),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                1 /
                                                100),
                                    const Divider(
                                      color: AppColor.grayColor,
                                    )
                                  ],
                                );
                              }),
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100),
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
                                      "$grandTotal KWD",
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
                                Container(
                                  width: MediaQuery.of(context).size.width *
                                      35 /
                                      100,
                                  child: AppButton(
                                    text: mainIndex == addOnsList.length - 1
                                        ? AppLanguage.checkoutText[language]
                                        : AppLanguage.proceedText[language],
                                    onPress: () {
                                      if (mainIndex != addOnsList.length - 1) {
                                        setState(() {
                                          mainIndex++;
                                        });
                                      } else {
                                        resetQuantity();
                                        grandTotal = '0';
                                        setState(() {});
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PublicBookingDetails(
                                              sendSelectedTime:
                                                  widget.sendSelectedTime,
                                              selectedSlotId:
                                                  widget.selectedSlotId,
                                              showDate: widget.showDate,
                                              tripDetails: tripDetails,
                                              date: widget.date,
                                              time: widget.time,
                                              sendAddons: selectedAddons,
                                              selectedAddons:
                                                  showSelectedAddons,
                                              sendTicketsCount:
                                                  widget.sendTicketsCount,
                                              sendSlotIds: widget.sendSlotIds,
                                              allTimeSlots: widget.allTimeSlots,
                                            ),
                                          ),
                                        );
                                      }
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
                    ))
              ],
            ),
          ),
        )),
      ),
    );
  }
}
