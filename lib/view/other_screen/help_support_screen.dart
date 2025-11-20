import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import 'dart:ui' as ui;

class HelpSupport extends StatefulWidget {
  static String routeName = "/HelpSupport";
  const HelpSupport({super.key});

  @override
  State<HelpSupport> createState() => _HelpSupportState();
}

class _HelpSupportState extends State<HelpSupport> {
  TextEditingController messageTextEditingController = TextEditingController();
  List messageList = [
    {
      "id": 1,
      "message": "Hi, is the boat available for the weekend?",
      "time": "9:30 PM"
    },
    {
      "id": 2,
      "message": "Yes, it's available from Friday to Sunday.",
      "time": "9:32 PM"
    },
    {
      "id": 6,
      "message": "Yes, it's available from Friday to Sunday.",
      "time": "9:35 PM"
    },
    {
      "id": 5,
      "message": "Perfect! Please send the details .",
      "time": "9:38 PM"
    },
  ];
  bool isContainerVisible = false;
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColor.secondaryColor,
        statusBarIconBrightness: Brightness.dark));
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          isContainerVisible = false;
        });
      },
      child: Scaffold(
        backgroundColor: AppColor.secondaryColor,
        body: SafeArea(
            child: Directionality(
          textDirection:
              language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: Stack(
            children: [
              Container(
                color: AppColor.secondaryColor,
                width: MediaQuery.of(context).size.width * 100 / 100,
                height: MediaQuery.of(context).size.height * 100 / 100,
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 7 / 100,
                      width: MediaQuery.of(context).size.width * 90 / 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              height:
                                  MediaQuery.of(context).size.width * 5 / 100,
                              width:
                                  MediaQuery.of(context).size.width * 5 / 100,
                              child: Image.asset(
                                AppImage.backIcon,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.width * 4 / 100,
                            width: MediaQuery.of(context).size.width * 4 / 100,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 73 / 100,
                            child: Text(
                                AppLanguage.helpAndSupportText[language],
                                style: const TextStyle(
                                    color: AppColor.primaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: AppFont.fontFamily)),
                          ),
                          // SizedBox(
                          //   height: MediaQuery.of(context).size.width * 5 / 100,
                          //   width: MediaQuery.of(context).size.width * 5 / 100,
                          //   child: Image.asset(AppImage.phoneIcon),
                          // ),
                        ],
                      ),
                    ),
                    Expanded(
                        flex: 1,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      3 /
                                      100),
                              Wrap(
                                runSpacing: 10.0,
                                children:
                                    List.generate(messageList.length, (index) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width *
                                        90 /
                                        100,
                                    child: Column(
                                      crossAxisAlignment:
                                          messageList[index]['id'] % 2 == 1
                                              ? CrossAxisAlignment.start
                                              : CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              70 /
                                              100,
                                          // padding: EdgeInsets.symmetric(
                                          //     vertical: MediaQuery.of(context)
                                          //             .size
                                          //             .height *
                                          //         2 /
                                          //         100,
                                          //     horizontal: MediaQuery.of(context)
                                          //             .size
                                          //             .width *
                                          //         3 /
                                          //         100),

                                          padding: const EdgeInsets.only(
                                                  top: 12, bottom: 20) +
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12),
                                          decoration: BoxDecoration(
                                            color:
                                                messageList[index]['id'] % 2 ==
                                                        1
                                                    ? Colors.grey
                                                    : Colors.green,
                                            borderRadius: BorderRadius.only(
                                              topLeft: messageList[index]
                                                              ['id'] %
                                                          2 ==
                                                      0
                                                  ? Radius.circular(16)
                                                  : Radius.circular(0),
                                              topRight: messageList[index]
                                                              ['id'] %
                                                          2 ==
                                                      0
                                                  ? Radius.circular(0)
                                                  : Radius.circular(16),
                                              bottomLeft: messageList[index]
                                                              ['id'] %
                                                          2 ==
                                                      0
                                                  ? Radius.circular(16)
                                                  : Radius.circular(16),
                                              bottomRight: messageList[index]
                                                              ['id'] %
                                                          2 ==
                                                      1
                                                  ? Radius.circular(16)
                                                  : Radius.circular(16),
                                            ),
                                          ),

                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                width: messageList[index]
                                                                ['id'] %
                                                            2 ==
                                                        0
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        40 /
                                                        100
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        48 /
                                                        100,
                                                child: Text(
                                                  messageList[index]['message'],
                                                  style: const TextStyle(
                                                      color: AppColor
                                                          .secondaryColor,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      fontFamily:
                                                          AppFont.fontFamily),
                                                ),
                                              ),
                                              // if (messageList[index]['id'] % 2 ==
                                              //     0)
                                              Container(
                                                margin:
                                                    EdgeInsets.only(top: 15),
                                                child: Text(
                                                  messageList[index]['time'],
                                                  style: const TextStyle(
                                                      color: AppColor
                                                          .secondaryColor,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w300,
                                                      fontFamily:
                                                          AppFont.fontFamily),
                                                ),
                                              ),
                                              if (messageList[index]['id'] %
                                                      2 ==
                                                  0)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      top: 15),
                                                  alignment: Alignment.topRight,
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
                                                  child: Image.asset(
                                                      AppImage.chatIcon),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              )
                            ],
                          ),
                        )),
                    Container(
                      width: MediaQuery.of(context).size.width * 100 / 100,
                      padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 5 / 100,
                          horizontal:
                              MediaQuery.of(context).size.width * 5 / 100),
                      decoration: const BoxDecoration(
                          color: AppColor.secondaryColor,
                          boxShadow: [
                            BoxShadow(
                              spreadRadius: -4,
                              blurRadius: 12,
                              color: Color.fromARGB(255, 167, 161, 161),
                            )
                          ]),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Center(
                            child: SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 80 / 100,
                              height:
                                  MediaQuery.of(context).size.height * 6 / 100,
                              child: TextFormField(
                                readOnly: false,
                                style: AppConstant.textFilledHeading,
                                textAlignVertical: TextAlignVertical.center,
                                keyboardType: TextInputType.name,
                                //controller: controller,

                                decoration: InputDecoration(
                                  prefixIcon: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        child: Image.asset(
                                          AppImage.smileIcon,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              5 /
                                              100,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              5 /
                                              100,
                                        ),
                                      ),
                                    ],
                                  ),
                                  suffixIcon: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        child: Image.asset(
                                          AppImage.uploadIcon,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              5 /
                                              100,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              5 /
                                              100,
                                        ),
                                      ),
                                    ],
                                  ),
                                  border: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColor.textinputBorderColor),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(25)),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColor.textinputBorderColor),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(25)),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColor.textinputBorderColor),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(25)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 15),
                                  filled: false,
                                  counterText: '',
                                  hintText: AppLanguage.messageText[language],
                                  hintStyle: const TextStyle(
                                      color: AppColor.textinputBorderColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: AppFont.fontFamily),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 7 / 100,
                            height: MediaQuery.of(context).size.width * 7 / 100,
                            child: Image.asset(AppImage.sendIcon),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}
