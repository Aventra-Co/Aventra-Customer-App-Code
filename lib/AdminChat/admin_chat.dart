import 'dart:async';
import 'dart:convert';
import 'package:boatapp/controller/app_image.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/app_color.dart';
import '../controller/app_config_provider.dart';
import '../controller/app_constant.dart';
import '../controller/app_firebase.dart';
import '../controller/app_font.dart';
import '../controller/app_language.dart';
import '../controller/app_loader.dart';
import '../controller/app_snack_bar_toast_message.dart';
import '../view/authentication/login_screen.dart';
import 'dart:ui' as ui;

class AdminChat extends StatefulWidget {
  final int otherUserId;
  // final String otherUserImage;
  final String otherUserName;
  // final String otherUserNameIdentify;
  final String deviceToken;
  // final String acceptAt;
  final String chatMetStatus;

  const AdminChat(
      {Key? key,
      required this.otherUserId,
      // required this.otherUserImage,
      required this.otherUserName,
      // required this.otherUserNameIdentify,
      required this.deviceToken,
      // required this.acceptAt,
      required this.chatMetStatus})
      : super(key: key);

  @override
  State<AdminChat> createState() => _ChatState();
}

class _ChatState extends State<AdminChat> {
  var items = [
    1, 2
    // 'Report and Unmatch',
    // 'Unmatch Only'
  ];
  int dropdownvalue = 1;
  bool isApiCalling = false;
  bool isMeetApiCall = false;
  TextEditingController textInputChatController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  // late DatabaseReference dbRef;
  List<dynamic> listmessage = <dynamic>[];
  List<dynamic> otherUserInbox = <dynamic>[];
  List<dynamic> otherUserInboxAll = <dynamic>[];
  int userId = 0;
  String userName = "";
  String userImage = "NA";
  bool isTextInputEmpty = false;
  bool height = false;
  List<dynamic> messageAll = <dynamic>[];
  int openTextField = 0;
  String userCreatedChatId = "";
  String deleteUserChatId = "";
  String otherUserCreatedChatId = "";
  String daysAgo = "0 days ago";
  Timer? timer;
  List<dynamic> userIds = [];
  List<dynamic> metUserIdsList = [];
  bool isMessageEmpty = false;
  bool isVisibleFirstTime = false;
  FocusNode chatFocusNode = FocusNode();
  String mobileNumber = "";

  //------------------------GET NUMBER API CALL--------------------------------//
  Future<void> getNumberApiCall() async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}get_admin_number");
    print("url $url");
    String token = AppConstant.token;

    if (token.isEmpty) {
      print("Token is missing!");
      // return;
    }

    Map<String, String> headers = {
      'Authorization': 'Bearer $token', // Use 'Bearer' if required
    };

    print("headers $headers");

    try {
      final response = await http.get(url, headers: headers);
      print("response $response");

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print("res $res");

        if (res['success'] == true) {
          mobileNumber = res['admin_number'].toString();
        } else {
          // ignore: use_build_context_synchronously
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Login()));
          }
        }
      } else {}
    } catch (e) {}
  }

//===============DIAL PAD FUNCTION===============//
  openDialPad(String phoneNumber) async {
    final Uri url = Uri.parse('tel:+91$phoneNumber');

    // Uri url = Uri(scheme: "tel", path: phoneNumber);
    print("Formatted URI: $url");

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      print("Can't open dial pad.");
    }
  }

  @override
  void initState() {
    // getGetMetUserApi(widget.otherUserId);
    getUserDetails();
    getNumberApiCall();
    print("ChatInitialScreen");
    print(widget.otherUserId);
    print(widget.otherUserName);
    // print(widget.otherUserImage);
    // print(widget.otherUserNameIdentify);
    print("deviceToken : ${widget.deviceToken}");
    FirebaseProvider.firebaseCreateUser(true, 'yes');
    // // Suppose you have a Timestamp object called timestamp
    // Timestamp timestamp = Timestamp.fromMillisecondsSinceEpoch(1647169645000);

    // // Convert the Timestamp to a DateTime object
    // DateTime dateTime = timestamp.toDate();

    // // Print the DateTime object in a readable format
    // print("dateTime : ${dateTime.toString()}");

    // Get the current timestamp
    // Timestamp currentTimestamp = Timestamp.now();
    // print("CurrentTimestamp---> $currentTimestamp");

    // Print the current timestamp in a readable format
    // print("CurrentTimestamp ${currentTimestamp.toDate().toString()}");

    super.initState();
  }

  Future<void> getUserDetails() async {
    print("Message Screen");
    final prefs = await SharedPreferences.getInstance();
    dynamic userDetails = prefs.getString('userDetails');

    // var userMet = prefs.getString('user_met').toString();
    // print("user_met : ${json.decode(userMet)}");

    // if (json.decode(userMet) != null) {
    //   userIds = json.decode(userMet);
    // }

    //--------------Firebase Get Other User Inbox ---------------
    if (userDetails != null) {
      setState(() {
        isApiCalling = false;
      });
      dynamic userDetail = jsonDecode(userDetails);
      // print("userDetail $userDetail['avatar']");
      userId = userDetail['user_id'];

      FirebaseProvider.setOtherUserMessageCountZero(
          userId.toString(), widget.otherUserId.toString());

      userName = "john".toString();
      // print("userName $userName");

      // String id = userDetail['user_id'].toString();
      // print('id $id');

      // String userImageUrl = userDetail['avatar']['url'];
      // print("userImageUrl : $userImageUrl");
      userImage = "";

      String otherUserId = widget.otherUserId.toString();
      // print('otherUserId $otherUserId');

      // print("u_$otherUserId");

      deleteUserChatId = "u_$otherUserId";
      // print("deleteUserChatId : $deleteUserChatId");

      String userChatId = 'u_${userId}__u_$otherUserId';
      // print("userChatId : $userChatId");

      userCreatedChatId = userChatId;

      otherUserCreatedChatId = 'u_${otherUserId}__u_$userId';

      // print("widget.acceptAt : ${widget.acceptAt}");

      // if (widget.acceptAt != "NA") {
      //   String days =
      //       Utils.differenceBetweenTwoDateInDays(widget.acceptAt.toString());
      //   // print("days $days");
      //   daysAgo = days.toString();
      // }
    }

    await FirebaseDatabase.instance
        .ref('message/$userCreatedChatId')
        .get()
        .then((snap) {
      print("snap.value--> ${snap.value}");

      // jsonObject.addAll({
      //   'answerTimeStamp': answerTimeStamp,
      // });
      // final list=snap.value;
      // print("list  $list");
      //  for (var i = 0; i < list.length; i++) {

      //                     }
      if (snap.value == null) {
        isMessageEmpty = true;
      }
      isApiCalling = false;
      setState(() {});
    }).catchError((error) {});

    setState(() {});
  }

  getTimeAgo(timestamp) {
    // Convert Unix timestamp to DateTime object
    DateTime datetime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

// Format datetime to a string
    String formattedDateTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(datetime);

    print('Datetime: $formattedDateTime');

    String formattedTime =
        DateFormat('h:mm a').format(formattedDateTime as DateTime);
    return formattedTime.toString();
  }

  backPress() {
    if (height == false) {
      setState(() {
        height = false;
      });
    }
    if (height == true) {
      setState(() {
        height = true;
      });
    }
  }

  String getChatTime(DateTime chatTime) {
    DateTime now = DateTime.now();
    final int chatDateDifference = now.difference(chatTime).inDays;

    if (chatDateDifference == 0) {
      // Chat occurred today
      return 'Today';
    } else if (chatDateDifference == 1) {
      // Chat occurred yesterday
      return 'Yesterday';
    } else {
      // Chat occurred on another day
      return DateFormat('MMM dd, yyyy').format(chatTime).toString();
    }
  }

  lastMessageTime(String messageTime) {
    String formattedTime = "";
    final DateFormat formatter = DateFormat('hh:mm a MMMM d, y');
    formattedTime = formatter.format(DateTime.parse(messageTime));
    return formattedTime.toString();
  }

  getTime(timestamp) {
    print("object$timestamp");

    DateTime datetime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String formattedDateTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(datetime);

    print("formattedDateTime$formattedDateTime");
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
        statusBarColor: AppColor.transparentColor,
        statusBarIconBrightness: Brightness.dark));
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (keyboardVisible == false) {
      setState(() {
        height = false;
      });
    }
    if (keyboardVisible == true) {
      setState(() {
        height = true;
      });
    }
    final firebaseRef =
        FirebaseDatabase.instance.ref().child('message/$userCreatedChatId');

    return WillPopScope(
      onWillPop: () async {
        // Capture a print value when the back button is pressed
        print('Back button pressed');

        // Determine whether to hide the keyboard or not
        if (shouldHideKeyboard()) {
          FocusScope.of(context).unfocus();
        }

        return true; // Allow back navigation
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // SizedBox(
                    //   height: MediaQuery.of(context).size.height * 1 / 100,
                    // ),
                    Directionality(
                      textDirection: language == 1
                          ? ui.TextDirection.rtl
                          : ui.TextDirection.ltr,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 7 / 100,
                        width: MediaQuery.of(context).size.width * 90 / 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Transform.rotate(
                                angle: language == 1 ? 3.1416 : 0,
                                child: Container(
                                  height: MediaQuery.of(context).size.width *
                                      5 /
                                      100,
                                  width: MediaQuery.of(context).size.width *
                                      5 /
                                      100,
                                  child: Image.asset(
                                    AppImage.navigateBackIcon,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.width * 4 / 100,
                              width:
                                  MediaQuery.of(context).size.width * 4 / 100,
                            ),
                            Container(
                              width:
                                  MediaQuery.of(context).size.width * 73 / 100,
                              child: Text(
                                  AppLanguage.helpAndSupportText[language],
                                  style: const TextStyle(
                                      color: AppColor.primaryColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: AppFont.fontFamily)),
                            ),
                            GestureDetector(
                              onTap: () {
                                openDialPad(mobileNumber);
                              },
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.width * 5 / 100,
                                width:
                                    MediaQuery.of(context).size.width * 5 / 100,
                                child: Image.asset(AppImage.phoneIcon),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // AppHeader(
                    //     text: AppLanguage.helpAndSupportText[language],
                    //     onPress: () {
                    //       FirebaseProvider.firebaseCreateUser(true, 'yes');
                    //       Navigator.pop(context);
                    //     }),
                    // Container(
                    //   width: MediaQuery.of(context).size.width * 90 / 100,
                    //   child: Row(
                    //     children: [
                    //       GestureDetector(
                    //         onTap: () {
                    //           FirebaseProvider.firebaseCreateUser(true, 'yes');
                    //           Navigator.pop(context);
                    //         },
                    //         child: Container(
                    //           width: MediaQuery.of(context).size.width * 12 / 100,
                    //           height:
                    //               MediaQuery.of(context).size.width * 12 / 100,
                    //           child: Image.asset(AppImage.navigateBackLogo),
                    //         ),
                    //       ),
                    //       SizedBox(
                    //         width: MediaQuery.of(context).size.width * 3 / 100,
                    //       ),
                    //       Text(
                    //         AppLanguage.chatSupportText[language],
                    //         // style: AppConstant.appBarTitleStyle,
                    //       )
                    //     ],
                    //   ),
                    // ),

                    // SizedBox(
                    //   height: MediaQuery.of(context).size.height * 3 / 100,
                    // ),
                    // const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.only(bottom: 11),
                      height: height == false
                          ? MediaQuery.of(context).size.height * 78 / 100
                          : MediaQuery.of(context).size.height * 42 / 100,
                      width: MediaQuery.of(context).size.width * 100 / 100,
                      color: Colors.white,
                      child: StreamBuilder(
                        stream: firebaseRef.onValue,
                        builder: (context, snap) {
                          if (snap.hasData &&
                              !snap.hasError &&
                              snap.data!.snapshot.value != null) {
                            Map data = snap.data!.snapshot.value as Map;
                            List item = [];

                            data.forEach((index, data) =>
                                item.add({"key": index, ...data}));

                            print("object11$item");
                            for (var i = 0; i < item.length; i++) {
                              if (item[i]['senderId'] == 1) {
                                item[i]['MsgTimeShamp'] = item[i]['timestamp'];
                                // print("hello");
                                // DateTime datetime =
                                //     DateTime.fromMillisecondsSinceEpoch(
                                //         item[i]['timestamp']);
                                // String formattedDateTime =
                                //     DateFormat('yyyy-MM-dd HH:mm:ss')
                                //         .format(datetime);

                                //   print("formattedDateTime$formattedDateTime");

                                //   item[i]['MsgTimeShamp'] = formattedDateTime;
                              }
                              if (item[i]['senderId'] != 1) {
                                item[i]['MsgTimeShamp'] = item[i]['timestamp'];
                              }
                            }
                            print("object33$item");

                            if (widget.chatMetStatus == "no") {
                              if (item.length == 10) {
                                if (isVisibleFirstTime == false) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    // chatModalAfterTenMessages(
                                    //     context, 1, 1);
                                    setState(() {
                                      isVisibleFirstTime = true;
                                    });
                                  });
                                }
                              }
                            }

                            item.sort(((a, b) {
                              String one = a["MsgTimeShamp"]?.toString() ?? '0';
                              String two = b["MsgTimeShamp"]?.toString() ?? '0';
                              return two.compareTo(one);
                            }));

                            // int count = 0;
                            List item1 = [];
                            // String value = "NA";
                            for (var i = 0; i < item.length; i++) {
                              print("object$item");
                              var chatJson = {
                                'key': item[i]['key'],
                                'senderId': item[i]['senderId'],
                                'last_seen': item[i]['last_seen'],
                                'messageType': item[i]['messageType'],
                                'msg_time': item[i]['msg_time'],
                                'message': item[i]['message'],
                                'timestamp': item[i]['timestamp'],
                                'MsgTimeShamp': item[i]['MsgTimeShamp'] ?? 0,
                              };
                              item1.add(chatJson);
                            }
                            item = [];
                            item = item1;

                            listmessage = item1;

                            return ListView.builder(
                                controller: _scrollController,
                                reverse: true,
                                shrinkWrap: true,
                                scrollDirection: Axis.vertical,
                                itemCount: item.length,
                                itemBuilder: (BuildContext context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18),
                                    child: Column(
                                      children: [
                                        InkWell(
                                          onLongPress: () {},
                                          child: Container(
                                            alignment: (item[index]['senderId']
                                                        .toString() !=
                                                    userId.toString())
                                                ? Alignment.topLeft
                                                : Alignment.topRight,
                                            child: Container(
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.80,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 15),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.only(
                                                  topLeft:
                                                      const Radius.circular(15),
                                                  topRight:
                                                      const Radius.circular(15),
                                                  bottomRight: Radius.circular(
                                                      (item[index]['senderId']
                                                                  .toString() !=
                                                              userId.toString())
                                                          ? 15
                                                          : 0),
                                                  bottomLeft: Radius.circular(
                                                      (item[index]['senderId']
                                                                  .toString() !=
                                                              userId.toString())
                                                          ? 0
                                                          : 15),
                                                ),
                                                color: (item[index]['senderId']
                                                            .toString() !=
                                                        userId.toString())
                                                    ? AppColor.themeColor
                                                    : AppColor.themeColor,
                                              ),
                                              child: Text(
                                                item[index]['message']
                                                    .toString(),
                                                style: TextStyle(
                                                    color: (item[index]
                                                                    ['senderId']
                                                                .toString() !=
                                                            userId.toString())
                                                        ? Colors.white
                                                        : Colors.white,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          alignment: (item[index]['senderId']
                                                      .toString() !=
                                                  userId.toString())
                                              ? Alignment.topLeft
                                              : Alignment.topRight,
                                          child: Row(
                                            mainAxisAlignment: (item[index]
                                                            ['senderId']
                                                        .toString() !=
                                                    userId.toString())
                                                ? MainAxisAlignment.start
                                                : MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                DateFormat(
                                                        'dd MMM yyyy, hh:mm a')
                                                    .format(
                                                  DateTime.parse(item[index]
                                                          ['MsgTimeShamp']
                                                      .toString()),
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                2 /
                                                100),
                                      ],
                                    ),
                                  );
                                });
                          } else {
                            return const Text('');
                          }
                        },
                      ),
                    ),

                    // )
                  ],
                ),
                Directionality(
                  textDirection: language == 1
                      ? ui.TextDirection.rtl
                      : ui.TextDirection.ltr,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          chatFocusNode.hasFocus
                              ? BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 5,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                )
                              : BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 5,
                                  blurRadius: 5,
                                  offset: const Offset(
                                      0, 3), // changes position of shadow
                                ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(0),
                        child: TextFormField(
                          enabled: true,
                          controller: textInputChatController,
                          textCapitalization: TextCapitalization.sentences,
                          cursorColor: Colors.grey,
                          keyboardType: TextInputType.text,
                          focusNode: chatFocusNode,
                          decoration: InputDecoration(
                            counterText: '',
                            suffixIcon: InkWell(
                              onTap: () {
                                if (textInputChatController.text.isNotEmpty) {
                                  FirebaseProvider.sendMessage(
                                    userId.toString(),
                                    widget.otherUserId.toString(),
                                    widget.otherUserName,
                                    textInputChatController.text,
                                    widget.deviceToken,
                                  );

                                  messageAll = [];
                                  if (height == false) {
                                    setState(() {
                                      height = false;
                                    });
                                  }
                                  if (height == true) {
                                    setState(() {
                                      height = true;
                                    });
                                  }

                                  getUserDetails();
                                }
                                textInputChatController.clear();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(9.0),
                                child: Transform.rotate(
                                  angle: language == 1 ? 3.1416 : 0,
                                  child: Image.asset(
                                    isTextInputEmpty
                                        ? AppImage.sendIcon
                                        : AppImage.sendIcon,
                                    width: 5,
                                    height: 5,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            border: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey, width: 0.6),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey, width: 0.6),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey, width: 0.6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 18.0),
                            fillColor: Colors.white,
                            filled: true,
                            errorStyle: const TextStyle(color: Colors.red),
                            hintText: AppLanguage.enterMsgText[language],
                            hintStyle: const TextStyle(
                                color: Color(0xff999999),
                                fontSize: 14.0,
                                fontWeight: FontWeight.w400),
                          ),
                          onTap: () {
                            if (listmessage.isNotEmpty) {
                              scrollToBottom();
                            }

                            setState(() {
                              openTextField = 1;
                              height = true;
                            });
                          },
                          onEditingComplete: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() {
                              openTextField = 0;
                              height = false;
                            });
                          },
                          onChanged: (input) {
                            if (input.isNotEmpty) {
                              isTextInputEmpty = true;
                            } else {
                              isTextInputEmpty = false;
                            }
                            setState(() {
                              height = true;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  sendFirstMessage(otherUserId, message) async {
    print("sendFirstMessage;");
    final prefs = await SharedPreferences.getInstance();
    var jwtToken = prefs.getString('user_jwt_token').toString();

    String userJWTToken = "Bearer $jwtToken";

    final url = Uri.parse("${AppConfigProvider.apiUrl}chats");
    print('url: $url');

    Map<String, String> headers = ({
      'Authorization': userJWTToken.toString(),
      "Content-Type": "application/json"
    });

    final response = await http.post(url,
        body: jsonEncode({
          "data": {
            "message": textInputChatController.text,
            "to_user": otherUserId
          }
        }),
        headers: headers);
    print(json.decode(response.body));

    try {
      if (response.statusCode == 200) {
        setState(() {
          isMessageEmpty = false;
        });
      } else {}
    } catch (err) {}
  }

  sendFirstMessageVerify(otherUserId, message) async {
    print("sendFirstMessageVerify;");
    final prefs = await SharedPreferences.getInstance();
    var jwtToken = prefs.getString('user_jwt_token').toString();

    String userJWTToken = "Bearer $jwtToken";

    final url = Uri.parse("${AppConfigProvider.apiUrl}chats");
    print('url: $url');

    Map<String, String> headers = ({
      'Authorization': userJWTToken.toString(),
      "Content-Type": "application/json"
    });

    final response = await http.post(url,
        body: jsonEncode({
          "data": {
            "message": textInputChatController.text,
            "to_user": otherUserId
          }
        }),
        headers: headers);
    print(json.decode(response.body));
    try {
      if (response.statusCode == 200) {
      } else {}
    } catch (err) {}
  }

  sendMessage() {
    Map<String, dynamic> user = {
      'chat_room_id': 'no',
      'email': 'info@mailinator.com',
      // 'image': 'image1.jgp',
      'notification_stauts': 1,
      'online_status': 'false',
      'player_id': 'no',
      'user_id': 2,
      'user_type': 0,
      'login_type': 'app',
    };
    FirebaseDatabase.instance.ref('users/' 'u_1').update(user).then((value) {
      var onlineStatusRef =
          FirebaseDatabase.instance.ref('users/' 'u_1' '/onlineStatus/');
      onlineStatusRef.onDisconnect().set('false');
    });
    // dbRef.push().set(user);
  }

  void scrollToBottom() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  bool shouldHideKeyboard() {
    // Implement your logic here to determine whether to hide the keyboard
    return true; // Replace with your condition
  }
}
