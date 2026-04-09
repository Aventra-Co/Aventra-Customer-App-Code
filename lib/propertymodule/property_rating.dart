import '/propertymodule/property_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../controller/app_button.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_header.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';

class PropertyRateNow extends StatefulWidget {
  static String routeName = './PropertyRateNow';

  const PropertyRateNow({super.key});

  @override
  State<PropertyRateNow> createState() => _PropertyRateNowState();
}

class _PropertyRateNowState extends State<PropertyRateNow> {
  TextEditingController commentTextEditingController = TextEditingController();

  String profileImage = AppImage.profilePlaceholderImage;
  String fullName = "Mahmoud";

  double timeRating = 4;
  double cleanRating = 5;
  double arrangementRating = 5;
  double totalRating = 4;

  @override
  Widget build(BuildContext context) {
    return _buildUIScreen(context);
  }

  Widget _buildUIScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColor.secondaryColor,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColor.secondaryColor,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              text: AppLanguage.rateNowText[language],
              onPress: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.02),

                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: AssetImage(AppImage.userImage),
                        ),
                        SizedBox(width: size.width * 0.03),
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: size.height * 0.02),

                    // ✅ Total Rating
                    Row(
                      children: [
                        Text(
                          AppLanguage.totalRatingsText[language],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: size.width * 0.03),
                        RatingBarIndicator(
                          rating: totalRating,
                          itemCount: 5,
                          itemSize: 24,
                          unratedColor: Colors.grey.shade400,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Color(0xFFFFE419),
                          ),
                        ),
                        SizedBox(width: size.width * 0.02),
                        Text(
                          "($totalRating)",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: size.height * 0.02),

                    const Divider(color: Colors.black),

                    SizedBox(height: size.height * 0.02),

                    Text(
                      "${AppLanguage.ratingText[language]}:",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: size.height * 0.015),

                    // Clean rating
                    _buildRatingRow("Clean:", cleanRating, (rating) {
                      setState(() {
                        cleanRating = rating;
                        _calculateTotalRating();
                      });
                    }),

                    SizedBox(height: size.height * 0.01),

                    // Arrangement rating
                    _buildRatingRow("Arrangement:", arrangementRating,
                        (rating) {
                      setState(() {
                        arrangementRating = rating;
                        _calculateTotalRating();
                      });
                    }),

                    SizedBox(height: size.height * 0.02),

                    const Divider(color: Colors.black),

                    SizedBox(height: size.height * 0.02),

                    Text(
                      AppLanguage.commentsText[language],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: size.height * 0.01),

                    TextFormField(
                      controller: commentTextEditingController,
                      maxLines: 3,
                      maxLength: AppConstant.describeLength,
                      decoration: InputDecoration(
                        counterText: '',
                        // hintText: AppLanguage.addCommentText[language],
                        // hintStyle: TextStyle(
                        //   fontSize: 14,
                        //   color: Colors.grey.shade500,
                        // ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColor.themeColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.all(size.width * 0.04),
                      ),
                    ),

                    SizedBox(height: size.height * 0.06),

                    AppButton(
                      text: AppLanguage.submitButtonText[language],
                      onPress: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PropertyReview()));
                      },
                    ),

                    SizedBox(height: size.height * 0.03),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(
    String label,
    double currentRating,
    Function(double) onUpdate,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        RatingBar.builder(
          initialRating: currentRating,
          minRating: 0,
          itemCount: 5,
          itemSize: 22,
          unratedColor: Colors.grey.shade400,
          itemPadding: const EdgeInsets.symmetric(horizontal: 2),
          itemBuilder: (context, _) => const Icon(
            Icons.star,
            color: Color(0xFFFFE419),
          ),
          onRatingUpdate: onUpdate,
        ),
      ],
    );
  }

  void _calculateTotalRating() {
    int count = 0;
    double sum = 0;

    if (timeRating > 0) {
      sum += timeRating;
      count++;
    }
    if (cleanRating > 0) {
      sum += cleanRating;
      count++;
    }
    if (arrangementRating > 0) {
      sum += arrangementRating;
      count++;
    }

    setState(() {
      totalRating =
          count > 0 ? double.parse((sum / count).toStringAsFixed(1)) : 0;
    });
  }

  @override
  void dispose() {
    commentTextEditingController.dispose();
    super.dispose();
  }
}
