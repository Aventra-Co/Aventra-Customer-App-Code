// ignore_for_file: prefer_const_literals_to_create_immutables
import 'dart:developer';
import 'package:boatapp/view/other_screen/publicBookingFlow/public_redirection_trip_details.dart';
import 'package:boatapp/view/property_screens/redirection_property_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import '../main.dart';
import '../view/bottom_navigation/explore_screen.dart';
import '../view/bottom_navigation/inbox_screen.dart';
import '../view/bottom_navigation/bookings.dart';
import '../view/bottom_navigation/profile_screen.dart';
import '../view/bottom_navigation/favourites.dart';
import '../view/other_screen/privateBookingFlow/private_redirection_trip_details.dart';
import 'app_color.dart';
import 'app_constant.dart';
import 'app_font.dart';
import 'app_image.dart';
import 'app_language.dart';
import 'dart:ui' as ui;

class MyFooterPage extends StatefulWidget {
  final int selectedTab;
  const MyFooterPage({Key? key, this.selectedTab = 0}) : super(key: key);

  @override
  _MyFooterPageState createState() => _MyFooterPageState();
}

class _MyFooterPageState extends State<MyFooterPage> {
  int _selectedIndex = 0;
  PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedTab;
    _pageController = PageController(initialPage: widget.selectedTab);
    initUniLinks();
    _pageController =
        PageController(initialPage: AppConstant.selectFooterIndex);

    setState(() {
      _selectedIndex = AppConstant.selectFooterIndex;
    });

    print("select Footer Index ${AppConstant.selectFooterIndex}");
    print("_selectedIndex $_selectedIndex");
  }

  String? lastProcessedLink; // Store the last processed deep link

  Future<void> initUniLinks() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String? initialLink = await getInitialLink();
      String? savedLink = prefs.getString('deep_link');

      if (initialLink != null && initialLink != savedLink) {
        await prefs.setString('deep_link', initialLink); // Save deep link
        handleDeepLink(Uri.parse(initialLink));

        // Clear deep link after use
        Future.delayed(Duration(seconds: 1), () async {
          await prefs.remove('deep_link');
        });
      }

      uriLinkStream.listen((Uri? uri) async {
        if (uri != null && uri.toString() != savedLink) {
          await prefs.setString('deep_link', uri.toString());
          handleDeepLink(uri);

          // Clear deep link after use
          Future.delayed(Duration(seconds: 1), () async {
            await prefs.remove('deep_link');
          });
        }
      });
    } on PlatformException {
      print("PlatformException occurred");
    }
  }

  void handleDeepLink(Uri uri) {
    print("Received Deep Link: $uri");

    final pathSegments = uri.pathSegments;
    log("pathsegments $pathSegments");
    String postId = pathSegments[0].toString(); // Extract the post ID
    int advertisementType = int.parse(pathSegments[2]); // Extract the post ID
    int entityType = int.parse(pathSegments[2]); // Extract the post ID
    log("Post ID: $postId");
    log("Workingadfadfad");
    log("Entity Typw $entityType");
    // Wait for UI to be ready before navigating

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (entityType == 1) {
        log("not entering");
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => RedirectionPropertyDetailsScreen(
                propertyAdId: int.parse(postId)),
          ),
        );
      } else {
        if (advertisementType == 0) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) =>
                  PrivateRedirectionTripDetails(tripId: postId),
            ),
          );
        } else {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) =>
                  PublicRedirectionTripDetails(tripId: postId),
            ),
          );
        }
      }

      // Reset deep link after navigation
      Future.delayed(const Duration(seconds: 1), () {
        lastProcessedLink = null;
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: <Widget>[
          const Explore(),
          MyTrip(selectedTab: widget.selectedTab),
          const Inbox(),
          const Favourites(),
          const Profile()
        ],
      ),
      bottomNavigationBar: Directionality(
        textDirection:
            language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Stack(
          children: [
            BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                // 0
                BottomNavigationBarItem(
                  icon: Column(
                    children: [
                      _selectedIndex == 0
                          ? Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              height: 3,
                              width: 60,
                              color: AppColor.themeColor,
                            )
                          : Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              height: 3,
                              width: 60,
                              color: AppColor.secondaryColor.withOpacity(0.1),
                            ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 1 / 100),
                      Container(
                        height: screenWidth > 600
                            ? MediaQuery.of(context).size.width * 5 / 100
                            : MediaQuery.of(context).size.width * 7 / 100,
                        width: screenWidth > 600
                            ? MediaQuery.of(context).size.width * 5 / 100
                            : MediaQuery.of(context).size.width * 7 / 100,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(_selectedIndex == 0
                                ? AppImage.activeExploreIcon
                                : AppImage.deactiveExploreIcon),
                          ),
                        ),
                      ),
                      SizedBox(
                          height:
                              MediaQuery.of(context).size.height * 0.7 / 100),
                      Text(
                        AppLanguage.exploreText[language],
                        style: TextStyle(
                          fontFamily: AppFont.fontFamily,
                          fontSize: screenWidth > 600 ? 16 : 11,
                          color: _selectedIndex == 0
                              ? AppColor.themeColor
                              : AppColor.textinputBorderColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                          height:
                              MediaQuery.of(context).size.height * 1.5 / 100),
                    ],
                  ),
                  label: "",
                  backgroundColor: AppColor.secondaryColor,
                ),

                // 1
                BottomNavigationBarItem(
                  icon: Column(
                    children: [
                      _selectedIndex == 1
                          ? Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              height: 3,
                              width: 60,
                              color: AppColor.themeColor,
                            )
                          : Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              height: 3,
                              width: 60,
                              color: AppColor.secondaryColor.withOpacity(0.1),
                            ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 1 / 100),
                      Container(
                        height: screenWidth > 600
                            ? MediaQuery.of(context).size.width * 5 / 100
                            : MediaQuery.of(context).size.width * 7 / 100,
                        width: screenWidth > 600
                            ? MediaQuery.of(context).size.width * 5 / 100
                            : MediaQuery.of(context).size.width * 7 / 100,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(_selectedIndex == 1
                                ? AppImage.activebookingIcon
                                : AppImage.bookingIcon),
                          ),
                        ),
                      ),
                      SizedBox(
                          height:
                              MediaQuery.of(context).size.height * 0.7 / 100),
                      Text(
                        AppLanguage.bookingsText[language],
                        style: TextStyle(
                          fontFamily: AppFont.fontFamily,
                          fontSize: screenWidth > 600 ? 16 : 11,
                          color: _selectedIndex == 1
                              ? AppColor.themeColor
                              : AppColor.textinputBorderColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                          height:
                              MediaQuery.of(context).size.height * 1.5 / 100),
                    ],
                  ),
                  label: "",
                  backgroundColor: AppColor.secondaryColor,
                ),

                // 2
                BottomNavigationBarItem(
                  icon: Column(
                    children: [
                      _selectedIndex == 2
                          ? Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              height: 3,
                              width: 60,
                              color: AppColor.themeColor,
                            )
                          : Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              height: 3,
                              width: 60,
                              color: AppColor.secondaryColor.withOpacity(0.1),
                            ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 1 / 100),
                      Container(
                        height: screenWidth > 600
                            ? MediaQuery.of(context).size.width * 5 / 100
                            : MediaQuery.of(context).size.width * 7 / 100,
                        width: screenWidth > 600
                            ? MediaQuery.of(context).size.width * 5 / 100
                            : MediaQuery.of(context).size.width * 7 / 100,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(_selectedIndex == 2
                                ? AppImage.activeInboxIcon
                                : AppImage.deactiveInboxIcon),
                          ),
                        ),
                      ),
                      SizedBox(
                          height:
                              MediaQuery.of(context).size.height * 0.7 / 100),
                      Text(
                        AppLanguage.inboxText[language],
                        style: TextStyle(
                          fontFamily: AppFont.fontFamily,
                          fontSize: screenWidth > 600 ? 16 : 11,
                          color: _selectedIndex == 2
                              ? AppColor.themeColor
                              : AppColor.textinputBorderColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                          height:
                              MediaQuery.of(context).size.height * 1.5 / 100),
                    ],
                  ),
                  label: "",
                  backgroundColor: AppColor.secondaryColor,
                ),

                // 3
                BottomNavigationBarItem(
                  icon: Column(
                    children: [
                      _selectedIndex == 3
                          ? Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              height: 3,
                              width: 60,
                              color: AppColor.themeColor,
                            )
                          : Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              height: 3,
                              width: 60,
                              color: AppColor.secondaryColor.withOpacity(0.1),
                            ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 1 / 100),
                      Container(
                        height: screenWidth > 600
                            ? MediaQuery.of(context).size.width * 5 / 100
                            : MediaQuery.of(context).size.width * 7 / 100,
                        width: screenWidth > 600
                            ? MediaQuery.of(context).size.width * 5 / 100
                            : MediaQuery.of(context).size.width * 7 / 100,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(_selectedIndex == 3
                                ? AppImage.activeFevouriteIcon
                                : AppImage.deactiveFevouriteIcon),
                          ),
                        ),
                      ),
                      SizedBox(
                          height:
                              MediaQuery.of(context).size.height * 0.7 / 100),
                      Text(
                        AppLanguage.favouritesText[language],
                        style: TextStyle(
                          fontFamily: AppFont.fontFamily,
                          fontSize: screenWidth > 600 ? 16 : 11,
                          color: _selectedIndex == 3
                              ? AppColor.themeColor
                              : AppColor.textinputBorderColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                          height:
                              MediaQuery.of(context).size.height * 1.5 / 100),
                    ],
                  ),
                  label: "",
                  backgroundColor: AppColor.secondaryColor,
                ),

                // 4
                BottomNavigationBarItem(
                  icon: Column(
                    children: [
                      _selectedIndex == 4
                          ? Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              height: 3,
                              width: 60,
                              color: AppColor.themeColor,
                            )
                          : Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              height: 3,
                              width: 60,
                              color: AppColor.secondaryColor.withOpacity(0.1),
                            ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 1 / 100),
                      Container(
                        height: screenWidth > 600
                            ? MediaQuery.of(context).size.width * 5 / 100
                            : MediaQuery.of(context).size.width * 7 / 100,
                        width: screenWidth > 600
                            ? MediaQuery.of(context).size.width * 5 / 100
                            : MediaQuery.of(context).size.width * 7 / 100,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(_selectedIndex == 4
                                ? AppImage.activeCaptainIcon
                                : AppImage.deactiveCaptainIcon),
                          ),
                        ),
                      ),
                      SizedBox(
                          height:
                              MediaQuery.of(context).size.height * 0.7 / 100),
                      Text(
                        AppLanguage.profileText[language],
                        style: TextStyle(
                          fontFamily: AppFont.fontFamily,
                          fontSize: screenWidth > 600 ? 16 : 11,
                          color: _selectedIndex == 4
                              ? AppColor.themeColor
                              : AppColor.textinputBorderColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                          height:
                              MediaQuery.of(context).size.height * 1.5 / 100),
                    ],
                  ),
                  label: "",
                  backgroundColor: AppColor.secondaryColor,
                ),
              ],
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              iconSize: 27,
              onTap: _onItemTapped,
              selectedFontSize: 0,
              unselectedFontSize: 0,
              elevation: 7,
            ),
            Positioned(
              top: 0,
              child: Container(
                width: MediaQuery.of(context).size.width * 100 / 100,
                height: MediaQuery.of(context).size.height * 0.2 / 100,
                decoration: BoxDecoration(
                    color: AppColor.secondaryColor.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        spreadRadius: 2,
                        blurRadius: 7,
                        color: AppColor.textColor.withOpacity(0.1),
                      )
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
