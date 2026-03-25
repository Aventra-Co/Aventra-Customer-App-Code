import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_header.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../authentication/login_screen.dart';
// import 'rate_now.dart';

class Review extends StatefulWidget {
  static String routeName = './Review';
  final String tripId;
  final List tripImages;
  final bool isProperty;
  const Review(
      {super.key,
      required this.tripId,
      required this.tripImages,
      required this.isProperty});

  @override
  State<Review> createState() => _ReviewState();
}

class _ReviewState extends State<Review> {
  List<dynamic> reviewList = [];
  int selectedImageInd = 0;

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  int userId = 0;
  int boatId = 0;
  dynamic userDetails;
  dynamic tripDetails = {};
  bool isApiCalling = true;

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
    if (widget.isProperty) {
      getAllPropReviewsApiCall(userId);
    } else {
      getAllReviewsApiCall(userId);
    }
    setState(() {});
  }

  Future<void> getAllReviewsApiCall(userId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_all_ratings_user?user_id=$userId&trip_id=${widget.tripId}");
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
          var item = res['rating_array'];
          reviewList = (item != "NA") ? item : [];

          setState(() {
            isApiCalling = false;
          });
        } else {
          reviewList = [];
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
        reviewList = [];
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (e) {
      reviewList = [];
      setState(() {
        isApiCalling = false;
      });
    }
  }

  Future<void> getAllPropReviewsApiCall(userId) async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_all_ratings_property?user_id=$userId&property_ad_id=${widget.tripId}");
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
          var item = res['rating_array'];
          reviewList = (item != "NA") ? item : [];

          setState(() {
            isApiCalling = false;
          });
        } else {
          reviewList = [];
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
        reviewList = [];
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (e) {
      reviewList = [];
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
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return Scaffold(
      backgroundColor: AppColor.secondaryColor,
      body: SafeArea(
          child: Container(
        color: AppColor.secondaryColor,
        width: MediaQuery.of(context).size.width * 100 / 100,
        height: MediaQuery.of(context).size.height * 100 / 100,
        child: Column(
          children: [
            const NoInternetBanner(),
            AppHeader(
              text: AppLanguage.reviewText[language],
              onPress: () {
                Navigator.pop(context);
              },
            ),
            Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 100 / 100,
                        // height: MediaQuery.of(context).size.height *  / 100,
                        alignment: Alignment.center,
                        decoration:
                            const BoxDecoration(color: AppColor.creamColor),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          // crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: screenHeight * 2 / 100,
                            ),
                            //==================IMAGE CODE=====================//
                            if (widget.tripImages.isNotEmpty &&
                                !widget.isProperty) ...[
                              SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                // alignment: Alignment.center,
                                height: screenWidth > 600
                                    ? MediaQuery.of(context).size.height *
                                        30 /
                                        100
                                    : MediaQuery.of(context).size.height *
                                        20 /
                                        100,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    '${AppConfigProvider.imageURL}${widget.tripImages[selectedImageInd]['image']}',
                                    fit: BoxFit.cover,
                                    loadingBuilder: (BuildContext context,
                                        Widget child,
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
                                ),
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      2 /
                                      100),

                              //list
                              Container(
                                alignment: Alignment.center,
                                width: MediaQuery.of(context).size.width *
                                    100 /
                                    100,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        left: screenWidth > 600 ? 38 : 20.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: List.generate(
                                          widget.tripImages.length, (index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              right: 12.0),
                                          child: Column(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    selectedImageInd = index;
                                                  });
                                                },
                                                child: SizedBox(
                                                  width: screenWidth > 600
                                                      ? MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          15 /
                                                          100
                                                      : MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          15 /
                                                          100,
                                                  height: screenWidth > 600
                                                      ? MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          15 /
                                                          100
                                                      : MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          15 /
                                                          100,
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    child: Image.network(
                                                      '${AppConfigProvider.imageURL}${widget.tripImages[index]['image']}',
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
                                                            highlightColor:
                                                                Colors.grey
                                                                    .shade100,
                                                            child: Container(
                                                              color: Colors.grey
                                                                  .shade300,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      2 /
                                      100),
                            ],
                            //==================IMAGE CODE=====================//
                            if (widget.tripImages.isNotEmpty &&
                                widget.isProperty) ...[
                              SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                // alignment: Alignment.center,
                                height: screenWidth > 600
                                    ? MediaQuery.of(context).size.height *
                                        30 /
                                        100
                                    : MediaQuery.of(context).size.height *
                                        20 /
                                        100,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    '${AppConfigProvider.imageURL}${widget.tripImages[selectedImageInd]['image_path']}',
                                    fit: BoxFit.cover,
                                    loadingBuilder: (BuildContext context,
                                        Widget child,
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
                                ),
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      2 /
                                      100),

                              //list
                              Container(
                                alignment: Alignment.center,
                                width: MediaQuery.of(context).size.width *
                                    100 /
                                    100,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        left: screenWidth > 600 ? 38 : 20.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: List.generate(
                                          widget.tripImages.length, (index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              right: 12.0),
                                          child: Column(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    selectedImageInd = index;
                                                  });
                                                },
                                                child: SizedBox(
                                                  width: screenWidth > 600
                                                      ? MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          15 /
                                                          100
                                                      : MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          15 /
                                                          100,
                                                  height: screenWidth > 600
                                                      ? MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          15 /
                                                          100
                                                      : MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          15 /
                                                          100,
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    child: Image.network(
                                                      '${AppConfigProvider.imageURL}${widget.tripImages[index]['image_path']}',
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
                                                            highlightColor:
                                                                Colors.grey
                                                                    .shade100,
                                                            child: Container(
                                                              color: Colors.grey
                                                                  .shade300,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      2 /
                                      100),
                            ]
                          ],
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 2 / 100),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 90 / 100,
                        child: Wrap(
                          runSpacing: 15.0,
                          children: List.generate(reviewList.length, (index) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 7, horizontal: 9),
                              decoration: BoxDecoration(
                                  color: AppColor.secondaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                        blurRadius: 7,
                                        spreadRadius: 3,
                                        color: AppColor.shadowColor
                                            .withOpacity(0.3))
                                  ]),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RatingBarIndicator(
                                    rating: reviewList[index]['total_rating']
                                        .toDouble(),
                                    itemCount: 5,
                                    itemSize: 25,
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: AppColor.yellowColor,
                                    ),
                                  ),
                                  Text(
                                    reviewList[index]['review'],
                                    style: const TextStyle(
                                        color: AppColor.primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: AppFont.fontFamily),
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              1 /
                                              100),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          if (!widget.isProperty)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              child: SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    12 /
                                                    100,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    12 /
                                                    100,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: reviewList[index]
                                                              ['image'] !=
                                                          null
                                                      ? Image.network(
                                                          '${AppConfigProvider.imageURL}${reviewList[index]['image']}',
                                                          fit: BoxFit.cover,
                                                          loadingBuilder:
                                                              (BuildContext
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
                                                                    .grey
                                                                    .shade300,
                                                                highlightColor:
                                                                    Colors.grey
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
                                                          AppImage
                                                              .profilePlaceholderImage,
                                                          fit: BoxFit.cover,
                                                        ),
                                                ),
                                              ),
                                            ),
                                          if (widget.isProperty)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              child: SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    12 /
                                                    100,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    12 /
                                                    100,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: reviewList[index]
                                                              ['image_path'] !=
                                                          null
                                                      ? Image.network(
                                                          '${AppConfigProvider.imageURL}${reviewList[index]['image_path']}',
                                                          fit: BoxFit.cover,
                                                          loadingBuilder:
                                                              (BuildContext
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
                                                                    .grey
                                                                    .shade300,
                                                                highlightColor:
                                                                    Colors.grey
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
                                                          AppImage
                                                              .profilePlaceholderImage,
                                                          fit: BoxFit.cover,
                                                        ),
                                                ),
                                              ),
                                            ),
                                          SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  2 /
                                                  100),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppLanguage
                                                    .reviewByText[language],
                                                style: const TextStyle(
                                                    color:
                                                        AppColor.primaryColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w400,
                                                    fontFamily:
                                                        AppFont.fontFamily),
                                              ),
                                              Text(
                                                reviewList[index]['name'],
                                                style: const TextStyle(
                                                    color:
                                                        AppColor.primaryColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily:
                                                        AppFont.fontFamily),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Text(
                                        reviewList[index]['createtime'],
                                        style: const TextStyle(
                                            color: AppColor.primaryColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: AppFont.fontFamily),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 2 / 100)
                    ],
                  ),
                ))
          ],
        ),
      )),
    );
  }
}
