// ignore_for_file: sized_box_for_whitespace
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_font.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_header.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../authentication/login_screen.dart';
import 'package:http/http.dart' as http;

class FAQ extends StatefulWidget {
  static String routeName = "./FAQ";
  const FAQ({super.key});

  @override
  State<FAQ> createState() => _FAQState();
}

class _FAQState extends State<FAQ> {
  int faqIndex = 0;
  List<dynamic> faqList = [];
  bool isApiCalling = false;
  int userId = 0;
  dynamic token;
  dynamic userDetails;

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

//--------------------GET USER DETAILS-----------------------//
  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userDetails = prefs.getString("userDetails");
    token = prefs.getString("token");
    setState(() {
      isApiCalling = true;
    });

    // print("userDetails $userDetails");
    if (userDetails != null) {
      dynamic data = json.decode(userDetails);
      print("up ${data}");
      userId = data['user_id'];
      print('67$userId');
    }
    setState(() {
      isApiCalling = false;
    });
    getFAQsApi(userId);
    setState(() {});
  }

//=============================GET FAQS DETAILS===================================//
  Future<void> getFAQsApi(userId) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}get_faqs?user_id=$userId");
    print("url $url");

    String token = AppConstant.token;

    if (token.isEmpty) {
      print("Token is missing!");
      return;
    }

    Map<String, String> headers = {
      'Authorization': 'Bearer $token', // Use 'Bearer' if required
    };

    setState(() {
      isApiCalling = true;
    });

    print("headers $headers");

    try {
      final response = await http.get(url, headers: headers);
      print("response $response");

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print("res $res");

        if (res['success'] == true) {
          var item = res['faq_array'];
          faqList = (item != "NA") ? item : [];

          setState(() {
            isApiCalling = false;
          });
        } else {
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(
                context, res['message'][language]);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }
          setState(() {
            isApiCalling = false;
          });
        }
      } else {
        print("Error: ${response.statusCode}");
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (e) {
      print("Exception: $e");
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return Scaffold(
      backgroundColor: AppColor.secondaryColor,
      body: SafeArea(
          child: Directionality(
        textDirection:
            language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Container(
          width: MediaQuery.of(context).size.width * 100 / 100,
          height: MediaQuery.of(context).size.height * 100 / 100,
          color: AppColor.secondaryColor,
          child: Column(
            children: [
              const NoInternetBanner(),
              AppHeader(
                text: AppLanguage.faqText[language],
                onPress: () {
                  Navigator.pop(context);
                },
              ),
              Expanded(
                  child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 3 / 100,
                    ),
                    Wrap(
                      children: List.generate(faqList.length, (index) {
                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  faqList[index]["status"] =
                                      !faqList[index]["status"];
                                });
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width *
                                    100 /
                                    100,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                    width: .5,
                                    color: !faqList[index]["status"]
                                        ? AppColor.borderColor
                                        : AppColor.secondaryColor,
                                  )),
                                  borderRadius: BorderRadius.circular(0),
                                  color: faqList[index]["status"]
                                      ? AppColor.lighTthemeColor
                                      : AppColor.secondaryColor,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      // mainAxisAlignment:
                                      //     MainAxisAlignment.spaceBetween,
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              3 /
                                              100,
                                        ),
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              85 /
                                              100,
                                          child: Text(
                                            faqList[index]["question"] ?? "",
                                            style: TextStyle(
                                                color: faqList[index]["status"]
                                                    ? AppColor.themeColor
                                                    : AppColor.lightBlackColor,
                                                fontFamily: AppFont.fontFamily,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 16),
                                          ),
                                        ),
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              4 /
                                              100,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              4 /
                                              100,
                                          decoration: BoxDecoration(
                                              image: DecorationImage(
                                                  image: faqList[index]
                                                          ["status"]
                                                      ? const AssetImage(
                                                          AppImage.upArrowIcon)
                                                      : const AssetImage(
                                                          AppImage
                                                              .downArrowIcon))),
                                        ),
                                      ],
                                    ),
                                    if (faqList[index]["status"]) ...[
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                1 /
                                                100,
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                90 /
                                                100,
                                        child: Text(
                                          faqList[index]["answer"] ?? "",
                                          style: const TextStyle(
                                              color: AppColor.primaryColor,
                                              fontFamily: AppFont.fontFamily,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 2 / 100,
                            ),
                          ],
                        );
                      }),
                    )
                  ],
                ),
              ))
            ],
          ),
        ),
      )),
    );
  }
}
