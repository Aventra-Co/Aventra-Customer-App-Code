// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../controller/app_config_provider.dart';
import '../../controller/app_image.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../controller/app_button.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_header.dart';
import '../../controller/app_language.dart';

class RateNowProperty extends StatefulWidget {
  static String routeName = './RateNowProperty';
  final int propertyAdId;
  final int propertyBookingId;
  final int ownerId;

  const RateNowProperty({
    super.key,
    required this.propertyAdId,
    required this.ownerId,
    required this.propertyBookingId,
  });

  @override
  State<RateNowProperty> createState() => _RateNowState();
}

class _RateNowState extends State<RateNowProperty> {
  List<dynamic> ratingList = <dynamic>[];
  List<dynamic> finalRatings = <dynamic>[];

  TextEditingController commentTextEditngController = TextEditingController();

  String profileImage = "";
  String fullName = "";
  int userId = 0;
  dynamic userDetails;

  bool isApiCalling = false;

  double arrangmentsRating = 0;
  double cleanRating = 0;

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
  }

  // ⭐⭐⭐================ CALCULATE TOTAL AVERAGE RATING ================⭐⭐⭐//
  void calculateTotalRating() {
    double sum = 0;
    int count = 0;

    // Main 4 ratings
    if (arrangmentsRating > 0) {
      sum += arrangmentsRating;
      count++;
    }
    if (cleanRating > 0) {
      sum += cleanRating;
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
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}add_property_rating");

    setState(() => isApiCalling = true);

    String token = AppConstant.token;

    try {
      var headers = {'Authorization': 'Bearer $token'};

      var body = {
        'user_id': userId.toString(),
        'property_ad_id': widget.propertyAdId.toString(),
        'total_rating': totalRating.toString(),
        'arrangements': arrangmentsRating.toString(),
        'clean': cleanRating.toString(),
        'review': commentTextEditngController.text,
        "owner_id": widget.ownerId.toString(),
        "property_booking_id": widget.propertyBookingId.toString(),
      };

      log("url: $url $body");

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
          ratingRow("${AppLanguage.arrangementsText[language]}:", (rating) {
            arrangmentsRating = rating;
            calculateTotalRating();
          }, initial: arrangmentsRating),

          ratingRow("${AppLanguage.cleanText[language]}:", (rating) {
            cleanRating = rating;
            calculateTotalRating();
          }, initial: cleanRating),
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
