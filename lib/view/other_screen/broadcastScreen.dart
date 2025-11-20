import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_header.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import 'dart:ui' as ui;

class BroadcastScreen extends StatefulWidget {
  static String routeName = './BroadcastScreen';
  final dynamic broadCastDetails;
  const BroadcastScreen({super.key, this.broadCastDetails});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreen();
}

class _BroadcastScreen extends State<BroadcastScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Directionality(
        textDirection:
            language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Container(
          width: MediaQuery.of(context).size.width * 100 / 100,
          height: MediaQuery.of(context).size.height * 100 / 100,
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 5 / 100,
              ),
              AppHeader(
                  text: AppLanguage.notificationsText[language],
                  onPress: () {
                    Navigator.pop(context);
                  }),
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 2 / 100,
                      ),
                      Container(
                        width: screenWidth * 90 / 100,
                        child: Row(
                          children: [
                            //!===user image====/
                            Container(
                              width: screenWidth * 20 / 100,
                              height: screenWidth * 20 / 100,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: (widget.broadCastDetails['user_image'] !=
                                            null &&
                                        widget.broadCastDetails['user_image'] !=
                                            "NA")
                                    ? Image.network(
                                        '${AppConfigProvider.imageURL}${widget.broadCastDetails['user_image']}',
                                        fit: BoxFit.cover,
                                        loadingBuilder: (BuildContext context,
                                            Widget child,
                                            ImageChunkEvent? loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          } else {
                                            return Shimmer.fromColors(
                                              baseColor: Colors.grey.shade300,
                                              highlightColor:
                                                  Colors.grey.shade100,
                                              child: Container(
                                                color: Colors.grey.shade300,
                                              ),
                                            );
                                          }
                                        },
                                      )
                                    : Image.asset(
                                        AppImage.imageFrame,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            SizedBox(
                              width: screenWidth * 2 / 100,
                            ),

                            //!===user name=====
                            Container(
                              width: screenWidth * 67 / 100,
                              child: Text(
                                widget.broadCastDetails['username'] ?? "",
                                style: const TextStyle(
                                    fontFamily: AppFont.fontFamily,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 2 / 100,
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 90 / 100,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColor.background),
                        child: Column(
                          children: [
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100,
                            ),
                            Container(
                              width:
                                  MediaQuery.of(context).size.width * 85 / 100,
                              child: Text(
                                widget.broadCastDetails['title'][language] ??
                                    "",
                                style: const TextStyle(
                                  fontFamily: AppFont.fontFamily,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.primaryColor,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100,
                            ),
                            Container(
                              width:
                                  MediaQuery.of(context).size.width * 85 / 100,
                              child: Text(
                                widget.broadCastDetails['message'][language] ??
                                    "",
                                style: const TextStyle(
                                    fontFamily: AppFont.fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400),
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100,
                            ),
                            Container(
                              width: screenWidth * 80 / 100,
                              // height: screenWidth * 20 / 100,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: (widget.broadCastDetails['image'] !=
                                            null &&
                                        widget.broadCastDetails['image'] !=
                                            "NA")
                                    ? Image.network(
                                        '${AppConfigProvider.imageURL}${widget.broadCastDetails['image']}',
                                        fit: BoxFit.cover,
                                        loadingBuilder: (BuildContext context,
                                            Widget child,
                                            ImageChunkEvent? loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          } else {
                                            return Shimmer.fromColors(
                                              baseColor: Colors.grey.shade300,
                                              highlightColor:
                                                  Colors.grey.shade100,
                                              child: Container(
                                                color: Colors.grey.shade300,
                                              ),
                                            );
                                          }
                                        },
                                      )
                                    : Image.asset(
                                        AppImage.imageFrame,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 4 / 100,
                      ),
                    ],
                  ),
                ),
              )
              //: Container(),
              ,
              const NoInternetBanner(),
            ],
          ),
        ),
      ),
    );
  }
}
