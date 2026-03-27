// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../controller/app_config_provider.dart';
import '../../controller/app_image.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../authentication/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../controller/app_button.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_header.dart';
import '../../controller/app_language.dart';
import 'dart:ui' as ui;

class RateNow extends StatefulWidget {
  static String routeName = './RateNow';
  final String tripId;
  final String tripBookingId;
  final String ownerId;

  const RateNow({
    super.key,
    required this.tripId,
    required this.ownerId,
    required this.tripBookingId,
  });

  @override
  State<RateNow> createState() => _RateNowState();
}

class _RateNowState extends State<RateNow> {
  List<dynamic> ratingList = <dynamic>[];
  List<dynamic> finalRatings = <dynamic>[];

  TextEditingController commentTextEditngController = TextEditingController();

  String profileImage = "";
  String fullName = "";
  int userId = 0;
  dynamic userDetails;

  bool isApiCalling = false;

  double timeRating = 0;
  double cleanRating = 0;
  double captainRating = 0;
  double hospitalityRating = 0;

  double totalRating = 0;

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  // --------------------GET USER DETAILS----------------------- //
  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userDetails = prefs.getString("userDetails");

    setState(() => isApiCalling = true);

    if (userDetails != null) {
      dynamic data = json.decode(userDetails);

      userId = data['user_id'];
      profileImage = data["image"] ?? "NA";
      fullName = data["name"] ?? "NA";
    }

    setState(() => isApiCalling = false);
    getAddOnsApiCall(userId);
  }

  // ------------------------Get Add Ons API CALL-------------------------------- //
  Future<void> getAddOnsApiCall(userId) async {
    setState(() => isApiCalling = true);

    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_trip_addon?user_id=$userId&trip_id=${widget.tripBookingId}");

    print("URL: $url");

    String token = AppConstant.token;

    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);

        if (res['success'] == true) {
          var item = res['addone_arr'];
          ratingList = (item != "NA") ? item : [];

          // ⭐ PREFILL MAIN 4 RATINGS
          timeRating = double.parse(res['time'].toString());
          cleanRating = double.parse(res['clean'].toString());
          hospitalityRating = double.parse(res['hospitality'].toString());
          captainRating = double.parse(res['captain'].toString());

          // ⭐ PREFILL REVIEW TEXT
          commentTextEditngController.text =
              (res['review'] != "NA") ? res['review'] : "";

          // ⭐ SET EXISTING AVG RATING
          totalRating = res['total_rating'].toDouble();

          setState(() {});
        } else {
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Login()));
          }
        }
      }
    } catch (e) {
    } finally {
      setState(() => isApiCalling = false);
    }
  }

  //================ Add Rating for Addons ================//
  void addRating(int addOnId, double rating) {
    final index =
        finalRatings.indexWhere((element) => element['addon_id'] == addOnId);

    if (index != -1) {
      finalRatings[index]['rating'] = rating;
    } else {
      finalRatings.add({
        "addon_id": addOnId,
        "rating": rating,
      });
    }

    calculateTotalRating();
  }

  // ⭐⭐⭐================ CALCULATE TOTAL AVERAGE RATING ================⭐⭐⭐//
  void calculateTotalRating() {
    double sum = 0;
    int count = 0;

    // Main 4 ratings
    if (timeRating > 0) {
      sum += timeRating;
      count++;
    }
    if (cleanRating > 0) {
      sum += cleanRating;
      count++;
    }
    if (captainRating > 0) {
      sum += captainRating;
      count++;
    }
    if (hospitalityRating > 0) {
      sum += hospitalityRating;
      count++;
    }

    // Addons ratings
    for (var add in finalRatings) {
      if (add['rating'] > 0) {
        sum += add['rating'];
        count++;
      }
    }

    totalRating =
        (count == 0) ? 0 : double.parse((sum / count).toStringAsFixed(1));

    setState(() {});
  }

  //=============== validation ============//
  validation() {
    calculateTotalRating();

    if (totalRating == 0) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.ratingMsg[language]);
      return;
    }
    addRatingApiCall();
  }

  //==================Add Rating API===================//
  Future<void> addRatingApiCall() async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}add_rating");

    setState(() => isApiCalling = true);

    String token = AppConstant.token;

    try {
      var headers = {'Authorization': 'Bearer $token'};

      var body = {
        'user_id': userId.toString(),
        'trip_id': widget.tripId,
        'total_rating': totalRating.toString(),
        'time': timeRating.toString(),
        'clean': cleanRating.toString(),
        'captain': captainRating.toString(),
        'hospitality': hospitalityRating.toString(),
        'review': commentTextEditngController.text,
        'addon_arr': json.encode(finalRatings),
        "owner_id": widget.ownerId,
        "trip_booking_id": widget.tripBookingId,
      };

      log("$body");

      http.Response response =
          await http.post(url, headers: headers, body: body);

      var res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (res['success'] == true) {
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          Navigator.pop(context);
        } else {
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
        }
      }
    } catch (e) {
    } finally {
      setState(() => isApiCalling = false);
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColor.secondaryColor,
        statusBarIconBrightness: Brightness.dark));

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Directionality(
        textDirection:
            language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Scaffold(
          body: SafeArea(
            child: Container(
              color: AppColor.secondaryColor,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  const NoInternetBanner(),
                  AppHeader(
                    text: AppLanguage.rateNowText[language],
                    onPress: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Profile
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.90,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: (profileImage != "NA")
                                      ? NetworkImage(
                                          '${AppConfigProvider.imageURL}$profileImage')
                                      : const AssetImage(
                                              AppImage.profilePlaceholderImage)
                                          as ImageProvider,
                                ),
                                const SizedBox(width: 10),
                                Text(fullName,
                                    style: const TextStyle(
                                        color: AppColor.primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ⭐ Total Avg Rating Display
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.90,
                            child: Row(
                              children: [
                                Text(AppLanguage.totalRatingsText[language],
                                    style: const TextStyle(
                                        color: AppColor.primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(width: 10),
                                RatingBarIndicator(
                                  rating: totalRating,
                                  itemCount: 5,
                                  itemSize: 24,
                                  unratedColor: Colors.grey.shade400,
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star,
                                    color: AppColor.yellowColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text("($totalRating)",
                                    style: const TextStyle(
                                        color: AppColor.primaryColor,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),
                          divider(),

                          // ⭐ Rating Section
                          ratingSection(context),

                          divider(),

                          // Comment Section
                          commentSection(context),
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

  Widget divider() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.90,
      child: const Divider(color: AppColor.primaryColor),
    );
  }

  // =======================================================
  // ⭐⭐ Rating Fields Section
  // =======================================================
  Widget ratingSection(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${AppLanguage.ratingText[language]}:",
              style: const TextStyle(
                  color: AppColor.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),

          const SizedBox(height: 15),

          // ⭐ PREFILLED MAIN RATINGS
          ratingRow("Time:", (rating) {
            timeRating = rating;
            calculateTotalRating();
          }, initial: timeRating),

          ratingRow("Clean:", (rating) {
            cleanRating = rating;
            calculateTotalRating();
          }, initial: cleanRating),

          ratingRow("Captain:", (rating) {
            captainRating = rating;
            calculateTotalRating();
          }, initial: captainRating),

          ratingRow("Hospitality:", (rating) {
            hospitalityRating = rating;
            calculateTotalRating();
          }, initial: hospitalityRating),

          // Addons Section
          if (ratingList.isNotEmpty)
            Column(
              children: ratingList.map((item) {
                return ratingRow(
                  "${item['addon_name'][language]}:",
                  (rating) => addRating(item['addon_id'], rating),
                  initial: item['addon_rating'].toDouble(),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Single Rating Row Widget
  Widget ratingRow(String label, Function(double) onUpdate,
      {double initial = 0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColor.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          RatingBar.builder(
            unratedColor: Colors.grey.shade400,
            initialRating: initial,
            minRating: 1,
            itemCount: 5,
            itemSize: 22,
            itemPadding: const EdgeInsets.symmetric(horizontal: 3),
            direction: Axis.horizontal,
            itemBuilder: (context, _) =>
                const Icon(Icons.star, color: AppColor.yellowColor),
            onRatingUpdate: onUpdate,
          ),
        ],
      ),
    );
  }

  // =======================================================
  // ⭐⭐ Comments + Submit Section
  // =======================================================
  Widget commentSection(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLanguage.commentsText[language],
              style: const TextStyle(
                  color: AppColor.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextFormField(
            maxLines: 4,
            controller: commentTextEditngController,
            maxLength: AppConstant.describeLength,
            decoration: InputDecoration(
              counterText: '',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: AppLanguage.addCommentText[language],
            ),
          ),
          const SizedBox(height: 30),
          AppButton(
            text: AppLanguage.submitButtonText[language],
            onPress: () => validation(),
          )
        ],
      ),
    );
  }
}
