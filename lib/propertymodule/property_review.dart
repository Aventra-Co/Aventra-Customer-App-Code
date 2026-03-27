import 'package:boatapp/propertymodule/property_rating.dart';
import 'package:boatapp/view/other_screen/booking_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../controller/app_color.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../../controller/app_constant.dart';

class PropertyReview extends StatefulWidget {
  static String routeName = './PropertyReview';

  const PropertyReview({super.key});

  @override
  State<PropertyReview> createState() => _PropertyReviewState();
}

class _PropertyReviewState extends State<PropertyReview> {
  int selectedImageIndex = 0;

  // final List<String> thumbnailImages = [
  //   AppImage.houseIcon,

  // ];

  final List<Map<String, dynamic>> staticReviews = [
    {
      'rating': 5.0,
      'review':
          'The location was fantastic. It was walking distance to many attractions and had great views. The property was clean and well-maintained.',
      'name': 'John Wick',
      'image': AppImage.profilePlaceholderImage,
      'date': '01 Nov 2024',
    },
    {
      'rating': 4.0,
      'review':
          'Very WONDERFUL! Its so incredible. Everything is perfect. We enjoyed it a lot. The property has all the facilities needed for a comfortable stay.',
      'name': 'Jane Cooper',
      'image': AppImage.profilePlaceholderImage,
      'date': '28 Oct 2024',
    },
    {
      'rating': 5.0,
      'review':
          'The apartment is centrally located with easy access to public transport. It is an excellent choice for travelers who want to explore the city.',
      'name': 'Sarah Miller',
      'image': AppImage.profilePlaceholderImage,
      'date': '25 Oct 2024',
    },
  ];

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

    return WillPopScope(
      onWillPop: () {
        // AppConstant.selectFooterIndex = 0;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BookingHistory(
              selectedTab: 1,
            ),
          ),
        );
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: AppColor.secondaryColor,
        appBar: AppBar(
          backgroundColor: AppColor.secondaryColor,
          elevation: 0,
          scrolledUnderElevation: 0, //
          surfaceTintColor: Colors.transparent, //
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: ((context) => BookingHistory(
                          selectedTab: 1,
                        )))),
          ),
          title: Text(
            AppLanguage.reviewText[language],
            style: const TextStyle(
              fontSize: 18,
              fontFamily: AppFont.fontFamily,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: size.width,
                color: const Color(0xFFFFF8F0),
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                  vertical: size.height * 0.02,
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        AppImage.houseIcon,
                        width: size.width * 0.9,
                        height: size.height * 0.20,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PropertyRateNow()));
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 4 / 100,
                            vertical:
                                MediaQuery.of(context).size.height * 0.8 / 100,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E8B87),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Add Review",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.02),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: Column(
                  children: staticReviews.map((review) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: size.height * 0.015),
                      child: Container(
                        padding: EdgeInsets.all(size.width * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              spreadRadius: 2,
                              color: Colors.black.withOpacity(0.08),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            PropertyRateNow()));
                              },
                              child: RatingBarIndicator(
                                rating: review['rating'],
                                itemCount: 5,
                                itemSize: 20,
                                itemBuilder: (context, _) => const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFC107),
                                ),
                              ),
                            ),

                            SizedBox(height: size.height * 0.01),

                            // Review text
                            Text(
                              review['review'],
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: AppFont.fontFamily,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade800,
                                height: 1.4,
                              ),
                            ),

                            SizedBox(height: size.height * 0.015),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Image.asset(
                                        review['image'],
                                        width: size.width * 0.12,
                                        height: size.width * 0.12,
                                        fit: BoxFit.cover,
                                      ),
                                    ),

                                    SizedBox(width: size.width * 0.03),

                                    // Name
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLanguage.reviewByText[language],
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontFamily: AppFont.fontFamily,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          review['name'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontFamily: AppFont.fontFamily,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                // Date
                                Text(
                                  review['date'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: AppFont.fontFamily,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: size.height * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
