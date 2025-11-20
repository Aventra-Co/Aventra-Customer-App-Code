import 'dart:convert';
import 'dart:developer';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/app_color.dart';
import '../controller/app_config_provider.dart';
import '../controller/app_constant.dart';
import '../controller/app_footer.dart';
import '../controller/app_image.dart';
import '../controller/app_language.dart';
import '../controller/app_snack_bar_toast_message.dart';
import '../helper/apis.dart';
import '../helper/my_date_util.dart';
import '../model/chat_user.dart';
import '../model/message.dart';
import '../view/authentication/login_screen.dart';
import 'message_card.dart';
import 'profile_image.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //for storing all messages
  List<Message> _list = [];
  XFile? _imageSelect;
  String selectedImagePath = '';
  var fileName = 'NA';
  bool isApiCalling = false;

  //for handling message text changes
  final _textController = TextEditingController();

  //showEmoji -- for storing value of showing or hiding emoji
  //isUploading -- for checking if image is uploading or not?
  bool _showEmoji = false, _isUploading = false;
  int userId = 0;
  dynamic data;
  dynamic userDataArr;
  bool isActive = false;

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  //----------------------------GET USER DETAILS--------------------------------//
  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    data = prefs.getString("userDetails");

    // print("userDetails $userDetails");
    if (data == null) {
      // print("worked");
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.notRegisteredMsg[language]);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Login()));
    } else {
      userDataArr = jsonDecode(data);
      userId = userDataArr['user_id'] ?? 0;
    }

    // print("userDataArr $userDataArr");;
    isApiCalling = false;
    setActiveStatus();
    getActiveStatus();
    setState(() {});
  }

  //=============Set Active Status==================
  setActiveStatus() async {
    setState(() {
      isApiCalling = true;
    });
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}user_chat_status");
    String token = AppConstant.token;
    print("Url===> $url");

    try {
      var headers = {
        'Authorization': 'Bearer $token',
      };

      var body = {
        'user_id': userId.toString(),
        'other_user_id': widget.user.id.toString(),
      };

      print("body $body");

      http.Response response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      print("response--> $response");
      var res = jsonDecode(response.body);

      print("res333 : $res");

      if (response.statusCode == 200) {
        print("res : $res");
        if (res['success'] == true) {
          // log("Status True");
          setState(() {
            isApiCalling = false;
          });
        } else {
          // ignore: use_build_context_synchronously
          setState(() {
            isApiCalling = false;
          });
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          if (res['active_status'] == 0) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Login()));
          }
        }
      } else {
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (e) {
      setState(() {
        isApiCalling = false;
      });
    }
  }

  //=============Get Active Status=================
  getActiveStatus() async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}get_active_status?user_id=$userId&other_user_id=${widget.user.id}");
    print("urlrttt $url");

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
        // log("APiStatus200 $isActive");
        dynamic res = jsonDecode(response.body);
        print("res $res");

        if (res['success'] == true) {
          isActive = res['status'];
          log("APiStatus $isActive");
          setState(() {
            isApiCalling = false;
          });
        } else {
          setState(() {
            isApiCalling = false;
          });
          // ignore: use_build_context_synchronously
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          if (res['active_status'] == 0) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Login()));
          }
        }
      } else {
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (e) {
      setState(() {
        isApiCalling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return WillPopScope(
      onWillPop: () {
        if (_showEmoji) {
          setState(() => _showEmoji = false);
          return Future.value(false);
        } else {
          AppConstant.selectFooterIndex = 2;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyFooterPage(),
            ),
          );
          return Future.value(true);
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus;
          setState(() {
            _showEmoji = false;
          });
        },
        child: Scaffold(
          //app bar
          // appBar: AppBar(
          //   automaticallyImplyLeading: false,
          //   flexibleSpace: _appBar(),
          // ),

          backgroundColor: Colors.white,

          //body
          body: Column(
            children: [
              StreamBuilder(
                  stream: APIs.getUserInfo(widget.user),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.docs;
                    final list = data
                            ?.map((e) => ChatUser.fromJson(e.data()))
                            .toList() ??
                        [];
                    return Container(
                      width: MediaQuery.of(context).size.width * 100 / 100,
                      height: MediaQuery.of(context).size.height * 13 / 100,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.1), // Shadow color
                            blurRadius: 4, // Blur radius of the shadow
                            offset: Offset(0, 1), // Offset for bottom shadow
                          ),
                        ],
                        color: AppColor.secondaryColor,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 6 / 100,
                          ),
                          Row(
                            children: [
                              //back button
                              IconButton(
                                  onPressed: () {
                                    AppConstant.selectFooterIndex = 2;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MyFooterPage(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    size: 30,
                                  )),

                              //user profile picture
                              ProfileImage(
                                size: MediaQuery.of(context).size.height * .05,
                                url: list.isNotEmpty
                                    ? list[0].image
                                    : widget.user.image,
                              ),

                              //for adding some space
                              const SizedBox(width: 10),

                              //user name & last seen time
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  //user name
                                  Text(
                                      list.isNotEmpty
                                          ? list[0].name
                                          : widget.user.name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500)),

                                  //for adding some space
                                  const SizedBox(height: 2),

                                  //last seen time of user
                                  Text(
                                      list.isNotEmpty
                                          ? list[0].isOnline
                                              ? 'Online'
                                              : MyDateUtil.getLastActiveTime(
                                                  context: context,
                                                  lastActive:
                                                      list[0].lastActive)
                                          : MyDateUtil.getLastActiveTime(
                                              context: context,
                                              lastActive:
                                                  widget.user.lastActive),
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.black)),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

              SizedBox(
                height: MediaQuery.of(context).size.height * 2 / 100,
              ),
              Expanded(
                child: StreamBuilder(
                  stream: APIs.getAllMessages(widget.user),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      //if data is loading
                      case ConnectionState.waiting:
                      case ConnectionState.none:
                        return const SizedBox();

                      //if some or all data is loaded then show it
                      case ConnectionState.active:
                      case ConnectionState.done:
                        final data = snapshot.data?.docs;
                        _list = data
                                ?.map((e) => Message.fromJson(e.data()))
                                .toList() ??
                            [];

                        if (_list.isNotEmpty) {
                          return ListView.builder(
                              reverse: true,
                              itemCount: _list.length,
                              padding: EdgeInsets.only(
                                  top:
                                      MediaQuery.of(context).size.height * .01),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                return MessageCard(message: _list[index]);
                              });
                        } else {
                          return const Center(
                            child: Text('Say Hii! 👋',
                                style: TextStyle(fontSize: 20)),
                          );
                        }
                    }
                  },
                ),
              ),

              SizedBox(
                height: MediaQuery.of(context).size.height * .01,
              ),

              //progress indicator for showing uploading
              if (_isUploading)
                const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        child: CircularProgressIndicator(strokeWidth: 2))),

              //chat input filed
              _chatInput(screenWidth),

              //show emojis on keyboard emoji button click & vice versa
              if (_showEmoji)
                SizedBox(
                  height: MediaQuery.of(context).size.height * .35,
                  child: EmojiPicker(
                    textEditingController: _textController,
                    config: const Config(),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  // app bar widget
  Widget _appBar() {
    return SafeArea(
      child: InkWell(
          onTap: () {},
          child: StreamBuilder(
              stream: APIs.getUserInfo(widget.user),
              builder: (context, snapshot) {
                final data = snapshot.data?.docs;
                final list =
                    data?.map((e) => ChatUser.fromJson(e.data())).toList() ??
                        [];

                return Container(
                  width: MediaQuery.of(context).size.width * 100 / 100,
                  height: MediaQuery.of(context).size.height * 7 / 100,
                  //color: Colors.amberAccent,
                  decoration: BoxDecoration(
                    color: Colors.white, // Background color of the container
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1), // Shadow color
                        blurRadius: 4, // Blur radius of the shadow
                        offset: const Offset(0, 1), // Offset for bottom shadow
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      //back button
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                            size: 30,
                          )),

                      //user profile picture
                      ProfileImage(
                        size: MediaQuery.of(context).size.height * .05,
                        url:
                            list.isNotEmpty ? list[0].image : widget.user.image,
                      ),

                      //for adding some space
                      const SizedBox(width: 10),

                      //user name & last seen time
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //user name
                          Text(
                              list.isNotEmpty ? list[0].name : widget.user.name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500)),

                          //for adding some space
                          const SizedBox(height: 2),

                          //last seen time of user
                          Text(
                              list.isNotEmpty
                                  ? list[0].isOnline
                                      ? 'Online'
                                      : MyDateUtil.getLastActiveTime(
                                          context: context,
                                          lastActive: list[0].lastActive)
                                  : MyDateUtil.getLastActiveTime(
                                      context: context,
                                      lastActive: widget.user.lastActive),
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black54)),
                        ],
                      )
                    ],
                  ),
                );
              })),
    );
  }

  // bottom chat input field
  // Widget _chatInput() {
  //   return Padding(
  //     padding: EdgeInsets.symmetric(),
  //     child: Row(
  //       children: [
  //         //input field & buttons
  //         Expanded(
  //           child: Container(
  //             height: MediaQuery.of(context).size.height * 8 / 100,
  //             decoration: const BoxDecoration(
  //               color: AppColor.white,
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Color.fromARGB(255, 191, 195, 199), // Shadow color
  //                   blurRadius: 6.0, // Blur intensity
  //                   offset: Offset(0, -2), // Moves shadow 5px down
  //                 ),
  //               ],
  //             ),
  //             child: Row(
  //               children: [
  //                 //emoji button
  //                 IconButton(
  //                     onPressed: () {
  //                       FocusScope.of(context).unfocus();
  //                       imagePickerBottomSheet();
  //                       // setState(() => _showEmoji = !_showEmoji);
  //                     },
  //                     icon: Image.asset(
  //                       AppImage.sendImage,
  //                       color: AppColor.themeColor,
  //                       scale: 3,
  //                     )),
  //                 Expanded(
  //                     child: TextField(
  //                   controller: _textController,
  //                   keyboardType: TextInputType.multiline,
  //                   maxLines: null,
  //                   onTap: () {},
  //                   decoration: InputDecoration(
  //                       hintText: '   Type Message...',
  //                       contentPadding: EdgeInsets.only(left: 5, top: 9),
  //                       hintStyle: const TextStyle(color: AppColor.black),
  //                       suffixIcon: Container(
  //                         height: MediaQuery.of(context).size.width * 5 / 100,
  //                         width: MediaQuery.of(context).size.width * 5 / 100,
  //                         child: MaterialButton(
  //                           onPressed: () {
  //                             if (_textController.text.isNotEmpty) {
  //                               if (_list.isEmpty) {
  //                                 //on first message (add user to my_user collection of chat user)
  //                                 APIs.sendFirstMessage(widget.user,
  //                                     _textController.text, Type.text);
  //                               } else {
  //                                 //simply send message
  //                                 APIs.sendMessage(widget.user,
  //                                     _textController.text, Type.text);
  //                               }
  //                               _textController.text = '';
  //                             }
  //                           },
  //                           minWidth: 0,
  //                           padding: const EdgeInsets.only(
  //                               top: 10, bottom: 10, right: 5, left: 10),
  //                           // shape: const CircleBorder(),
  //                           // color: Colors.green,
  //                           child: Image.asset(AppImage.sendImage),
  //                         ),
  //                       ),
  //                       border: InputBorder.none),
  //                 )),
  //                 SizedBox(width: MediaQuery.of(context).size.width * .02),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _chatInput(screenWidth) {
    return Container(
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
                controller: _textController,
                maxLength: AppConstant.describeLength,
                onTap: () {
                  setState(() => _showEmoji = false);
                },
                decoration: InputDecoration(
                    prefixIcon: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            setState(() => _showEmoji = true);
                          },
                          child: SizedBox(
                            child: Image.asset(
                              AppImage.smileIcon,
                              width: screenWidth > 600
                                  ? MediaQuery.of(context).size.width * 4 / 100
                                  : MediaQuery.of(context).size.width * 5 / 100,
                              height: screenWidth > 600
                                  ? MediaQuery.of(context).size.width * 4 / 100
                                  : MediaQuery.of(context).size.width * 5 / 100,
                            ),
                          ),
                        ),
                      ],
                    ),
                    suffixIcon: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() => _showEmoji = false);
                            FocusScope.of(context).unfocus();
                            imagePickerBottomSheet();
                          },
                          child: SizedBox(
                            child: Image.asset(
                              AppImage.uploadIcon,
                              width: screenWidth > 600
                                  ? MediaQuery.of(context).size.width * 4 / 100
                                  : MediaQuery.of(context).size.width * 5 / 100,
                              height: screenWidth > 600
                                  ? MediaQuery.of(context).size.width * 4 / 100
                                  : MediaQuery.of(context).size.width * 5 / 100,
                            ),
                          ),
                        ),
                      ],
                    ),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.boaderColor),
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.boaderColor),
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.themeColor),
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
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
            GestureDetector(
              onTap: () {
                if (_textController.text.isNotEmpty) {
                  if (_list.isEmpty) {
                    //on first message (add user to my_user collection of chat user)
                    APIs.sendFirstMessage(
                        widget.user, _textController.text, Type.text, isActive);
                  } else {
                    //simply send message
                    APIs.sendMessage(
                        widget.user, _textController.text, Type.text, isActive);
                  }
                  _textController.text = '';
                }
              },
              child: Container(
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
            ),
          ],
        ),
      ),
    );
  }

  void imagePickerBottomSheet() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: Text(AppLanguage.photoGalleryText[language]),
                    onTap: () {
                      _imgFromGallery();
                      setState(() {});
                      // Navigator.of(context).pop();
                    }),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: Text(AppLanguage.cameraText[language]),
                  onTap: () {
                    _imgFromCamera();
                    setState(() {});
                    // Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        });
  }

  Future<void> _imgFromCamera() async {
    dynamic image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        // maxHeight: 450.0,
        // maxWidth: 450.0,
        imageQuality: 50);

    if (image != null) {
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _imageSelect = image;
          fileName = image.path;
          //  var _btnActive = true;
        });
        sendImageApiCall();
      });
    } else {
      setState(() {
        //  var _btnActive = false;
      });
    }

    Navigator.of(context).pop();
  }

//----- from gallary-------
  Future<void> _imgFromGallery() async {
    dynamic image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // maxHeight: 450.0,
        // maxWidth: 450.0,
        imageQuality: 50);

    if (image != null) {
      print("image$image");
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _imageSelect = image;
          fileName = image.path;
          //  var _btnActive = true;
        });
        sendImageApiCall();
      });
    } else {
      setState(() {
        //    var _btnActive = false;
      });
    }

    Navigator.of(context).pop();
  }

  sendImageApiCall() async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}file_upload_user");
    print("Url $url");

    setState(() {
      isApiCalling = true; // Set API call to true while the process starts
    });

    String token = AppConstant.token;
    print(token);

    try {
      var headers = {
        'authorization': 'Bearer $token',
      };

      // Prepare the multipart request
      http.MultipartRequest formData = http.MultipartRequest('POST', url);
      formData.headers.addAll(headers);

      // Add the image file
      if (_imageSelect != null) {
        XFile image1 = _imageSelect!;
        List<int> imageBytes = await image1.readAsBytes();
        http.MultipartFile imageFile = http.MultipartFile.fromBytes(
            'image', imageBytes,
            filename: 'image.jpg', contentType: MediaType('image', 'jpg'));

        formData.files.add(imageFile);
      } else {
        formData.fields['images'] = "";
      }

      // Send the request
      var response = await formData.send();
      var responseBody = await http.Response.fromStream(response);

      print("response--> ${responseBody.body}");
      var res = jsonDecode(responseBody.body);

      if (response.statusCode == 200) {
        print("res : $res");
        if (res['success'] == true) {
          setState(() {
            selectedImagePath = res['image_path'];
            isApiCalling = false;
          });
          if (_list.isEmpty) {
            //on first message (add user to my_user collection of chat user)
            APIs.sendFirstMessage(
                widget.user, selectedImagePath, Type.image, isActive);
          } else {
            //simply send message
            APIs.sendMessage(
                widget.user, selectedImagePath, Type.image, isActive);
          }
          // sendImage(selectedImagePath);
        } else {
          setState(() {
            isApiCalling = false;
          });
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          if (res['active_status'] == 0) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Login()));
          }
        }
      } else {
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (e) {
      setState(() {
        isApiCalling = false;
      });
      print("Error: $e");
    }
  }
}
