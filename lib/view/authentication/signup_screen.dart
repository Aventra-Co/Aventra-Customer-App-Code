import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/app_button.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_firebase.dart';
import '../../controller/app_font.dart';
// import '../../controller/app_footer.dart';
import '../../controller/app_header.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../../controller/custom_input.dart';
import '../../controller/custom_password.dart';
import '../../helper/apis.dart';
import '../../model/chat_user.dart';
import '../content_screen/content_screen.dart';
import 'login_screen.dart';
import 'otp_verify_screen.dart';

class Signup extends StatefulWidget {
  static String routeName = "./Signup";
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController firstnameTextEditingController =
      TextEditingController();
  TextEditingController lastnameTextEditingController = TextEditingController();
  TextEditingController citynameTextEditingController = TextEditingController();
  TextEditingController countrynameTextEditingController =
      TextEditingController();
  TextEditingController dobTextEditingController = TextEditingController();
  TextEditingController mobileTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController confirmpasswordTextEditingController =
      TextEditingController();
  TextEditingController countrySearchTextEditingController =
      TextEditingController();
  TextEditingController searchTextEditingController = TextEditingController();
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  String getDate = '';
  String sendDate = '';
  var cityName;
  var cityId;
  var countryName;
  var countryId;
  List<dynamic> cityList = [];
  List<dynamic> countryList = [];
  List<dynamic> citySearchList = [];
  List<dynamic> countrySearchList = [];
  bool isApiCalling = false;
  String shareWith = "";
  String termsandconditionstype = "";
  String privacypolicytype = "";
  String aboutustype = "";
  String rateappurl = "";
  int userId = 0;
  int isPayment = 0;

  //!---------------------SEARCH FUNCTION COUNTRY--------------------//!/
  searchResultCountry(String query) {
    print(query);

    var results1 = countrySearchList
        .where((value) => value['country_name'][language]
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    print("results1 $results1");

    countryList = [];

    countryList = results1;

    setState(() {});
  }

//!---------------------SEARCH FUNCTION CITY--------------------//!/
  searchResultCity(String query) {
    print(query);

    var results1 = citySearchList
        .where((value) => value['city_name'][language]
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    print("results1 $results1");

    cityList = [];

    cityList = results1;

    setState(() {});
  }

  //!-----------------GET CITIES API CALL-----------------//!
  Future<void> getCities() async {
    Uri url = Uri.parse(
        "${AppConfigProvider.apiUrl}fetch_city_by_country?country_id=$countryId");
    print("url $url");

    Map<String, String> headers = ({
      'Content-Type': 'application/json',
    });
    try {
      final http.Response response = await http.get(
        url,
        headers: headers,
      );
      print("Runn");
      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print(res);
        if (res['success'] == true) {
          print(response.statusCode);
          var item = res['city_arr'];
          print("item $item");
          if (item != "NA") {
            setState(() {
              cityList = item;
              citySearchList = item;
            });
          } else {
            setState(() {
              cityList = [];
              citySearchList = [];
            });
          }

          //! findCountry();

          print("countryList $countryList");

          setState(() {
            isApiCalling = false;
          });
        } else {
          if (res['active_status'] == 0) {
            Future.delayed(const Duration(milliseconds: 100), () async {});
          }
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

//!-----------------GET COUNTRIES API CALL-----------------//!
  Future<void> getCountries() async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}fetch_country_list");
    print("url $url");

    Map<String, String> headers = ({
      'Content-Type': 'application/json',
    });
    try {
      final http.Response response = await http.get(
        url,
        headers: headers,
      );
      print("Runn");
      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print(res);
        if (res['success'] == true) {
          print(response.statusCode);
          var item = res['country_arr'];
          print("item $item");
          if (item != "NA") {
            setState(() {
              countryList = item;
              countrySearchList = item;
            });
          } else {
            setState(() {
              countryList = [];
              countrySearchList = [];
            });
          }

          //! findCountry();

          print("countryList $countryList");

          setState(() {
            isApiCalling = false;
          });
        } else {
          if (res['active_status'] == 0) {
            Future.delayed(const Duration(milliseconds: 100), () async {});
          }
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

  //!=============================Payment API===================================//
  Future<void> paymentStatusApiCall() async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}payment_hide_show");
    print("url $url");
    String token = AppConstant.token;

    if (token.isEmpty) {
      print("Token is missing!");
      // return;
    }

    Map<String, String> headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);
      print("response $response");

      if (response.statusCode == 200) {
        dynamic res = jsonDecode(response.body);
        print("res $res");

        if (res['success'] == true) {
          setState(() {
            isPayment = res['payment_data']['payment_status'];
          });
        } else {
          // ignore: use_build_context_synchronously
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Login()));
          }
        }
      } else {}
    } catch (e) {
      setState(() {
        isApiCalling = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    paymentStatusApiCall();
    getAllContent();
    getCountries();
  }

  //!-----------------GET CONTENT API CALL-----------------//!
  Future<void> getAllContent() async {
    Uri url =
        Uri.parse('${AppConfigProvider.apiUrl}get_all_content?language_id=0');
    print("url $url");

    try {
      final response = await http.get(
        url,
      );

      dynamic res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        //! print("res $res");
        if (res['success'] == true) {
          setState(() {
            isApiCalling = false;
          });
          List data = res['content_arr'];
          for (var i = 0; i < data.length; i++) {
            if (data[i]['content_type'] == 5) {
              setState(() {
                shareWith = data[i]['content'];
              });
              print("share app ${data[i]['content']}");
            }
            if (data[i]['content_type'] == 2) {
              var url1 = data[i]['content_url'];

              setState(() {
                termsandconditionstype = url1;
              });
              log('$termsandconditionstype');
            }

            if (data[i]['content_type'] == 1) {
              var url1 = data[i]['content_url'];

              setState(() {
                privacypolicytype = url1;
              });
              print('289 privacy');
            }
            if (data[i]['content_type'] == 0) {
              var url1 = data[i]['content_url'];

              setState(() {
                aboutustype = url1;
              });
              print('289 about');
            }

            if (AppConstant.deviceType == 'android') {
              if (data[i]['content_type'] == 4) {
                var androidurl = data[i]['content'];

                setState(() {
                  rateappurl = androidurl;
                });
              }
            }

            if (AppConstant.deviceType == 'ios') {
              if (data[i]['content_type'] == 3) {
                var iosurl = data[i]['content'];

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

  //!-------------------------------SIGN UP VALIDATION---------------------------------//!
  void signUpValidation(
    String firstName,
    String lastName,
    String country,
    String city,
    String dob,
    String mobile,
    String email,
    String password,
    String confirmpassword,
  ) {
    if (firstName.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.firstNameMessage[language]);
      return;
    } else if (lastName.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.lastNameMessage[language]);
      return;
    } else if (country.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.countryMsg[language]);
      return;
    } else if (city.isEmpty) {
      SnackBarToastMessage.showSnackBar(context, AppLanguage.cityMsg[language]);
      return;
    } else if (dob.isEmpty) {
      SnackBarToastMessage.showSnackBar(context, AppLanguage.dobMsg[language]);
      return;
    } else if (mobile.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.mobileNumberMessage[language]);
      return;
    } else if (mobile.length < 7) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.mobilevalidMessage[language]);
      return;
    } else if (email.isEmpty) {
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
    } else if (password.length < 6) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.passwordMinMessage[language]);
    } else if (confirmpassword.isEmpty) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.repeatPasswordMsg[language]);
    } else if (confirmpassword.length < 6) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.passwordMinMessage[language]);
    } else if (password != confirmpassword) {
      SnackBarToastMessage.showSnackBar(
          context, AppLanguage.passwordandConfirmpassMessage[language]);
    } else {
      //! If validation passes, call the API
      signUpUserApiCall(firstName, lastName, email, mobile, password);
    }
  }

//!-------------------------------SIGN UP API CALL-------------------//!
  signUpUserApiCall(
    String firstName,
    String lastName,
    String emailAddress,
    String mobile,
    String password,
  ) async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}sign_up");

    print("Url $url");

    setState(() {
      isApiCalling = true;
    });

    try {
      String playeID = AppConstant.playerID.toString();
      print("playeID line number 101 $playeID");
      http.MultipartRequest formData = http.MultipartRequest('POST', url);

      formData.fields['f_name'] = firstName.toString();
      formData.fields['l_name'] = lastName.toString();
      formData.fields['email'] = emailAddress;
      formData.fields['mobile'] = mobile.toString();
      formData.fields['password'] = password;
      formData.fields['dob'] = isPayment == 0 ? "2025-12-24" : sendDate;
      formData.fields['city_id'] = isPayment == 0 ? "120" : cityId.toString();
      formData.fields['country_id'] =
          isPayment == 0 ? "89" : countryId.toString();
      formData.fields['user_type'] = "1";
      formData.fields['player_id'] = playeID.toString();
      formData.fields['device_type'] = AppConstant.deviceType;
      formData.fields['login_type'] = "app";

      print("Fields130--> ${formData.fields}");

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
          log("success145");
          if (data != "NA") {
            log("success147");
            final prefs = await SharedPreferences.getInstance();
            print("prefs =================>$prefs");
            prefs.setString("userDetails", jsonEncode(res['userDataArray']));
            prefs.setString("password", password);
            prefs.setString("token", res['token'].toString());
            log("storage${prefs.getString("userDetails")}");
            FirebaseProvider.firebaseCreateUser(true);
            APIs.userArry = res['userDataArray'];
            APIs.user_id = res['userDataArray']['user_id'].toString();

            if (await userExists(res['userDataArray']['user_id']) && mounted) {
              print("mounted $mounted");
              AppConstant.selectFooterIndex = 0;
            } else {
              createUser(res['userDataArray']['user_id'], res['userDataArray']);
              AppConstant.selectFooterIndex = 0;
            }

            log("success");
            userId = data['user_id'];
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            log("SignupID$userId");
            Navigator.pushNamed(context, SignUpOtpVerifyHeader.routeName,
                arguments: ResetPasswordIdClass(userId: userId.toString()));
            setState(() {
              isApiCalling = false;
            });
          }
          setState(() {
            isApiCalling = false;
          });
        } else {
          //! ignore: use_build_context_synchronously
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
          setState(() {
            isApiCalling = false;
          });
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
        statusBarColor: AppColor.transparentColor,
        statusBarIconBrightness: Brightness.dark));
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColor.secondaryColor,
        body: SizedBox(
          width: MediaQuery.of(context).size.width * 100 / 100,
          height: MediaQuery.of(context).size.height * 100 / 100,
          child: Column(
            children: [
              const NoInternetBanner(),
              Stack(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 100 / 100,
                    padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height * 12 / 100,
                        horizontal:
                            MediaQuery.of(context).size.width * 5 / 100),
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(AppImage.signUpIcon),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30))),
                  ),
                  Positioned(
                    left: MediaQuery.of(context).size.width * 40 / 100,
                    top: MediaQuery.of(context).size.height * 4.5 / 100,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 20 / 100,
                      height: screenWidth > 600
                          ? null
                          : MediaQuery.of(context).size.height * 10 / 100,
                      child: Image.asset(
                        AppImage.appIcon,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 2 / 100),
              Expanded(
                  child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 2 / 100),

                    SizedBox(
                      width: MediaQuery.of(context).size.width * 90 / 100,
                      child: Text(
                        AppLanguage.createAccountText[language],
                        style: const TextStyle(
                          color: AppColor.primaryColor,
                          fontFamily: AppFont.fontFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 36,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 1 / 100,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 90 / 100,
                      child: Text(
                        AppLanguage.joinUsText[language],
                        style: const TextStyle(
                          color: AppColor.textColor,
                          fontFamily: AppFont.fontFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 3 / 100),

                    //!------------------first name---------------------
                    CustomTextFormField(
                        readOnly: false,
                        fillColorStatus: 0,
                        controller: firstnameTextEditingController,
                        hintText: AppLanguage.firstNameInputText[language],
                        image: AppImage.profileIcon,
                        keyboardtype: TextInputType.name,
                        maxLength: AppConstant.fullnameLength),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 2 / 100),

                    //!------------------last name---------------------
                    CustomTextFormField(
                        readOnly: false,
                        fillColorStatus: 0,
                        controller: lastnameTextEditingController,
                        hintText: AppLanguage.lastNameInputText[language],
                        image: AppImage.profileIcon,
                        keyboardtype: TextInputType.name,
                        maxLength: AppConstant.fullnameLength),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 2 / 100),

                    if (isPayment == 1) ...[
                      //!------------------country name---------------------
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 90 / 100,
                          height: MediaQuery.of(context).size.height * 6 / 100,
                          child: TextFormField(
                            readOnly: true,
                            style: AppConstant.textFilledHeading,
                            textAlignVertical: TextAlignVertical.center,
                            //! keyboardType: keyboardtype,
                            controller: countrynameTextEditingController,
                            onTap: () {
                              countryListBottomSheet(context, screenWidth);
                            },
                            decoration: InputDecoration(
                              prefixIcon: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    child: Image.asset(
                                      AppImage.locationIcon,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              5 /
                                              100,
                                      width: MediaQuery.of(context).size.width *
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
                                      AppImage.downArrowIcon,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              4 /
                                              100,
                                      width: MediaQuery.of(context).size.width *
                                          4 /
                                          100,
                                    ),
                                  ),
                                ],
                              ),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColor.textinputBorderColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColor.textinputBorderColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColor.textinputBorderColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 15),
                              filled: false,
                              counterText: '',
                              hintText: AppLanguage.countryText[language],
                              hintStyle: const TextStyle(
                                  color: AppColor.hintTextinputColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: AppFont.fontFamily),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 2 / 100),

                      //!------------------city name---------------------
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 90 / 100,
                          height: MediaQuery.of(context).size.height * 6 / 100,
                          child: TextFormField(
                            readOnly: true,
                            style: AppConstant.textFilledHeading,
                            textAlignVertical: TextAlignVertical.center,
                            //! keyboardType: keyboardtype,
                            controller: citynameTextEditingController,
                            onTap: () {
                              cityListBottomSheet(context, screenWidth);
                            },
                            decoration: InputDecoration(
                              prefixIcon: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    child: Image.asset(
                                      AppImage.locationIcon,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              5 /
                                              100,
                                      width: MediaQuery.of(context).size.width *
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
                                      AppImage.downArrowIcon,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              4 /
                                              100,
                                      width: MediaQuery.of(context).size.width *
                                          4 /
                                          100,
                                    ),
                                  ),
                                ],
                              ),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColor.textinputBorderColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColor.textinputBorderColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColor.textinputBorderColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 15),
                              filled: false,
                              counterText: '',
                              hintText: AppLanguage.cityNameInputText[language],
                              hintStyle: const TextStyle(
                                  color: AppColor.hintTextinputColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: AppFont.fontFamily),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 2 / 100),

                      //!-------------------dob----------------
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 90 / 100,
                          height: MediaQuery.of(context).size.height * 6 / 100,
                          child: TextFormField(
                            readOnly: true,
                            style: AppConstant.textFilledHeading,
                            textAlignVertical: TextAlignVertical.center,
                            //! keyboardType: keyboardtype,
                            controller: dobTextEditingController,
                            onTap: () async {
                              print(DateTime.now());
                              //! print(getDate);

                              DateTime today = DateTime.now();
                              DateTime minDate =
                                  today.subtract(Duration(days: 365 * 100));
                              DateTime maxDate =
                                  today.subtract(Duration(days: 365 * 16));

                              DateTime initialDate;
                              if (getDate.isEmpty ||
                                  getDate == "Invalid date") {
                                initialDate = today;
                              } else {
                                try {
                                  initialDate = DateTime.parse(getDate);
                                } catch (e) {
                                  initialDate = today;
                                  print(" $getDate");
                                }
                              }

                              if (initialDate.isBefore(minDate)) {
                                initialDate = minDate;
                              }
                              if (initialDate.isAfter(maxDate)) {
                                initialDate = maxDate;
                              }

                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: initialDate,
                                firstDate: minDate,
                                lastDate: maxDate,
                                builder: (BuildContext context, Widget? child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      primaryColor: AppColor.themeColor,
                                      colorScheme: const ColorScheme.light(
                                        primary: AppColor.themeColor,
                                        onPrimary: AppColor.secondaryColor,
                                      ),
                                      buttonTheme: const ButtonThemeData(
                                        textTheme: ButtonTextTheme.primary,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                            foregroundColor:
                                                AppColor.themeColor),
                                      ),
                                      backgroundColor: AppColor.themeColor,
                                      dialogBackgroundColor:
                                          AppColor.themeColor,
                                      highlightColor: AppColor.themeColor,
                                      textTheme: const TextTheme(
                                        bodyText2: TextStyle(
                                            color: AppColor.themeColor),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (pickedDate != null) {
                                String formattedDate =
                                    DateFormat('dd-MM-yyyy').format(pickedDate);
                                String sentFormatDate =
                                    DateFormat('yyyy-MM-dd').format(pickedDate);
                                print(formattedDate);
                                setState(() {
                                  getDate = formattedDate;
                                  sendDate = sentFormatDate;
                                  log("senddate$sendDate");
                                  dobTextEditingController.text = getDate;
                                });
                              } else {
                                print("No date selected");
                              }
                            },
                            decoration: InputDecoration(
                              prefixIcon: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    child: Image.asset(
                                      AppImage.dobIcon,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              5 /
                                              100,
                                      width: MediaQuery.of(context).size.width *
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
                                      AppImage.downArrowIcon,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              4 /
                                              100,
                                      width: MediaQuery.of(context).size.width *
                                          4 /
                                          100,
                                    ),
                                  ),
                                ],
                              ),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColor.textinputBorderColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColor.textinputBorderColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColor.textinputBorderColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 15),
                              filled: false,
                              counterText: '',
                              hintText: AppLanguage.dobInputText[language],
                              hintStyle: const TextStyle(
                                  color: AppColor.hintTextinputColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: AppFont.fontFamily),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 2 / 100),
                    ],

                    //!------------------mobile number---------------------
                    CustomTextFormField(
                        readOnly: false,
                        fillColorStatus: 0,
                        controller: mobileTextEditingController,
                        hintText: AppLanguage.mobileNumberInputText[language],
                        image: AppImage.phoneIcon,
                        keyboardtype: TextInputType.number,
                        maxLength: AppConstant.mobileLength),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 2 / 100),

                    //!------------email--------------
                    CustomTextFormField(
                        readOnly: false,
                        fillColorStatus: 0,
                        controller: emailTextEditingController,
                        hintText: AppLanguage.emailInputText[language],
                        image: AppImage.mailIcon,
                        keyboardtype: TextInputType.emailAddress,
                        maxLength: AppConstant.emailMaxLength),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 2 / 100),

                    //! ----------- Password Text Input -------------
                    CustomPasswordTextFormField(
                        readOnly: false,
                        fillColorStatus: 0,
                        controller: passwordTextEditingController,
                        hintText: AppLanguage.passwordInputText[language],
                        keyboardtype: TextInputType.text,
                        maxLength: AppConstant.passwordLength),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 2 / 100),

                    //! -----------confirm Password Text Input -------------
                    CustomPasswordTextFormField(
                        readOnly: false,
                        fillColorStatus: 0,
                        controller: confirmpasswordTextEditingController,
                        hintText:
                            AppLanguage.confirmPasswordInputText[language],
                        keyboardtype: TextInputType.text,
                        maxLength: AppConstant.passwordLength),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 3 / 100),

                    AppButton(
                        text: AppLanguage.createAccountText[language],
                        onPress: () {
                          signUpValidation(
                              firstnameTextEditingController.text,
                              lastnameTextEditingController.text,
                              countrynameTextEditingController.text,
                              citynameTextEditingController.text,
                              dobTextEditingController.text,
                              mobileTextEditingController.text,
                              emailTextEditingController.text,
                              passwordTextEditingController.text,
                              confirmpasswordTextEditingController.text);
                        }),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 3 / 100),

                    SizedBox(
                      width: MediaQuery.of(context).size.width * 100 / 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 80 / 100,
                            child: Text.rich(
                                textAlign: TextAlign.center,
                                TextSpan(children: [
                                  TextSpan(
                                      text:
                                          AppLanguage.bySigningUpText[language],
                                      style: const TextStyle(
                                          color: AppColor.textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: AppFont.fontFamily)),
                                  TextSpan(
                                      text: AppLanguage
                                          .termsConditionText[language],
                                      style: const TextStyle(
                                          color: AppColor.themeColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: AppFont.fontFamily,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColor.themeColor),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.pushNamed(
                                              context, Content.routeName,
                                              arguments: ContentClass(
                                                  header: AppLanguage
                                                          .termsConditionText[
                                                      language],
                                                  contenttype:
                                                      termsandconditionstype));
                                        }),
                                  TextSpan(
                                      text:
                                          " ${AppLanguage.andText[language]} ",
                                      style: const TextStyle(
                                          color: AppColor.textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: AppFont.fontFamily)),
                                  TextSpan(
                                      text: AppLanguage
                                          .privacyPolicyText[language],
                                      style: const TextStyle(
                                        color: AppColor.themeColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: AppFont.fontFamily,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColor.themeColor,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.pushNamed(
                                              context, Content.routeName,
                                              arguments: ContentClass(
                                                  header: AppLanguage
                                                          .privacyPolicyText[
                                                      language],
                                                  contenttype:
                                                      privacypolicytype));
                                        })
                                ])),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 2 / 100),

                    SizedBox(
                      width: MediaQuery.of(context).size.width * 90 / 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLanguage.alreadyAccountText[language],
                            style: const TextStyle(
                                color: AppColor.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFont.fontFamily),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const Login()));
                            },
                            child: Text(
                              AppLanguage.logInText[language],
                              style: const TextStyle(
                                  color: AppColor.themeColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppFont.fontFamily),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 1 / 100),

                    SizedBox(
                        height: MediaQuery.of(context).size.height * 2 / 100),
                  ],
                ),
              ))
            ],
          ),
        ),
      ),
    );
  }

  void countryListBottomSheet(BuildContext context, double screenWidth) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      constraints:
          BoxConstraints.expand(width: MediaQuery.of(context).size.width),
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Container(
                  height: MediaQuery.of(context).size.height * 100 / 100,
                  width: MediaQuery.of(context).size.width * 100 / 100,
                  decoration: const BoxDecoration(
                    //! color: Colors.white,
                    color: AppColor.secondaryColor,
                  ),
                  child: Column(children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 6 / 100,
                    ),
                    AppHeader(
                      text: AppLanguage.countryListText[language],
                      onPress: () {
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 90 / 100,
                      //! height: MediaQuery.of(context).size.height * 6.5 / 100,
                      child: TextFormField(
                        style: const TextStyle(
                            height: 0.9, color: AppColor.primaryColor),
                        keyboardType: TextInputType.text,
                        maxLength: AppConstant.searchLength,
                        maxLines: 1,
                        controller: countrySearchTextEditingController,
                        onChanged: (input) {
                          setState(() {
                            if (input.isNotEmpty) {
                              searchResultCountry(input);
                            } else {
                              countryList = countrySearchList;
                            }
                          });
                        },
                        decoration: InputDecoration(
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 0.7,
                                color: AppColor.textinputBorderColor,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(35)),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 0.7,
                                color: AppColor.textinputBorderColor,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(35)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 0.7,
                                color: AppColor.textinputBorderColor,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(35)),
                            ),
                            prefixIcon: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.width *
                                      5 /
                                      100,
                                  width: MediaQuery.of(context).size.width *
                                      5 /
                                      100,
                                  child: Image.asset(
                                    AppImage.searchIcon,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                            fillColor: AppColor.themeColor,
                            counterText: '',
                            hintText: AppLanguage.searchInputText[language],
                            hintStyle: const TextStyle(
                                color: AppColor.textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFont.fontFamily)),
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 4 / 100),
                    Expanded(
                      child: SingleChildScrollView(
                          child: Wrap(children: [
                        ...List.generate(
                          countryList.length,
                          (index) => GestureDetector(
                            onTap: () {
                              selectCountry(
                                  index,
                                  countryList[index]["country_name"][language],
                                  countryList[index]["country_id"]);
                              Navigator.pop(context);
                            },
                            child: Container(
                                alignment: Alignment.centerLeft,
                                margin: EdgeInsets.symmetric(vertical: 8),
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          78 /
                                          100,
                                      child: Text(
                                        countryList[index]["country_name"]
                                            [language],
                                        style: TextStyle(
                                            color: AppColor.textColor,
                                            fontFamily: AppFont.fontFamily,
                                            fontSize:
                                                screenWidth > 600 ? 20 : 15,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    if (countryList[index]["country_id"] ==
                                        countryId)
                                      const Icon(
                                        Icons.check,
                                        color: AppColor.themeColor,
                                        size: 25,
                                      ),
                                  ],
                                )),
                          ),
                        )
                      ])),
                    )
                  ])),
            );
          },
        );
      },
    );
  }

  void cityListBottomSheet(BuildContext context, double screenWidth) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      constraints:
          BoxConstraints.expand(width: MediaQuery.of(context).size.width),
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Container(
                  height: MediaQuery.of(context).size.height * 100 / 100,
                  width: MediaQuery.of(context).size.width * 100 / 100,
                  decoration: const BoxDecoration(
                    //! color: Colors.white,
                    color: AppColor.secondaryColor,
                  ),
                  child: Column(children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 6 / 100,
                    ),
                    AppHeader(
                      text: AppLanguage.cityListText[language],
                      onPress: () {
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 90 / 100,
                      //! height: MediaQuery.of(context).size.height * 6.5 / 100,
                      child: TextFormField(
                        style: const TextStyle(
                            height: 0.9, color: AppColor.primaryColor),
                        keyboardType: TextInputType.text,
                        maxLength: AppConstant.searchLength,
                        maxLines: 1,
                        controller: searchTextEditingController,
                        onChanged: (input) {
                          setState(() {
                            if (input.isNotEmpty) {
                              searchResultCity(input);
                            } else {
                              cityList = citySearchList;
                            }
                          });
                        },
                        decoration: InputDecoration(
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 0.7,
                                color: AppColor.textinputBorderColor,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(35)),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 0.7,
                                color: AppColor.textinputBorderColor,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(35)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 0.7,
                                color: AppColor.textinputBorderColor,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(35)),
                            ),
                            prefixIcon: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.width *
                                      5 /
                                      100,
                                  width: MediaQuery.of(context).size.width *
                                      5 /
                                      100,
                                  child: Image.asset(
                                    AppImage.searchIcon,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                            fillColor: AppColor.themeColor,
                            counterText: '',
                            hintText: AppLanguage.searchInputText[language],
                            hintStyle: const TextStyle(
                                color: AppColor.textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFont.fontFamily)),
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 4 / 100),
                    Expanded(
                      child: SingleChildScrollView(
                          child: Wrap(children: [
                        ...List.generate(
                          cityList.length,
                          (index) => GestureDetector(
                            onTap: () {
                              selectcity(
                                  index,
                                  cityList[index]["city_name"][language],
                                  cityList[index]["city_id"]);
                              Navigator.pop(context);
                            },
                            child: Container(
                                alignment: Alignment.centerLeft,
                                margin: EdgeInsets.symmetric(vertical: 8),
                                width: MediaQuery.of(context).size.width *
                                    90 /
                                    100,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          78 /
                                          100,
                                      child: Text(
                                        cityList[index]["city_name"][language],
                                        style: TextStyle(
                                            color: AppColor.textColor,
                                            fontFamily: AppFont.fontFamily,
                                            fontSize:
                                                screenWidth > 600 ? 20 : 15,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    if (cityList[index]["city_id"] == cityId)
                                      const Icon(
                                        Icons.check,
                                        color: AppColor.themeColor,
                                        size: 25,
                                      ),
                                  ],
                                )),
                          ),
                        )
                      ])),
                    )
                  ])),
            );
          },
        );
      },
    );
  }

  selectcity(index, name, id) {
    setState(() {
      cityId = id;
      cityName = name;
      citynameTextEditingController.text = cityName;
    });
  }

  selectCountry(index, name, id) {
    setState(() {
      countryId = id;
      countryName = name;
      countrynameTextEditingController.text = countryName;
      citynameTextEditingController.clear();
      getCities();
    });
  }
}
