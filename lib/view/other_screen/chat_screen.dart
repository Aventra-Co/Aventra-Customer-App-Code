// ignore_for_file: sized_box_for_whitespace, avoid_unnecessary_containers

import 'package:flutter/material.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';

class Chat extends StatefulWidget {
  static String routeName = './Chat';
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatScreen();
}

class _ChatScreen extends State<Chat> {
  TextEditingController messageTextController = TextEditingController();
  List messages = [
    {
      "text": "Hi, is the boat available for the weekend?",
      "time": "9:30am",
      "isMe": false,
      "isRead": true
    },
    {
      "text": "Yes, it's available from Friday to Sunday.",
      "time": "9:30am",
      "isMe": true,
      "isRead": true
    },
    {
      "text": "Would you like to confirm a booking?",
      "time": "9:30am",
      "isMe": true,
      "isRead": true
    },
    {
      "text": "Perfect! Please send the details",
      "time": "9:30am",
      "isMe": false,
      "isRead": true
    },
  ];
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColor.secondaryColor,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Container(
          width: MediaQuery.of(context).size.width * 100 / 100,
          height: MediaQuery.of(context).size.height * 100 / 100,
          color: AppColor.secondaryColor,
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 100 / 100,
                height: MediaQuery.of(context).size.height * 14 / 100,
                decoration: const BoxDecoration(
                    color: AppColor.themeColor,
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(50),
                        bottomRight: Radius.circular(50))),
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 6 / 100,
                    ),
                    Row(
                      //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 3 / 100,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            alignment: Alignment.centerRight,
                            width: MediaQuery.of(context).size.width * 5 / 100,
                            height: MediaQuery.of(context).size.width * 5 / 100,
                            child: Image.asset(
                              AppImage.backIcon,
                              color: AppColor.secondaryColor,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 4 / 100,
                        ),
                        Container(
                          width: screenWidth > 600
                              ? MediaQuery.of(context).size.width * 8 / 100
                              : MediaQuery.of(context).size.width * 10 / 100,
                          height: screenWidth > 600
                              ? MediaQuery.of(context).size.width * 8 / 100
                              : MediaQuery.of(context).size.width * 10 / 100,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.asset(
                              AppImage.boatImage,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 2 / 100,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: const Text(
                                "Mahmoud Tst",
                                style: TextStyle(
                                    color: AppColor.secondaryColor,
                                    fontFamily: AppFont.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                              ),
                            ),
                            Container(
                              child: Text(
                                AppLanguage.onlineText[language],
                                style: const TextStyle(
                                    color: AppColor.secondaryColor,
                                    fontFamily: AppFont.fontFamily,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 2 / 100,
              ),
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Wrap(
                    children: [
                      ...List.generate(
                        messages.length,
                        (index) {
                          return Align(
                            alignment: messages[index]['isMe']
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                              ),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: messages[index]['isMe']
                                      ? AppColor.green
                                      : AppColor.chatBubbaleColor,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: const Radius.circular(12),
                                    bottomRight: const Radius.circular(12),
                                    topRight: messages[index]['isMe']
                                        ? const Radius.circular(0)
                                        : const Radius.circular(12),
                                    topLeft: messages[index]['isMe']
                                        ? const Radius.circular(12)
                                        : const Radius.circular(0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      messages[index]['text'],
                                      style: TextStyle(
                                          color: AppColor.secondaryColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          messages[index]['time'],
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColor.secondaryColor),
                                        ),
                                        if (messages[index]['isMe']) ...[
                                          const SizedBox(width: 5),
                                          Icon(
                                            messages[index]['isRead']
                                                ? Icons.done_all
                                                : Icons.done,
                                            size: 16,
                                            color: messages[index]['isRead']
                                                ? Colors.blue
                                                : Colors.white70,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: AppColor.secondaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.textLightColor, // Shadow color
                      blurRadius: 5.0, // Blur intensity
                      offset: Offset(0, -4), // Moves shadow 5px down
                    ),
                  ],
                ),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 10 / 100,
                alignment: Alignment.center,
                child: Container(
                  width: MediaQuery.of(context).size.width * 90 / 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 80 / 100,
                        height: MediaQuery.of(context).size.height * 6.5 / 100,
                        child: TextFormField(
                          readOnly: false,
                          style: const TextStyle(
                              height: 1.1,
                              color: AppColor.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w400),
                          textAlignVertical: TextAlignVertical.center,
                          keyboardType: TextInputType.text,
                          controller: messageTextController,
                          maxLength: AppConstant.describeLength,
                          decoration: InputDecoration(
                              prefixIcon: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    child: Image.asset(
                                      AppImage.smileIcon,
                                      width: screenWidth > 600
                                          ? MediaQuery.of(context).size.width *
                                              4 /
                                              100
                                          : MediaQuery.of(context).size.width *
                                              5 /
                                              100,
                                      height: screenWidth > 600
                                          ? MediaQuery.of(context).size.width *
                                              4 /
                                              100
                                          : MediaQuery.of(context).size.width *
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
                                      width: screenWidth > 600
                                          ? MediaQuery.of(context).size.width *
                                              4 /
                                              100
                                          : MediaQuery.of(context).size.width *
                                              5 /
                                              100,
                                      height: screenWidth > 600
                                          ? MediaQuery.of(context).size.width *
                                              4 /
                                              100
                                          : MediaQuery.of(context).size.width *
                                              5 /
                                              100,
                                    ),
                                  ),
                                ],
                              ),
                              border: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColor.boaderColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50)),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColor.boaderColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColor.themeColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 15),
                              fillColor: AppColor.secondaryColor,
                              filled: true,
                              counterText: '',
                              hintText: "Message",
                              hintStyle: const TextStyle(
                                  color: AppColor.textColor,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16)),
                        ),
                      ),
                      Container(
                        width: screenWidth > 600
                            ? MediaQuery.of(context).size.width * 4 / 100
                            : MediaQuery.of(context).size.width * 6 / 100,
                        height: screenWidth > 600
                            ? MediaQuery.of(context).size.width * 4 / 100
                            : MediaQuery.of(context).size.width * 6 / 100,
                        child: Image.asset(
                          AppImage.sendIcon,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
