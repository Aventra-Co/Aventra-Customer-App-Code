import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_firebase.dart';
import '../../controller/app_font.dart';
import '../../controller/app_footer.dart';
import '../../controller/app_image.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../../controller/one_signal_service.dart';
import '../../helper/apis.dart';
import '../../model/chat_user.dart';
import '../authentication/login_screen.dart';
import '../authentication/notification_screen.dart';

class Splash extends StatefulWidget {
  static String routeName = './Splash';
  Splash({super.key});

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool status = false;
  String email = '';
  int languageId = 0;
  bool _isLoginSuccessful = false;
  bool _shouldNavigateToNotifications = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => getUserDetails());
  }

  // Check for pending OneSignal notifications
  void _checkPendingNotifications() {
    if (OneSignalService.hasPendingBroadcastNotification()) {
      _shouldNavigateToNotifications = true;
      print("Pending broadcast notification detected");
    }
  }

  // Handle navigation after login process
  void _handlePostLoginNavigation() {
    if (_hasNavigated) {
      log("Navigation already handled, skipping...");
      return;
    }

    _hasNavigated = true;

    log("=== Navigation Debug ===");
    log("Login successful: $_isLoginSuccessful");
    log("Should navigate to notifications: $_shouldNavigateToNotifications");
    log("========================");

    if (_isLoginSuccessful && _shouldNavigateToNotifications) {
      print("Navigating to notifications after successful login");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NotificationScreen()),
      );
      OneSignalService.clearPendingNotifications();
      log("Navigated to notifications - login successful");
    } else if (_isLoginSuccessful) {
      log("Navigating to home - login successful but no pending notifications");
      AppConstant.selectFooterIndex = 0;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MyFooterPage(),
        ),
      );
    } else {
      log("Navigating to login - login failed");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
  }

  //-------------------------------GET USER DETAILS-----------------------//
  Future<dynamic> getUserDetails() async {
    _checkPendingNotifications();

    final prefs = await SharedPreferences.getInstance();
    dynamic userDetails = prefs.getString("userDetails");
    dynamic password = prefs.getString("password");
    final String savedToken = prefs.getString("token") ?? "";
    if (savedToken.toString().trim().isNotEmpty) {
      AppConstant.token = savedToken.toString();
    }
    dynamic langId = prefs.getString("language_id");
    log("dfd$langId");

    if (langId != null) {
      languageId = int.parse(langId);
      if (languageId == 0) {
        language = 0;
      } else {
        language = 1;
      }
    } else {
      languageId = 0;
    }

    log("$userDetails");

    if (userDetails != null) {
      print("Line 42");
      dynamic data = json.decode(userDetails);
      email = data['email'];
      print("data['email'] $email");
      print("password $password");

      if (data['profile_complete'] == 1) {
        if (data['otp_verify'] == 1) {
          if (data['login_type'] == 0) {
            log("line51 - Normal Login ${data['login_type']}");
            final String p = password?.toString() ?? "";
            if (AppConstant.token.toString().trim().isNotEmpty) {
              _isLoginSuccessful = true;
              APIs.userArry = data;
              APIs.user_id = data['user_id'].toString();
              APIs.getSelfInfo();
              _handlePostLoginNavigation();
            } else if (p.trim().isEmpty) {
              _isLoginSuccessful = true;
              APIs.userArry = data;
              APIs.user_id = data['user_id'].toString();
              APIs.getSelfInfo();
              _handlePostLoginNavigation();
            } else {
              await _performNormalLogin(email, p);
            }
          } else {
            log("Social Login ${data['login_type']}");
            if (AppConstant.token.toString().trim().isNotEmpty) {
              _isLoginSuccessful = true;
              APIs.userArry = data;
              APIs.user_id = data['user_id'].toString();
              APIs.getSelfInfo();
              _handlePostLoginNavigation();
            } else {
              _isLoginSuccessful = true;
              APIs.userArry = data;
              APIs.user_id = data['user_id'].toString();
              APIs.getSelfInfo();
              _handlePostLoginNavigation();
            }
          }
        } else {
          _isLoginSuccessful = false;
          _handlePostLoginNavigation();
        }
      } else {
        _isLoginSuccessful = false;
        _handlePostLoginNavigation();
      }
    } else {
      _isLoginSuccessful = false;
      _handlePostLoginNavigation();
    }
  }

  // Normal login function
  Future<void> _performNormalLogin(String email, String password) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}sign_in");
    print("Url $url");

    try {
      final String playeID = await OneSignalService.getPlayerId();
      print("playeID line number 101 $playeID");
      http.MultipartRequest formData = http.MultipartRequest('POST', url);

      formData.fields['email'] = email.toString();
      formData.fields['password'] = password.toString();
      formData.fields['player_id'] = playeID.toString();
      formData.fields['device_type'] = AppConstant.deviceType.toString();

      log("formData.fields ${formData.fields}");

      http.StreamedResponse response = await formData.send();
      log("response--> $response");
      var responseString = await response.stream.toBytes();
      var res = jsonDecode(utf8.decode(responseString));

      if (response.statusCode == 200) {
        print("res : $res");
        if (res['success'] == true) {
          if (res['userDataArray'] != "NA") {
            _isLoginSuccessful = true;

            AppConstant.token = res['token'];
            print("AppConstant.token ${AppConstant.token}");
            final prefs = await SharedPreferences.getInstance();
            print("prefs =================>$prefs");
            prefs.setString("userDetails", jsonEncode(res['userDataArray']));
            prefs.setString("token", res['token'].toString());
            FirebaseProvider.firebaseCreateUser(true);
            APIs.userArry = res['userDataArray'];
            APIs.user_id = res['userDataArray']['user_id'].toString();
            APIs.getSelfInfo();

            print("kfjjg${AppConstant.playerID}");
            await updateUser(res['userDataArray'],
                res['userDataArray']['user_id'], playeID);

            if (await userExists(res['userDataArray']['user_id']) && mounted) {
              print("mounted $mounted");
            } else {
              await createUser(
                  res['userDataArray']['user_id'], res['userDataArray']);
            }

            _handlePostLoginNavigation();
          } else {
            _isLoginSuccessful = false;
            _handlePostLoginNavigation();
          }
        } else {
          _isLoginSuccessful = false;
          _handlePostLoginNavigation();
        }
      } else {
        _isLoginSuccessful = false;
        _handlePostLoginNavigation();
      }
    } catch (e) {
      print("Normal login error: $e");
      _isLoginSuccessful = false;
      _handlePostLoginNavigation();
    }
  }

  // Social login function
  Future<void> _performSocialLogin(
      dynamic data, SharedPreferences prefs) async {
    print("Starting social login...");
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}social_login_user");
    print("Url $url");

    try {
      final String playeID = await OneSignalService.getPlayerId();
      var headers = {
        'token': AppConstant.token,
      };
      var body = {
        'social_type': "google",
        'social_id': data['google_id'].toString(),
        'device_type': AppConstant.deviceType.toString(),
        'player_id': playeID,
        'social_email': data['email']
      };

      http.Response response =
          await http.post(url, headers: headers, body: body);

      print(body);
      print("response--> $response");
      var res = jsonDecode(response.body);
      print("res780: $res");

      if (response.statusCode == 200) {
        if (res['success'] == true) {
          if (res['user_exist'] == "yes") {
            log("Social login successful - user exists");
            _isLoginSuccessful = true;

            _handlePostLoginNavigation();

            prefs.setString("userDetails", jsonEncode(res['userDataArray']));
            AppConstant.token = res['token'];
            AppConstant.selectFooterIndex = 0;
            APIs.user_id = res['userDataArray']['user_id'].toString();
            APIs.getSelfInfo();

            if (await userExists(res['userDataArray']['user_id']) && mounted) {
              print("mounted $mounted");
            } else {
              await createUser(
                  res['userDataArray']['user_id'], res['userDataArray']);
            }

            if (mounted) {
              SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            }
          } else {
            log("Social login - user doesn't exist, redirect to signup");
            _isLoginSuccessful = false;

            var appledata = {
              "email": data['email'],
              "id": data['id'],
              "name": data['name'],
              "logintype": "apple"
            };
            prefs.setString('appledata', jsonEncode(appledata));
            prefs.setString('socialdata', jsonEncode(data));

            if (res['active_status'] == 0) {
              Future.delayed(const Duration(milliseconds: 300), () async {
                if (mounted) {
                  SnackBarToastMessage.showSnackBar(
                      context, res['msg'][language]);
                }
              });
            }

            _handlePostLoginNavigation();
          }
        } else {
          log("Social login failed - API returned success: false");
          _isLoginSuccessful = false;

          var appledata = {
            "email": data['email'],
            "id": data['apple_id'],
            "name": data['name'],
            "logintype": "apple"
          };
          prefs.setString('appledata', jsonEncode(appledata));
          prefs.setString('socialdata', jsonEncode(data));

          if (res['active_status'] == 0) {
            Future.delayed(const Duration(milliseconds: 300), () async {
              if (mounted) {
                SnackBarToastMessage.showSnackBar(
                    context, res['msg'][language]);
              }
            });
          }

          _handlePostLoginNavigation();
        }
      } else {
        log("Social login failed - HTTP error: ${response.statusCode}");
        _isLoginSuccessful = false;
        _handlePostLoginNavigation();
      }
    } catch (e) {
      print("Social login error: $e");
      _isLoginSuccessful = false;
      _handlePostLoginNavigation();
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
    print("User exists: $exists");
    return exists;
  }

  static Future<void> updateUser(var usserArrey, userId, playerId) async {
    print("userId$userId");
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light));
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width * 100 / 100,
        height: MediaQuery.of(context).size.height * 100 / 100,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImage.newSplash),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  width: MediaQuery.of(context).size.width * 40 / 100,
                  height: MediaQuery.of(context).size.width * 40 / 100,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(1000),
                      child: Image.asset(AppImage.appIcon))),
              if (_shouldNavigateToNotifications)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    "Processing notification...",
                    style: TextStyle(
                        fontFamily: AppFont.fontFamily,
                        fontSize: 14,
                        color: AppColor.themeColor.withOpacity(0.7)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget build(BuildContext context) {
  //   SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  //       statusBarColor: AppColor.transparentColor,
  //       statusBarIconBrightness: Brightness.dark));
  //   return Scaffold(
  //     body: Container(
  //       width: MediaQuery.of(context).size.width * 100 / 100,
  //       height: MediaQuery.of(context).size.height * 100 / 100,
  //       child: Stack(
  //         children: [
  //           Image.asset(
  //             AppImage.newSplashVideo,
  //             fit: BoxFit.cover,
  //             width: double.infinity,
  //             height: double.infinity,
  //           ),
  //           if (_shouldNavigateToNotifications)
  //             Positioned(
  //               bottom: 100,
  //               left: 0,
  //               right: 0,
  //               child: Center(
  //                 child: Container(
  //                   padding: const EdgeInsets.symmetric(
  //                       horizontal: 20, vertical: 10),
  //                   decoration: BoxDecoration(
  //                     color: Colors.black.withOpacity(0.7),
  //                     borderRadius: BorderRadius.circular(20),
  //                   ),
  //                   child: const Text(
  //                     "Processing notification...",
  //                     style: TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 14,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
