import 'dart:convert';
import 'dart:developer';
import 'package:boatapp/controller/app_footer.dart';
import 'package:boatapp/view/authentication/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../../controller/app_loader.dart';
import 'dart:ui' as ui;

class ChangeLanguage extends StatefulWidget {
  static String routeName = "./ChangeLanguage";
  const ChangeLanguage({super.key});

  @override
  State<ChangeLanguage> createState() => ChangePasswordState();
}

class ChangePasswordState extends State<ChangeLanguage> {
  dynamic userDetails;
  dynamic userDataArr;
  int userId = 0;
  bool isApiCalling = false;
  int selectedLanguage = 0;
  List languageList = [
    {
      "id": 0,
      "title": "English",
    },
    {
      "id": 1,
      "title": "Arabic",
    },
 
  ];
  dynamic languageId;
  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    languageId = prefs.getString("language_id");
    log(languageId);
    if (languageId != null) {
      selectedLanguage = int.parse(languageId);
    }
    print(languageId.runtimeType);
    setState(() {});
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        body: Directionality(
          textDirection:
              language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: Container(
            height: MediaQuery.of(context).size.height * 100 / 100,
            width: MediaQuery.of(context).size.width * 100 / 100,
            decoration: const BoxDecoration(
              // color: Colors.white,
              color: AppColor.secondaryColor,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 6 / 100,
                ),
                const NoInternetBanner(),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 90 / 100,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Transform.rotate(
                          angle: language == 1 ? 3.1416 : 0,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 6 / 100,
                            height: MediaQuery.of(context).size.width * 6 / 100,
                            child: Image.asset(AppImage.backIcon),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 4 / 100,
                      ),
                      Text(
                        AppLanguage.languageText[language],
                        style: const TextStyle(
                          color: AppColor.primaryColor,
                          fontFamily: AppFont.fontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 3 / 100),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(children: [
                      ...List.generate(
                        languageList.length,
                        (index) => GestureDetector(
                            onTap: () async {
                              setState(() {
                                selectedLanguage = languageList[index]['id'];
                              });
                              language = selectedLanguage;

                              // -----Local Storage ------------
                              final prefs =
                                  await SharedPreferences.getInstance();
                              prefs.setString(
                                  "language_id", jsonEncode(selectedLanguage));
                              // prefs.setString("language_name",
                              //     jsonEncode(languageList[index]['title']));
                              if (AppConstant.languageNav == 0) {
                                AppConstant.selectFooterIndex = 4;
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const MyFooterPage()));
                              } else {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const Login()));
                              }

                              // -----Local Storage End------------
                            },
                            child: Container(
                              alignment: Alignment.centerLeft,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                90 /
                                                100,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                6 /
                                                100,
                                            decoration: BoxDecoration(
                                              border: Border.all(width: .5),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      40 /
                                                      100,
                                                  padding: language == 1
                                                      ? const EdgeInsets.only(
                                                          right: 20)
                                                      : const EdgeInsets.only(
                                                          left: 20),
                                                  child: Text(
                                                    languageList[index]
                                                        ["title"],
                                                    style: TextStyle(
                                                      color:
                                                          AppColor.primaryColor,
                                                      fontFamily:
                                                          AppFont.fontFamily,
                                                      fontSize:
                                                          screenWidth > 600
                                                              ? 20
                                                              : 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      40 /
                                                      100,
                                                ),
                                                Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      5 /
                                                      100,
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      5 /
                                                      100,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      width: .3,
                                                      color: AppColor
                                                          .textinputBorderColor,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            100),
                                                  ),
                                                  child: languageList[index]
                                                              ["id"] ==
                                                          selectedLanguage
                                                      ? Image.asset(
                                                          AppImage
                                                              .selectLanguage,
                                                          fit: BoxFit.fill,
                                                        )
                                                      : Container(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // if (languageList[index]["languageId"] == languageId)
                                    ],
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        100,
                                  ),
                                ],
                              ),
                            )),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
