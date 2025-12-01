// ignore_for_file: sized_box_for_whitespace

import 'dart:convert';
import 'dart:developer';
import 'package:boatapp/controller/app_footer.dart';
import 'package:boatapp/view/other_screen/change_language_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../AdminChat/admin_chat.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_snack_bar_toast_message.dart';
// import '/view/other_screen/help_support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../../controller/route_observer.dart';
import '../authentication/change_password_screen.dart';
import '../authentication/deleteAccount_screen.dart';
import '../authentication/edit_profile_screen.dart';
import '../authentication/login_screen.dart';
import '../content_screen/content_screen.dart';
import '../other_screen/booking_history_screen.dart';
import '../other_screen/faq_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;

class Profile extends StatefulWidget {
  static String routeName = "./Profile";
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with RouteAware {
  List<dynamic> languageList = [
    {"id": 0, "name": "English"},
    {"id": 1, "name": "Arabic"},
    // {"languageId": 3, "name": "French"},
    // {"languageId": 4, "name": "Italian"},
    // {"languageId": 5, "name": "Korean"},
  ];
  String languageName = "";
  dynamic languageId;
  bool isApiCalling = false;
  int userId = 0;
  String fullName = "";
  String email = "";
  dynamic userDetails;
  dynamic userDataArr;
  String shareWith = "";
  String termsandconditionstype = "";
  String privacypolicytype = "";
  String aboutustype = "";
  String rateappurl = "";
  String profileImage = "";
  String vendorId = '';
  int loginType = 0;
  var fileName = 'NA';

  @override
  void initState() {
    super.initState();
    getUserDetails();
    getAllContent();
  }

  //----------------------------GET USER DETAILS--------------------------------//
  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userDetails = prefs.getString("userDetails");
    languageId = prefs.getString("language_id");
    if (languageId != null) {
      languageId = int.parse(languageId);
      if (languageId == 0) {
        languageName = "English";
      } else {
        languageName = "Arabic";
      }
    } else {
      languageId = 0;
      languageName = "English";
    }
    if (isGuest) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Login()));
      return;
    }
    // print("userDetails $userDetails");
    if (userDetails == null) {
      // print("worked");
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.notRegisteredMsg[language]);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Login()));
    } else {
      userDataArr = jsonDecode(userDetails);
      userId = userDataArr['user_id'] ?? 0;
      fullName = userDataArr['name'] ?? "";
      profileImage = userDataArr["image"] ?? "NA";
      vendorId = userDataArr["languageId"] ?? "NA";
      loginType = userDataArr['login_type'] ?? "";
    }

    // print("userDataArr $userDataArr");
    isApiCalling = false;
    setState(() {});
  }

//-----------------Sign Out-----------------------
  localstorageclearbutton() async {
    final prefs = await SharedPreferences.getInstance();
    print("prefs =================>$prefs");
    prefs.remove('userDetails');
    prefs.remove('password');

    log("Worked");

    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (context) => const Login(),
      ),
    );
  }

//-----------------GET CONTENT API CALL-----------------//
  Future<void> getAllContent() async {
    Uri url = Uri.parse(
        '${AppConfigProvider.apiUrl}get_all_content?language_id=$language');
    print("url $url");

    try {
      final response = await http.get(
        url,
      );

      dynamic res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // print("res $res");
        if (res['success'] == true) {
          setState(() {
            isApiCalling = false;
          });
          List data = res['content_arr'];
          for (var i = 0; i < data.length; i++) {
            if (data[i]['content_type'] == 5) {
              setState(() {
                shareWith = data[i]['content_english'];
              });
              print("share app ${data[i]['content']}");
            }
            if (data[i]['content_type'] == 2) {
              var url1 = data[i]['content_url'];

              setState(() {
                termsandconditionstype = url1;
              });
              print('289 term $termsandconditionstype');
            }

            if (data[i]['content_type'] == 1) {
              var url1 = data[i]['content_url'];

              setState(() {
                privacypolicytype = url1;
              });
              print('289 privacy $privacypolicytype');
            }
            if (data[i]['content_type'] == 0) {
              var url1 = data[i]['content_url'];

              setState(() {
                aboutustype = url1;
              });
              print('289 about $aboutustype');
            }

            if (AppConstant.deviceType == 'android') {
              if (data[i]['content_type'] == 4) {
                var androidurl = data[i]['content_english'];

                setState(() {
                  rateappurl = androidurl;
                });
                print('rateappurl $rateappurl');
              }
            }

            if (AppConstant.deviceType == 'ios') {
              if (data[i]['content_type'] == 3) {
                var iosurl = data[i]['content_english'];

                setState(() {
                  rateappurl = iosurl;
                });
              }
            }
          }
        }
      } else {
        setState(() {
          isApiCalling = false;
        });
        if (res['active_status'] == 0) {
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => const Login()));
        }
      }
    } catch (e) {}
  }

//------------------------SHARE  APP FUNCTION------------------//
  shareApp(BuildContext context) async {
    print("share187 $shareWith");
    var shareUrl = shareWith;

    final RenderBox box = context.findRenderObject() as RenderBox;
    await Share.share(shareUrl,
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
  }

//---------------------------OPEN RATE URL-----------------------//
  Future openUrl({
    required String url,
    bool inApp = false,
  }) async {
    print(url);
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // If not, prepend https:// to the URL
      url = 'https://$url';
    }

    if (await canLaunch(url)) {
      await launch(url,
          forceSafariVC: inApp, forceWebView: inApp, enableJavaScript: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    getAllContent();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    log(screenWidth.toString());
    log(screenHeight.toString());
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColor.transparentColor,
        statusBarIconBrightness: Brightness.dark));
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: WillPopScope(
        onWillPop: () async {
          AppConstant.selectFooterIndex = 0;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyFooterPage(),
            ),
          );
          return false;
        },
        child: Scaffold(
            body: Directionality(
          textDirection:
              language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: Container(
              height: MediaQuery.of(context).size.height * 100 / 100,
              width: MediaQuery.of(context).size.width * 100 / 100,
              color: AppColor.secondaryColor,
              child: Column(
                children: [
                  Container(
                    // color: Colors.red,
                    height: screenWidth > 600
                        ? screenHeight >= 800
                            ? MediaQuery.of(context).size.height * 27 / 100
                            : MediaQuery.of(context).size.height * 35 / 100
                        : MediaQuery.of(context).size.height * 21 / 100,
                    child: Stack(
                      children: [
                        SizedBox(
                          height: AppConstant.deviceType == 'ios'
                              ? MediaQuery.of(context).size.height * 3 / 100
                              : MediaQuery.of(context).size.height * 4 / 100,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 100 / 100,
                          height: MediaQuery.of(context).size.width * 30 / 100,
                          // color: AppColor.borderColor,
                          child: Image.asset(
                            AppImage.profileScreenIcon,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                            top: 35,
                            left: language == 1 ? null : 18,
                            right: language == 1 ? 18 : null,
                            child: Text(
                              AppLanguage.profileText[language],
                              style: const TextStyle(
                                  color: AppColor.secondaryColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: AppFont.fontFamily),
                            )),
                        Positioned(
                          bottom: 0,
                          right: screenWidth > 600
                              ? MediaQuery.of(context).size.width * 38 / 100
                              : MediaQuery.of(context).size.width * 37.8 / 100,
                          child: Container(
                            //margin: EdgeInsets.only(bottom: 100),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                  width: 3, color: AppColor.themeColor),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                width: MediaQuery.of(context).size.width *
                                    22 /
                                    100,
                                height: MediaQuery.of(context).size.width *
                                    22 /
                                    100,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: profileImage != 'NA'
                                    ? Image.network(
                                        "${AppConfigProvider.imageURL}$profileImage",
                                        fit: BoxFit.cover,
                                        loadingBuilder: (BuildContext context,
                                            Widget child,
                                            ImageChunkEvent? loadingProgress) {
                                          if (loadingProgress == null) {
                                            // Image has loaded
                                            return child;
                                          } else {
                                            // Image is still loading, show shimmer
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
                                        AppImage.profilePlaceholderImage,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 1.5 / 100,
                  ),
                  Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width * 90 / 100,
                    child: Text(
                      fullName,
                      style: TextStyle(
                          fontFamily: AppFont.fontFamily,
                          fontSize: screenWidth > 600 ? 20 : 16,
                          fontWeight: FontWeight.w700,
                          color: AppColor.primaryColor),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 1.5 / 100,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 90 / 100,
                        child: Column(
                          children: [
                            Container(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              //height: MediaQuery.of(context).size.height * 27 / 100,
                              padding: const EdgeInsets.symmetric(
                                vertical: 3,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: AppColor.profilebackgorundColor),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1.5 /
                                        100,
                                  ),
                                  PersonalSettingRow(
                                    leadingIcon: AppImage.editProfileIcon,
                                    title:
                                        AppLanguage.editProfileText[language],
                                    onPress: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const EditProfile()));
                                    },
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1.3 /
                                        100,
                                  ),
                                  if (loginType == 0)
                                    Column(
                                      children: [
                                        PersonalSettingRow(
                                          leadingIcon:
                                              AppImage.changePasswordIcon,
                                          title: AppLanguage
                                              .changePasswordText[language],
                                          onPress: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const ChangePassword()));
                                          },
                                        ),
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              1.3 /
                                              100,
                                        ),
                                      ],
                                    ),
                                  PersonalSettingRow(
                                    leadingIcon: AppImage.bookingHistoryIcon,
                                    title: AppLanguage
                                        .bookingHistoryText[language],
                                    onPress: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const BookingHistory()));
                                    },
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1.3 /
                                        100,
                                  ),
                                  PersonalSettingRow(
                                    leadingIcon: AppImage.helpSupportIcon,
                                    title: AppLanguage
                                        .helpAndSupportText[language],
                                    onPress: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => AdminChat(
                                                otherUserId: 1,
                                                otherUserName: "Admin",
                                                deviceToken: AppConstant.token,
                                                chatMetStatus: "yes")),
                                      );
                                    },
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1.3 /
                                        100,
                                  ),
                                  PersonalSettingRow(
                                    leadingIcon: AppImage.helpSupportIcon,
                                    title: AppLanguage.languageText[language],
                                    language: languageName,
                                    onPress: () {
                                      AppConstant.languageNav = 0;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ChangeLanguage(),
                                        ),
                                      );

                                      // languageListBottomSheet(
                                      //     context, screenWidth);
                                    },
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1.3 /
                                        100,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * .1 / 100,
                            ),
                            Container(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              //height: MediaQuery.of(context).size.height * 27 / 100,
                              padding: const EdgeInsets.symmetric(
                                vertical: 3,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: AppColor.profilebackgorundColor),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1.5 /
                                        100,
                                  ),
                                  PersonalSettingRow(
                                    leadingIcon: AppImage.editProfileIcon,
                                    title: AppLanguage.faqText[language],
                                    onPress: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const FAQ()));
                                    },
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1.3 /
                                        100,
                                  ),
                                  PersonalSettingRow(
                                    leadingIcon: AppImage.termsAndConditionIcon,
                                    title: AppLanguage
                                        .termsAndConditionText[language],
                                    onPress: () {
                                      Navigator.pushNamed(
                                          context, Content.routeName,
                                          arguments: ContentClass(
                                              header: AppLanguage
                                                      .termsAndConditionText[
                                                  language],
                                              contenttype:
                                                  termsandconditionstype));
                                    },
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1.3 /
                                        100,
                                  ),
                                  PersonalSettingRow(
                                    leadingIcon: AppImage.privacyPolicyIcon,
                                    title:
                                        AppLanguage.privacyPolicyText[language],
                                    onPress: () {
                                      Navigator.pushNamed(
                                          context, Content.routeName,
                                          arguments: ContentClass(
                                              header: AppLanguage
                                                  .privacyPolicyText[language],
                                              contenttype: privacypolicytype));
                                    },
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1.3 /
                                        100,
                                  ),
                                  PersonalSettingRow(
                                    leadingIcon: AppImage.aboutUsIcon,
                                    title: AppLanguage.aboutUsText[language],
                                    onPress: () {
                                      Navigator.pushNamed(
                                          context, Content.routeName,
                                          arguments: ContentClass(
                                              header: AppLanguage
                                                  .aboutUsText[language],
                                              contenttype: aboutustype));
                                    },
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1.3 /
                                        100,
                                  ),
                                  PersonalSettingRow(
                                    leadingIcon: AppImage.rateAppIcon,
                                    title: AppLanguage.rateAppText[language],
                                    onPress: () {
                                      openUrl(url: rateappurl);
                                    },
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1.3 /
                                        100,
                                  ),
                                  PersonalSettingRow(
                                    leadingIcon: AppImage.shareAppIcon,
                                    title: AppLanguage.shareAppText[language],
                                    onPress: () {
                                      shareApp(context);
                                    },
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1.3 /
                                        100,
                                  ),
                                  PersonalSettingRow(
                                    leadingIcon: AppImage.deleteAccountIcon,
                                    title:
                                        AppLanguage.deleteAccountText[language],
                                    onPress: () {
                                      deleteAccountPopUp(context, screenWidth);
                                    },
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1.3 /
                                        100,
                                  ),
                                  PersonalSettingRow(
                                    leadingIcon: AppImage.logoutIcon,
                                    title: AppLanguage.logOutText[language],
                                    onPress: () {
                                      logOutPopUp(context, screenWidth);
                                    },
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1.3 /
                                        100,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const NoInternetBanner(),
                ],
              )),
        )),
      ),
    );
  }

  //====================language selection bottom sheet====================
  // void languageListBottomSheet(BuildContext context, screenWidth) {
  //   showModalBottomSheet<void>(
  //     context: context,
  //     isScrollControlled: true,
  //     constraints: BoxConstraints.expand(
  //       width: screenWidth,
  //     ),
  //     useRootNavigator: false,
  //     isDismissible: false,
  //     enableDrag: false,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return Scaffold(
  //             body: Container(
  //               height: MediaQuery.of(context).size.height * 100 / 100,
  //               width: MediaQuery.of(context).size.width * 100 / 100,
  //               decoration: const BoxDecoration(
  //                 // color: Colors.white,
  //                 color: AppColor.secondaryColor,
  //               ),
  //               child: Column(
  //                 children: [
  //                   SizedBox(
  //                     height: MediaQuery.of(context).size.height * 6 / 100,
  //                   ),
  //                   Container(
  //                     width: MediaQuery.of(context).size.width * 90 / 100,
  //                     child: Row(
  //                       children: [
  //                         GestureDetector(
  //                           onTap: () {
  //                             Navigator.pop(context);
  //                           },
  //                           child: Container(
  //                             width:
  //                                 MediaQuery.of(context).size.width * 6 / 100,
  //                             height:
  //                                 MediaQuery.of(context).size.width * 6 / 100,
  //                             child: Image.asset(AppImage.backIcon),
  //                           ),
  //                         ),
  //                         SizedBox(
  //                           width: MediaQuery.of(context).size.width * 4 / 100,
  //                         ),
  //                         Text(
  //                           AppLanguage.languageText[language],
  //                           style: const TextStyle(
  //                             color: AppColor.primaryColor,
  //                             fontFamily: AppFont.fontFamily,
  //                             fontWeight: FontWeight.w600,
  //                             fontSize: 18,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   SizedBox(
  //                       height: MediaQuery.of(context).size.height * 3 / 100),
  //                   Expanded(
  //                     child: SingleChildScrollView(
  //                       child: Wrap(children: [
  //                         ...List.generate(
  //                           languageList.length,
  //                           (index) => GestureDetector(
  //                               onTap: () {
  //                                 Navigator.pop(context);
  //                                 selectKey(index, languageList[index]["name"],
  //                                     languageList[index]["id"]);
  //                               },
  //                               child: Container(
  //                                 alignment: Alignment.centerLeft,
  //                                 margin:
  //                                     const EdgeInsets.symmetric(vertical: 3),
  //                                 width: MediaQuery.of(context).size.width *
  //                                     90 /
  //                                     100,
  //                                 child: Column(
  //                                   children: [
  //                                     Row(
  //                                       children: [
  //                                         Row(
  //                                           children: [
  //                                             Container(
  //                                               width: MediaQuery.of(context)
  //                                                       .size
  //                                                       .width *
  //                                                   90 /
  //                                                   100,
  //                                               height: MediaQuery.of(context)
  //                                                       .size
  //                                                       .height *
  //                                                   6 /
  //                                                   100,
  //                                               decoration: BoxDecoration(
  //                                                 border: Border.all(width: .5),
  //                                                 borderRadius:
  //                                                     BorderRadius.circular(5),
  //                                               ),
  //                                               child: Row(
  //                                                 mainAxisAlignment:
  //                                                     MainAxisAlignment.start,
  //                                                 children: [
  //                                                   Container(
  //                                                     width:
  //                                                         MediaQuery.of(context)
  //                                                                 .size
  //                                                                 .width *
  //                                                             40 /
  //                                                             100,
  //                                                     padding:
  //                                                         const EdgeInsets.only(
  //                                                             left: 20),
  //                                                     child: Text(
  //                                                       languageList[index]
  //                                                           ["name"],
  //                                                       style: TextStyle(
  //                                                         color: AppColor
  //                                                             .primaryColor,
  //                                                         fontFamily: AppFont
  //                                                             .fontFamily,
  //                                                         fontSize:
  //                                                             screenWidth > 600
  //                                                                 ? 20
  //                                                                 : 14,
  //                                                         fontWeight:
  //                                                             FontWeight.w500,
  //                                                       ),
  //                                                     ),
  //                                                   ),
  //                                                   SizedBox(
  //                                                     width:
  //                                                         MediaQuery.of(context)
  //                                                                 .size
  //                                                                 .width *
  //                                                             40 /
  //                                                             100,
  //                                                   ),
  //                                                   Container(
  //                                                     width:
  //                                                         MediaQuery.of(context)
  //                                                                 .size
  //                                                                 .width *
  //                                                             5 /
  //                                                             100,
  //                                                     height:
  //                                                         MediaQuery.of(context)
  //                                                                 .size
  //                                                                 .width *
  //                                                             5 /
  //                                                             100,
  //                                                     decoration: BoxDecoration(
  //                                                       border: Border.all(
  //                                                         width: .3,
  //                                                         color: AppColor
  //                                                             .textinputBorderColor,
  //                                                       ),
  //                                                       borderRadius:
  //                                                           BorderRadius
  //                                                               .circular(100),
  //                                                     ),
  //                                                     child: languageList[index]
  //                                                                 ["id"] ==
  //                                                             languageId
  //                                                         ? Image.asset(
  //                                                             AppImage
  //                                                                 .selectLanguage,
  //                                                             fit: BoxFit.fill,
  //                                                           )
  //                                                         : Container(),
  //                                                   ),
  //                                                 ],
  //                                               ),
  //                                             ),
  //                                           ],
  //                                         ),

  //                                         // if (languageList[index]["languageId"] == languageId)
  //                                       ],
  //                                     ),
  //                                     SizedBox(
  //                                       height:
  //                                           MediaQuery.of(context).size.height *
  //                                               1 /
  //                                               100,
  //                                     ),
  //                                   ],
  //                                 ),
  //                               )),
  //                         ),
  //                       ]),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  // selectKey(index, name, languageId) async {
  //   // -----Local Storage ------------
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString("language_id", jsonEncode(languageId));

  //   print("Selected ID: $languageId");
  //   print("Selected Name: $name");

  //   setState(() {
  //     this.languageId = languageId;
  //     languageName = name;
  //     language = languageId;
  //   });
  //   log("gasdgasdg$language");
  // }

  //--------------------delete account bottom sheet--------------
  void deleteAccountPopUp(BuildContext context, screenWidth) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        constraints: BoxConstraints.expand(
          width: screenWidth,
        ),
        backgroundColor: AppColor.primaryColor.withOpacity(0.1),
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 100 / 100,
                height: MediaQuery.of(context).size.height * 100 / 100,
                color: AppColor.primaryColor.withOpacity(0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 80 / 100,
                      //    height: MediaQuery.of(context).size.height * 36 / 100,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 15),
                      decoration: BoxDecoration(
                          color: AppColor.secondaryColor,
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: [
                          Center(
                            child: SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 15 / 100,
                              height:
                                  MediaQuery.of(context).size.width * 15 / 100,
                              child: Image.asset(
                                AppImage.deleteAccountRedIcon,
                                // fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 3 / 100,
                          ),
                          Text(
                            AppLanguage.confirmDeleteText[language],
                            style: const TextStyle(
                                color: AppColor.primaryColor,
                                fontFamily: AppFont.fontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 20),
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * .5 / 100,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 65 / 100,
                            child: Text(
                              AppLanguage.sureDeleteText[language],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColor.textColor,
                                  fontFamily: AppFont.fontFamily,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16),
                            ),
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 3 / 100,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width *
                                      33 /
                                      100,
                                  height: MediaQuery.of(context).size.height *
                                      5 /
                                      100,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColor.lightBlackColor),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    AppLanguage.cancelText[language],
                                    style: const TextStyle(
                                        color: AppColor.primaryColor,
                                        fontFamily: AppFont.fontFamily,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 4 / 100,
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const DeleteAccount()));
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width *
                                      33 /
                                      100,
                                  height: MediaQuery.of(context).size.height *
                                      5 /
                                      100,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: AppColor.blueColor,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    AppLanguage.deleteText[language],
                                    style: const TextStyle(
                                        color: AppColor.secondaryColor,
                                        fontFamily: AppFont.fontFamily,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * .5 / 100,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }

  //==================log out bottom sheet================
  void logOutPopUp(BuildContext context, screenWidth) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        constraints: BoxConstraints.expand(
          width: screenWidth,
        ),
        backgroundColor: AppColor.primaryColor.withOpacity(0.1),
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 100 / 100,
                height: MediaQuery.of(context).size.height * 100 / 100,
                color: AppColor.primaryColor.withOpacity(0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 70 / 100,
                      decoration: BoxDecoration(
                          color: AppColor.secondaryColor,
                          borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        children: [
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 2 / 100,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 60 / 100,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: screenWidth > 600 ? 25.0 : 0),
                              child: Text(
                                AppLanguage.sureLogoutText[language],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColor.lightTextColor,
                                    fontFamily: AppFont.fontFamily,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18),
                              ),
                            ),
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 1 / 100,
                          ),
                          Container(
                            height:
                                MediaQuery.of(context).size.height * .1 / 100,
                            width: MediaQuery.of(context).size.width * 70 / 100,
                            color: AppColor.lightBorderColor,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  width: MediaQuery.of(context).size.width *
                                      34 /
                                      100,
                                  height: screenWidth > 600
                                      ? MediaQuery.of(context).size.height *
                                          6 /
                                          100
                                      : MediaQuery.of(context).size.width *
                                          17 /
                                          100,
                                  alignment: Alignment.center,
                                  child: Text(
                                    AppLanguage.cancelText[language],
                                    style: const TextStyle(
                                        color: AppColor.primaryColor,
                                        fontFamily: AppFont.fontFamily,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16),
                                  ),
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width *
                                    .2 /
                                    100,
                                height: MediaQuery.of(context).size.width *
                                    17 /
                                    100,
                                color: AppColor.lightBorderColor,
                              ),
                              GestureDetector(
                                onTap: () {
                                  localstorageclearbutton();
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  width: MediaQuery.of(context).size.width *
                                      34 /
                                      100,
                                  height: screenWidth > 600
                                      ? MediaQuery.of(context).size.height *
                                          6 /
                                          100
                                      : MediaQuery.of(context).size.width *
                                          17 /
                                          100,
                                  alignment: Alignment.center,
                                  child: Text(
                                    AppLanguage.logOutText[language],
                                    style: const TextStyle(
                                        color: AppColor.primaryColor,
                                        fontFamily: AppFont.fontFamily,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }
}

class PersonalSettingRow extends StatelessWidget {
  const PersonalSettingRow({
    Key? key,
    required this.title,
    required this.leadingIcon,
    required this.onPress,
    this.language,
  }) : super(key: key);

  final String title;
  final String leadingIcon;
  final Function onPress;
  final String? language;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          onPress();
        },
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: MediaQuery.of(context).size.width * 80 / 100,
              height: MediaQuery.of(context).size.height * 3 / 100,
              child: Row(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 6 / 100,
                    height: MediaQuery.of(context).size.width * 6 / 100,
                    child: Image.asset(leadingIcon),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 2 / 100,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 55 / 100,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColor.primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    language ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColor.themeColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
