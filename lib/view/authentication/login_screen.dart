// ignore_for_file: sized_box_for_whitespace, deprecated_member_use, prefer_typing_uninitialized_variables, prefer_interpolation_to_compose_strings
import 'dart:convert';
import 'dart:developer';
import '/view/other_screen/change_language_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_firebase.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../../controller/app_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../../controller/one_signal_service.dart';
import '../../helper/apis.dart';
import '../../model/chat_user.dart';
import 'forgot_password_screen.dart';
import 'otp_verify_screen.dart';
import 'signup_screen.dart';
import 'dart:ui' as ui;

class Login extends StatefulWidget {
  static String routeName = "./Login";
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  List<dynamic> languageList = [
    {"id": 1, "name": "English"},
    {"id": 2, "name": "Arabic"},
    {"id": 3, "name": "French"},
    {"id": 4, "name": "Italian"},
    {"id": 5, "name": "Korean"},
  ];
  List<dynamic> languageShortList = [
    {"id": 1, "name": "Eng"},
    {"id": 2, "name": "Ar"},
    {"id": 3, "name": "Fr"},
    {"id": 4, "name": "It"},
    {"id": 5, "name": "Ko"},
  ];
  String languageName = "Eng";
  late Size media;
  bool passwordVisible = true;
  var id = 1;
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isPasswordVisible = true;
  bool isApiCalling = false;
  int languageId = 0;
  GoogleSignInAuthentication? authentication;
  Map<String, String>? authHeaders;
  GoogleSignInAccount? _currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'profile',
      'email',
    ],
  );
  String deviceType = "";

  @override
  void initState() {
    super.initState();
    setLanguage();
    _handleSignOut();
    // getPaymentStatus();
    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      setState(() {
        _currentUser = account;
      });
      print('google signIn email $_currentUser');
      if (_currentUser != null) {
        print('google signIn email ${account?.email}');
        print('google signIn id ${account?.id}');
        print('google signIn displayName ${account?.displayName}');
        print('google signIn serverAuthCode ${account?.serverAuthCode}');

        authentication = await account?.authentication;
        print(
            'google signIn authentication accessToken ${authentication?.accessToken}');
        print(
            'google signIn authentication idToken ${authentication?.idToken}');

        await localstroge();
        print('check with server...');
        // await googleAuth(
        //     authentication?.idToken, authentication?.accessToken);

        authHeaders = (await account?.authHeaders);
        print(
            'google signIn authHeaders ${jsonEncode(authHeaders).toString()}'); // ~accessToken
      }
    });

    _googleSignIn.signInSilently();
  }

  setLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    dynamic langId = prefs.getString("language_id");
    log("dfd$langId");
    if (langId != null) {
      languageId = int.parse(langId);
      if (languageId == 0) {
        language = 0;
        languageName = "Eng";
      } else {
        language = 1;
        languageName = "Ar";
      }
    } else {
      languageId = 0;
      languageName = "Eng";
    }
    setState(() {});
  }

//-----------------------------SIGN IN VALIDATION--------------------------------//
  signInValidation(String email, String password) {
    if (email.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.emailMessage[language]);
      return;
    } else if (!AppConstant.emailValidatorRegExp.hasMatch(email)) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.emailValidMessage[language]);
      return;
    } else if (password.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.passwordMessage[language]);
      return;
    } else if (password.length < 6) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.passwordMinMessage[language]);
      return;
    } else {
      loginapicallingStart(email, password);
    }
  }

//-----------------------------LOGIN API CALL-----------------------------------//
  loginapicallingStart(email, password) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}sign_in");

    print("Url $url");

    setState(() {
      isApiCalling = true;
    });

    try {
      final String playeID = await OneSignalService.getPlayerId();
      print("playeID line number 101 $playeID");
      http.MultipartRequest formData = http.MultipartRequest('POST', url);
      formData.fields['email'] = email.toString();
      formData.fields['password'] = password.toString();
      formData.fields['player_id'] = playeID.toString();
      formData.fields['device_type'] = AppConstant.deviceType.toString();
      http.StreamedResponse response = await formData.send();
      log("Fromdata${formData.fields}");
      print("response--> $response");
      var responseString = await response.stream.toBytes();
      var res = jsonDecode(utf8.decode(responseString));

      if (response.statusCode == 200) {
        print("res : $res");
        if (res['success'] == true) {
          if (res['userDataArray'] != "NA") {
            AppConstant.token = res['token'];
            print("AppConstant.token ${AppConstant.token}");

            // SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            final prefs = await SharedPreferences.getInstance();
            print("prefs =================>${res['userDataArray']}");
            prefs.setString("userDetails", jsonEncode(res['userDataArray']));
            prefs.setString("password", password);
            FirebaseProvider.firebaseCreateUser(true);
            APIs.userArry = res['userDataArray'];
            APIs.user_id = res['userDataArray']['user_id'].toString();
            updateUser(res['userDataArray'], res['userDataArray']['user_id'],
                playeID);

            if (await userExists(res['userDataArray']['user_id']) && mounted) {
              print("mounted $mounted");
              updateUser(res['userDataArray'], res['userDataArray']['user_id'],
                  playeID);
              AppConstant.selectFooterIndex = 0;
            } else {
              createUser(res['userDataArray']['user_id'], res['userDataArray']);
              updateUser(res['userDataArray'], res['userDataArray']['user_id'],
                  playeID);
              AppConstant.selectFooterIndex = 0;
            }

            if (res['userDataArray']['otp_verify'] == 0) {
              print("object");
              Navigator.pushNamed(context, SignUpOtpVerifyHeader.routeName,
                  arguments: ResetPasswordIdClass(
                      userId: res['userDataArray']['user_id'].toString()));
            } else {
              AppConstant.selectFooterIndex = 0;
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyFooterPage()));
            }
            setState(() {
              isApiCalling = false;
            });
          }
        } else {
          // ignore: use_build_context_synchronously
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          setState(() {
            isApiCalling = false;
          });
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

  static Future<void> createUser(userid, usserArry) async {
    print("user$usserArry");
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final chatUser = ChatUser(
        id: userid.toString(),
        name: usserArry['name'] != null ? usserArry['name'].toString() : "",
        email: usserArry['email'] != null ? usserArry['email'].toString() : "",
        about: "Hey, I'm using We Chat!",
        image: usserArry['image'] != null ? usserArry['image'].toString() : "",
        createdAt: time,
        isOnline: false,
        lastActive: time,
        pushToken: '',
        mobile: "",
        playerId: AppConstant.playerID,
        groups: []);

    return await firestore
        .collection('users')
        .doc(userid.toString())
        .set(chatUser.toJson());
  }

  static Future<bool> userExists(userid) async {
    var doc = await firestore.collection('users').doc(userid.toString()).get();
    bool exists = doc.exists;

    // Print the status
    print("User exists: $exists");

    return exists;
  }

  static Future<void> updateUser(var usserArrey, userId, playerId) async {
    print("userId$userId");
    print("playerId287$playerId");
    try {
      await firestore.collection('users').doc(userId.toString()).update({
        'playerId': playerId.toString(),
        'name': usserArrey['name'] != null ? usserArrey['name'].toString() : "",
        'email':
            usserArrey['email'] != null ? usserArrey['email'].toString() : "",
      });
      print("User updated successfully!");
    } catch (e) {
      print("Error updating user: $e");
    }
  }

//-------------------------------SIGN UP API CALL-------------------//
  signUpUserApiCall(
    String fullName,
    String emailAddress,
    String logintype,
    String socialId,
  ) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}sign_up");

    print("Url $url");

    setState(() {
      isApiCalling = true;
    });

    List<String> nameParts = fullName.split(" ");
    String fName = nameParts.isNotEmpty ? nameParts[0] : "";
    String lName = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";
    log("fName322 $fName and lName $lName");

    try {
      final String playeID = await OneSignalService.getPlayerId();
      print("playeID line number 101 $playeID");
      http.MultipartRequest formData = http.MultipartRequest('POST', url);
      formData.fields['f_name'] = fName.toString();
      formData.fields['l_name'] = lName.toString();
      formData.fields['email'] = emailAddress;
      formData.fields['mobile'] = "";
      formData.fields['password'] = "";
      formData.fields['dob'] = "";
      formData.fields['city_id'] = "";
      formData.fields['country_id'] = "";
      formData.fields['user_type'] = "1";
      formData.fields['player_id'] = playeID.toString();
      formData.fields['device_type'] = AppConstant.deviceType;
      formData.fields['login_type'] = "app";

      log("Fields130--> ${formData.fields}");

      http.StreamedResponse response = await formData.send();
      print("response--> $response");
      var responseString = await response.stream.toBytes();
      var res = jsonDecode(utf8.decode(responseString));

      if (response.statusCode == 200) {
        print("res : $res");
        if (res['success'] == true) {
          AppConstant.token = res['token'];
          print("AppConstant.token ${AppConstant.token}");
          dynamic data = res['userDataArray'];
          log("success145$data");
          if (data != "NA") {
            log("success147");
            final prefs = await SharedPreferences.getInstance();
            print("prefs =================>$prefs");
            prefs.setString("userDetails", jsonEncode(data));
            prefs.setString("token", res['token'].toString());
            log("success");

            APIs.user_id = res['userDataArray']['user_id'].toString();

            print("gjkjkgjg${res['userDataArray']['user_id'].toString()}");

            if (await userExists(res['userDataArray']['user_id']) && mounted) {
              print("mounted $mounted");
              Future.delayed(
                  const Duration(seconds: 2),
                  () => {
                        setState(() {}),
                        AppConstant.selectFooterIndex = 0,
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyFooterPage()),
                        ),
                        setState(() {
                          isApiCalling = false;
                        }),
                      });
            } else {
              APIs.user_id = res['userDataArray']['user_id'].toString();
              createUser(res['userDataArray']['user_id'], res['userDataArray']);
              Future.delayed(
                  const Duration(seconds: 2),
                  () => {
                        AppConstant.selectFooterIndex = 0,
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyFooterPage()),
                        ),
                        setState(() {
                          isApiCalling = false;
                        }),
                      });
            }
          }
        } else {
          // ignore: use_build_context_synchronously
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          setState(() {
            isApiCalling = false;
          });
          if (res['active_flag'] == 0) {
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
    return ProgressHUD(
        inAsyncCall: isApiCalling,
        opacity: 0.5,
        child: _buildUIScreen(context));
  }

  Widget _buildUIScreen(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    print("width $screenWidth heigth $screenHeight");
    media = MediaQuery.of(context).size;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light));
    return WillPopScope(
      onWillPop: () {
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        return Future.value(false);
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Directionality(
            textDirection:
                language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            child: Stack(
              children: [
                Container(
                    height: MediaQuery.of(context).size.height * 100 / 100,
                    width: MediaQuery.of(context).size.width * 100 / 100,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(AppImage.newSplash),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black38, // You can change the color
                          BlendMode
                              .darken, // Try BlendMode.srcATop for a different effect
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 1,
                          child: SingleChildScrollView(
                            //physics: NeverScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: screenWidth > 600
                                      ? MediaQuery.of(context).size.height *
                                          4 /
                                          100
                                      : MediaQuery.of(context).size.height *
                                          6 /
                                          100,
                                ),

                                //language dropdown
                                Container(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  alignment: Alignment.topRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      AppConstant.languageNav = 1;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ChangeLanguage(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: screenWidth > 600
                                          ? MediaQuery.of(context).size.width *
                                              18 /
                                              100
                                          : MediaQuery.of(context).size.width *
                                              26 /
                                              100,

                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6, horizontal: 10),
                                      // width: MediaQuery.of(context).size.width * 20 / 100,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: AppColor.secondaryColor),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(
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
                                            child: Image.asset(
                                                AppImage.languageIcon),
                                          ),
                                          Padding(
                                            padding: language == 1
                                                ? const EdgeInsets.only(
                                                    right: 4.0)
                                                : const EdgeInsets.only(
                                                    left: 4.0),
                                            child: Text(
                                              languageName.toString(),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color:
                                                      AppColor.secondaryColor,
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16),
                                            ),
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                2 /
                                                100,
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                3.5 /
                                                100,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                3.5 /
                                                100,
                                            child: Image.asset(
                                              AppImage.redDownIcon,
                                              color: AppColor.secondaryColor,
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      4 /
                                      100,
                                ),

                                //my boat text
                                Container(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  child: Text(
                                    AppLanguage.aventraText[language],
                                    style: const TextStyle(
                                      color: AppColor.secondaryColor,
                                      fontFamily: AppFont.fontFamily,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      1 /
                                      100,
                                ),

                                //welcome text
                                Container(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  child: Text(
                                    AppLanguage.welcomeText[language],
                                    style: const TextStyle(
                                      color: AppColor.secondaryColor,
                                      fontFamily: AppFont.fontFamily,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 40,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      1 /
                                      100,
                                ),

                                //login text
                                Container(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  child: Text(
                                    AppLanguage.logInText[language],
                                    style: const TextStyle(
                                      color: AppColor.secondaryColor,
                                      fontFamily: AppFont.fontFamily,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 36,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      3 /
                                      100,
                                ),

                                //email field
                                Center(
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        90 /
                                        100,
                                    height: MediaQuery.of(context).size.height *
                                        6 /
                                        100,
                                    child: TextFormField(
                                      readOnly: false,
                                      style: const TextStyle(
                                          color: AppColor.secondaryColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily),
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      keyboardType: TextInputType.text,
                                      controller: emailTextEditingController,
                                      maxLength: AppConstant.fullnameLength,
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColor.secondaryColor,
                                              width: 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                        ),
                                        enabledBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColor.secondaryColor,
                                              width: 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColor.secondaryColor,
                                              width: 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical:
                                                screenWidth > 600 ? 35 : 5,
                                            horizontal: 15),
                                        filled: false,
                                        counterText: '',
                                        hintText: AppLanguage
                                            .emailInputText[language],
                                        hintStyle: const TextStyle(
                                            color: AppColor.secondaryColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: AppFont.fontFamily),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        3 /
                                        100),

                                // ----------- Password Text Input -------------
                                Center(
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        90 /
                                        100,
                                    height: MediaQuery.of(context).size.height *
                                        6 /
                                        100,
                                    child: TextFormField(
                                      style: const TextStyle(
                                          color: AppColor.secondaryColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily),
                                      keyboardType: TextInputType.text,
                                      maxLength: AppConstant.fullnameLength,
                                      controller: passwordTextEditingController,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      obscureText: passwordVisible,
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColor.secondaryColor,
                                              width: 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                        ),
                                        enabledBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColor.secondaryColor,
                                              width: 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColor.secondaryColor,
                                              width: 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                        ),
                                        suffixIcon: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  passwordVisible =
                                                      !passwordVisible;
                                                });
                                              },
                                              child: Container(
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
                                                  passwordVisible
                                                      ? AppImage.showEyeIcon
                                                      : AppImage.hideEyeIcon,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 5, horizontal: 15),
                                        fillColor: AppColor.secondaryColor,
                                        filled: false,
                                        counterText: '',
                                        hintText: AppLanguage
                                            .passwordInputText[language],
                                        hintStyle: const TextStyle(
                                            color: AppColor.secondaryColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: AppFont.fontFamily),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        2 /
                                        100),

                                //forget pass
                                Container(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const ForgotPassword()),
                                          );
                                        },
                                        child: Text(
                                          AppLanguage
                                              .forgotPasswordText[language],
                                          style: TextStyle(
                                              fontSize:
                                                  screenWidth > 600 ? 20 : 14,
                                              color: AppColor.secondaryColor,
                                              fontFamily: AppFont.fontFamily,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        3 /
                                        100),

                                //login and guest button
                                Container(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          isGuest = false;
                                          signInValidation(
                                              emailTextEditingController.text,
                                              passwordTextEditingController
                                                  .text);
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              6.5 /
                                              100,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              41 /
                                              100,
                                          decoration: BoxDecoration(
                                            color: AppColor.themeColor,
                                            borderRadius:
                                                BorderRadius.circular(50),
                                          ),
                                          child: Text(
                                            AppLanguage.logInText[language],
                                            style: TextStyle(
                                                fontSize:
                                                    screenWidth > 600 ? 20 : 16,
                                                color: AppColor.secondaryColor,
                                                fontFamily: AppFont.fontFamily,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              8 /
                                              100),
                                      GestureDetector(
                                        onTap: () {
                                          isGuest = true;
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const MyFooterPage()));
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              6.5 /
                                              100,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              41 /
                                              100,
                                          decoration: BoxDecoration(
                                            color: AppColor.themeColor,
                                            borderRadius:
                                                BorderRadius.circular(50),
                                          ),
                                          child: Text(
                                            AppLanguage.guestText[language],
                                            style: TextStyle(
                                                fontSize:
                                                    screenWidth > 600 ? 20 : 16,
                                                color: AppColor.secondaryColor,
                                                fontFamily: AppFont.fontFamily,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        3 /
                                        100),

                                //contact using text
                                Container(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  child: Text(
                                    AppLanguage.contactUsingText[language],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: AppColor.secondaryColor,
                                        fontSize: screenWidth > 600 ? 20 : 14,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: AppFont.fontFamily),
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        3 /
                                        100),

                                //google apple icon
                                Container(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (isApiCalling) return;
                                          isGuest = false;
                                          deviceType = "google";
                                          setState(() {
                                            isApiCalling = true;
                                          });
                                          _googleSignIn.disconnect();
                                          _handleSignIn();
                                        },
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              14 /
                                              100,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              14 /
                                              100,
                                          child:
                                              Image.asset(AppImage.googleIcon),
                                        ),
                                      ),
                                      if (AppConstant.deviceType == "ios")
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                4 /
                                                100),
                                      if (AppConstant.deviceType == "ios")
                                        GestureDetector(
                                          onTap: () {
                                            if (isApiCalling) return;
                                            isGuest = false;
                                            deviceType = "apple";
                                            setState(() {
                                              isApiCalling = true;
                                            });
                                            signinWithApple();
                                          },
                                          child: Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                14 /
                                                100,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                14 /
                                                100,
                                            child:
                                                Image.asset(AppImage.appleIcon),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        3 /
                                        100),

                                Container(
                                  width: MediaQuery.of(context).size.width *
                                      90 /
                                      100,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppLanguage.doNothaveText[language] +
                                            "",
                                        style: TextStyle(
                                            color: AppColor.secondaryColor,
                                            fontSize:
                                                screenWidth > 600 ? 20 : 14,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: AppFont.fontFamily),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const Signup()));
                                        },
                                        child: Text(
                                          AppLanguage.signUpText[language],
                                          style: TextStyle(
                                              color: AppColor.themeColor,
                                              fontSize:
                                                  screenWidth > 600 ? 20 : 14,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: AppFont.fontFamily),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const NoInternetBanner(),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============set social login==========//
  localstroge() async {
    print("jhdgfjhdjdhg");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('socialdata', "");
    if (_currentUser != null) {
      var data = {
        "email": _currentUser!.email,
        "name": _currentUser!.displayName,
        "id": _currentUser!.id,
        "code": _currentUser!.serverAuthCode,
        "image": _currentUser!.photoUrl,
        "logintype": "google"
      };

      chackUserId(data, "google");
    } else {
      print("rohit");
    }
  }

  Future<void> _handleSignOut() => _googleSignIn.disconnect();

  // =================checkUser===========//
  chackUserId(data, type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String playeID = await OneSignalService.getPlayerId();
    log("playerId753 $playeID");
    setState(() {
      isApiCalling = true;
    });
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}social_login_user");
    print("Url $url");
    setState(() {
      isApiCalling = true;
    });
    try {
      var headers = {
        'token': AppConstant.token,
      };
      var body = {
        'social_type': type,
        'social_id': data['id'].toString(),
        'device_type': AppConstant.deviceType.toString(),
        'player_id': playeID,
        'social_email': data['email']
      };
      http.Response response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      print(body);
      print("response--> $response");
      var res = jsonDecode(response.body);

      print("res780: $res");

      if (response.statusCode == 200) {
        // return false;
        if (res['success'] == true) {
          if (res['user_exist'] == "yes") {
            prefs.setString("userDetails", jsonEncode(res['userDataArray']));
            //  if (res['userDataArray']['profile_complete'] == 1) {
            AppConstant.token = res['token'];
            AppConstant.selectFooterIndex = 0;
            APIs.user_id = res['userDataArray']['user_id'].toString();
            if (await userExists(res['userDataArray']['user_id']) && mounted) {
              print("mounted $mounted");
              Future.delayed(
                  const Duration(seconds: 2),
                  () => {
                        setState(() {}),
                        AppConstant.selectFooterIndex = 0,
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyFooterPage()),
                        ),
                        setState(() {
                          isApiCalling = false;
                        }),
                      });
            } else {
              createUser(res['userDataArray']['user_id'], res['userDataArray']);
              Future.delayed(
                  const Duration(seconds: 2),
                  () => {
                        AppConstant.selectFooterIndex = 0,
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyFooterPage()),
                        ),
                        setState(() {
                          isApiCalling = false;
                        }),
                      });
            }
            // ignore: use_build_context_synchronously
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          } else {
            var appledata = {
              "email": data['email'],
              "id": data['id'],
              "name": data['name'],
              "logintype": "apple"
            };
            prefs.setString('appledata', jsonEncode(appledata));
            prefs.setString('socialdata', jsonEncode(data));
            log("API1");
            signUpUserApiCall(
                data['name'], data['email'], deviceType, data['id']);
            if (res['active_status'] == 0) {
              Future.delayed(const Duration(milliseconds: 300), () async {
                // ignore: use_build_context_synchronously
                SnackBarToastMessage.showSnackBar(
                    context, res['msg'][language]);
              });
              log("API2");
              signUpUserApiCall(
                data['name'],
                data['email'],
                deviceType,
                data['id'],
              );
            }
          }
        } else {
          var appledata = {
            "email": data['email'],
            "id": data['id'],
            "name": data['name'],
            "logintype": "apple"
          };
          prefs.setString('appledata', jsonEncode(appledata));
          prefs.setString('socialdata', jsonEncode(data));
          log("API3");
          signUpUserApiCall(
              data['name'], data['email'], deviceType, data['id']);

          if (res['active_status'] == 0) {
            Future.delayed(const Duration(milliseconds: 300), () async {
              // ignore: use_build_context_synchronously
              SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            });

            // ignore: use_build_context_synchronously
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
            setState(() {
              isApiCalling = false;
            });
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

  Future<void> _handleSignIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null && mounted) {
        setState(() {
          isApiCalling = false;
        });
      }
    } catch (error) {
      print("error44$error");
      if (mounted) {
        setState(() {
          isApiCalling = false;
        });
      }
    }
  }

  signinWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final userId = credential.userIdentifier;
      final name = credential.givenName;
      final email = credential.email;

      print("Apple ID Credential: $credential");

      // Step 1: Check if Apple ID exists in backend
      Uri url =
          Uri.parse("${AppConfigProvider.apiUrl}validate_apple?apple_id=$userId");
      print("Calling Apple Data API: $url");

      String token = AppConstant.token;
      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);
      print("API Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print("Decoded API Response: $res");

        if (res['success'] == true && res['user_arr'] != null) {
          final userData = res['user_arr'];

          var data = {
            "email": userData['email'] ?? "",
            "name": userData['name'] ?? "",
            "id": userId,
            "logintype": "apple"
          };

          // Optionally store locally
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('appledata', jsonEncode(data));

          await chackUserId(data, "apple");
        } else {
          if (name != null && email != null) {
            var data = {
              "email": email,
              "name": name,
              "id": userId,
              "logintype": "apple"
            };

            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('appledata', jsonEncode(data));

            await chackUserId(data, "apple");
          } else {
            SnackBarToastMessage.showSnackBar(context,
                "We couldn't retrieve your Apple account details. Please try again.");
            if (mounted) {
              setState(() {
                isApiCalling = false;
              });
            }
          }
        }
      } else {
        SnackBarToastMessage.showSnackBar(context, "Server error occurred.");
        if (mounted) {
          setState(() {
            isApiCalling = false;
          });
        }
      }
    } catch (e) {
      print("Apple login error: $e");
      SnackBarToastMessage.showSnackBar(context, "Login failed.");
      if (mounted) {
        setState(() {
          isApiCalling = false;
        });
      }
    }
  }

  checkapple(id) async {
    setState(() {
      isApiCalling = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var appledata = prefs.getString('appledata');

    if (appledata != null) {
      var appledata1 = jsonDecode(appledata);
      print("object");

      var data = {
        "email": appledata1['email'],
        "name": appledata1['name'],
        "id": appledata1['id'],
        "logintype": "apple"
      };
// print(data)
      chackUserId(data, "apple");
    } else {
      var appledata1 = jsonDecode(appledata!);
      var data = {
        "email": "",
        "name": "",
        "id": appledata1['id'],
        "logintype": "apple"
      };
// print(data)
      chackUserId(data, "apple");
    }
    setState(() {
      isApiCalling = false;
    });
  }

  // ========apple localstorage===//
  applelocalstroge(name, email, id) async {
    print(name);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('socialdata', "");

    var data = {
      "email": email,
      "name": name,
      "id": id,
      "code": "",
      "image": "",
      "logintype": "apple"
    };
    chackUserId(data, "apple");
  }
}
