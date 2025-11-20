import 'package:boatapp/controller/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_language.dart';
import 'dart:ui' as ui;

class BoatDetailsScreen extends StatefulWidget {
  static String routeName = './BoatDetailsScreen';
  final String boatName;
  final String boatBrand;
  final String registration;
  final String toilet;
  final String cabins;
  final String capacity;
  final String size;
  final String year;
  const BoatDetailsScreen(
      {super.key,
      required this.boatName,
      required this.boatBrand,
      required this.toilet,
      required this.cabins,
      required this.capacity,
      required this.size,
      required this.year,
      required this.registration});

  @override
  State<BoatDetailsScreen> createState() => BoatDetailsScreenState();
}

class BoatDetailsScreenState extends State<BoatDetailsScreen> {
  bool isApiCalling = false;
  int selectedImageInd = 0;
  String allActivity = "";
  @override
  void initState() {
    super.initState();
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
         statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return Scaffold(
      backgroundColor: AppColor.secondaryColor,
      body: Directionality(
        textDirection:
            language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Container(
          width: MediaQuery.of(context).size.width * 100 / 100,
          height: MediaQuery.of(context).size.height * 100 / 100,
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 4 / 100),
              const NoInternetBanner(),
              AppHeader(
                  text: AppLanguage.boatDetailsText[language],
                  onPress: () {
                    Navigator.pop(context);
                  }),
              Expanded(
                  child: SingleChildScrollView(
                      child: Column(
                children: [
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 2 / 100),

                  // //==================IMAGE CODE=====================//
                  // if (tripImages.isNotEmpty)
                  //   Container(
                  //     width: MediaQuery.of(context).size.width * 90 / 100,
                  //     height: screenWidth > 600
                  //         ? MediaQuery.of(context).size.height * 30 / 100
                  //         : MediaQuery.of(context).size.height * 20 / 100,
                  //     child: ClipRRect(
                  //       borderRadius: BorderRadius.circular(10),
                  //       child: Image.network(
                  //         '${AppConfigProvider.imageURL}${tripImages[selectedImageInd]['image']}',
                  //         fit: BoxFit.cover,
                  //         loadingBuilder: (BuildContext context, Widget child,
                  //             ImageChunkEvent? loadingProgress) {
                  //           if (loadingProgress == null) {
                  //             return child;
                  //           } else {
                  //             return Shimmer.fromColors(
                  //               baseColor: Colors.grey.shade300,
                  //               highlightColor: Colors.grey.shade100,
                  //               child: Container(
                  //                 color: Colors.grey.shade300,
                  //               ),
                  //             );
                  //           }
                  //         },
                  //       ),
                  //     ),
                  //   ),
                  // SizedBox(
                  //     height: MediaQuery.of(context).size.height * 2 / 100),

                  //list
                  // Container(
                  //   alignment: Alignment.center,
                  //   width: MediaQuery.of(context).size.width * 100 / 100,
                  //   child: SingleChildScrollView(
                  //     scrollDirection: Axis.horizontal,
                  //     child: Padding(
                  //       padding: EdgeInsets.only(
                  //           left: screenWidth > 600 ? 38 : 20.0),
                  //       child: Row(
                  //         mainAxisAlignment: MainAxisAlignment.start,
                  //         children: List.generate(tripImages.length, (index) {
                  //           return Padding(
                  //             padding: const EdgeInsets.only(right: 12.0),
                  //             child: Column(
                  //               children: [
                  //                 GestureDetector(
                  //                   onTap: () {
                  //                     setState(() {
                  //                       selectedImageInd = index;
                  //                     });
                  //                   },
                  //                   child: Container(
                  //                     width: screenWidth > 600
                  //                         ? MediaQuery.of(context).size.width *
                  //                             15 /
                  //                             100
                  //                         : MediaQuery.of(context).size.width *
                  //                             15 /
                  //                             100,
                  //                     height: screenWidth > 600
                  //                         ? MediaQuery.of(context).size.width *
                  //                             15 /
                  //                             100
                  //                         : MediaQuery.of(context).size.width *
                  //                             15 /
                  //                             100,
                  //                     child: ClipRRect(
                  //                       borderRadius: BorderRadius.circular(20),
                  //                       child: Image.network(
                  //                         '${AppConfigProvider.imageURL}${tripImages[index]['image']}',
                  //                         fit: BoxFit.cover,
                  //                         loadingBuilder: (BuildContext context,
                  //                             Widget child,
                  //                             ImageChunkEvent?
                  //                                 loadingProgress) {
                  //                           if (loadingProgress == null) {
                  //                             return child;
                  //                           } else {
                  //                             return Shimmer.fromColors(
                  //                               baseColor: Colors.grey.shade300,
                  //                               highlightColor:
                  //                                   Colors.grey.shade100,
                  //                               child: Container(
                  //                                 color: Colors.grey.shade300,
                  //                               ),
                  //                             );
                  //                           }
                  //                         },
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //           );
                  //         }),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // SizedBox(
                  //     height: MediaQuery.of(context).size.height * 2 / 100),

                  Column(
                    children: [
                      textTile(
                          AppLanguage.boatNameText[language], widget.boatName),
                      textTile(
                          AppLanguage.boatBrand[language], widget.boatBrand),
                      textTile(AppLanguage.registationText[language],
                          widget.registration),
                      textTile(
                          AppLanguage.capacityText[language], widget.capacity),
                      textTile(AppLanguage.toiletText[language], widget.toilet),
                      textTile(AppLanguage.cabinsText[language], widget.cabins),
                      textTile(AppLanguage.sizeText[language], widget.size),
                      textTile(AppLanguage.yearText[language], widget.year),
                    ],
                  )
                ],
              )))
            ],
          ),
        ),
      ),
    );
  }

  textTile(leftText, rightText) {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 90 / 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 47 / 100,
                child: Text(
                  "$leftText:",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColor.primaryColor,
                    fontFamily: AppFont.fontFamily,
                  ),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width * 41 / 100,
                child: Text(
                  rightText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColor.primaryColor,
                    fontFamily: AppFont.fontFamily,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 2 / 100),
      ],
    );
  }
}
