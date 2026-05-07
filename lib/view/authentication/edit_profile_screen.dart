import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../controller/app_button.dart';
import '../../controller/app_color.dart';
import '../../controller/app_config_provider.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_firebase.dart';
import '../../controller/app_font.dart';
import '../../controller/app_footer.dart';
import '../../controller/app_header.dart';
import '../../controller/app_image.dart';
import '../../controller/app_language.dart';
import '../../controller/app_loader.dart';
import '../../controller/app_snack_bar_toast_message.dart';
import '../../controller/custom_input.dart';
import '../../helper/apis.dart';
import '../../model/chat_user.dart';
import 'login_screen.dart';
import 'dart:ui' as ui;

class EditProfile extends StatefulWidget {
  static String routeName = "./EditProfile";
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController firstNameTextEditingController =
      TextEditingController();
  TextEditingController lastNameTextEditingController = TextEditingController();
  TextEditingController mobileTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController dobTextEditingController = TextEditingController();
  TextEditingController cityTextEditingController = TextEditingController();
  TextEditingController countryTextEditingController = TextEditingController();
  TextEditingController addressEditingController = TextEditingController();
  TextEditingController searchTextEditingController = TextEditingController();
  TextEditingController countrySearchTextEditingController =
      TextEditingController();
  int fillColorStatus = 0;
  String getDate = '';
  var cityName;
  var cityId = 0;
  var countryName;
  var countryId = 0;
  List<dynamic> cityList = [];
  List<dynamic> countryList = [];
  List citySearchList = [];
  List countrySearchList = [];
  String profileImage = "";
  String fullName = "";
  int userId = 0;
  dynamic userDetails;
  var fileName = 'NA';
  // late File _image;
  bool isApiCalling = false;
  XFile? _imageSelect;
  int selectedGenderId = 0;
  DateTime? selectedDate;
  String date = '';
  var sendDate = "";
  String vendorId = '';
  int isPayment = 0;

  @override
  void initState() {
    super.initState();
    paymentStatusApiCall();
    getUserDetails();
    getCountries();
  }

//--------------------GET USER DETAILS-----------------------//
  Future<dynamic> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userDetails = prefs.getString("userDetails");
    setState(() {
      isApiCalling = true;
    });

    print("userDetails $userDetails");
    if (userDetails != null) {
      dynamic data = json.decode(userDetails);
      print("up $data");
      userId = data['user_id'];
      firstNameTextEditingController.text = data["f_name"] ?? "";
      lastNameTextEditingController.text = data["l_name"] ?? "";
      emailTextEditingController.text = data["email"] ?? "";
      profileImage = data["image"] ?? "NA";
      fullName = data["name"] ?? "NA";
      vendorId = data["id"] ?? "NA";
      if (data['country'] != "NA") {
        countryId = data['country']['country_id'] ?? 1;
      }
      if (data['city_name'] != "NA") {
        cityId = data['city_name']['city_id'] ?? 1;
      }

      if (data["mobile"] == null) {
        mobileTextEditingController.text = "";
      } else {
        mobileTextEditingController.text = data["mobile"].toString();
      }
      print('86$userId');
      log("data['country']['country_name'] ${data['country']?['country_name'][language] ?? ""}");
      countryTextEditingController.text =
          data['country']?['country_name'][language] ?? "";
      cityTextEditingController.text =
          data['city_name']?['city_name'][language] ?? "";
      if (data['dob'] != null) {
        date = data["dob"] ?? '';
        dobTextEditingController.text = date;
        log(date);
        DateTime dateTime = DateFormat("dd-MM-yyyy").parse(date);
        log('datetime $date');
        sendDate = DateFormat("yyyy-MM-dd").format(dateTime);
        print(date);

        print('783  $sendDate');
      } else {
        date = "";
      }
    } else {
      firstNameTextEditingController.text = "";
      lastNameTextEditingController.text = "";
      emailTextEditingController.text = "";
      mobileTextEditingController.text = "";
    }
    setState(() {
      isApiCalling = false;
    });
    getCities();
    setState(() {});
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

//--------------------------------FROM CAMERA-----------------------//
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
      });
    } else {
      setState(() {
        //  var _btnActive = false;
      });
    }

    Navigator.of(context).pop();
  }

// ------------------------------FROM GALLERY------------------------//
  Future<void> _imgFromGallery() async {
    print("run");
    dynamic image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // maxHeight: 450.0,
        // maxWidth: 450.0,
        imageQuality: 50);

    if (image != null) {
      print("image 243 $image");
      Future.delayed(const Duration(seconds: 0), () {
        setState(() {
          _imageSelect = image;
          fileName = image.path;
          //  var _btnActive = true;
        });
      });
    } else {
      setState(() {
        //    var _btnActive = false;
      });
    }

    Navigator.of(context).pop();
  }

  //-------------------------------IMAGE PICKER BOTTOM SHEET--------------------------//
  void imagePickerBottomSheet() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
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
            ),
          );
        });
  }

//-------------------------------EDIT PROFILE VALIDATION---------------------------------//
  void editProfileValidation(String firstName, String lastName, String country,
      String city, String dob, String mobile, String email) {
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
    } else {
      // If validation passes, call the API
      editProfileUsertApiCall();
    }
  }

//------------------------EDIT PROFILE API CALL--------------------------------//
  editProfileUsertApiCall() async {
    setState(() {
      isApiCalling = true;
    });
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}edit_user_profile");

    print("Url===> $url");

    try {
      http.MultipartRequest formData = http.MultipartRequest('POST', url);
      formData.fields['user_id'] = userId.toString();
      formData.fields['f_name'] = firstNameTextEditingController.text;
      formData.fields['l_name'] = lastNameTextEditingController.text;
      formData.fields['email'] = emailTextEditingController.text;
      formData.fields['mobile'] = mobileTextEditingController.text;
      formData.fields['country_id'] =
          isPayment == 0 ? "89" : countryId.toString();
      formData.fields['city_id'] = isPayment == 0 ? "120" : cityId.toString();
      formData.fields['dob'] =
          isPayment == 0 ? "2024-12-24" : sendDate.toString();

      if (_imageSelect != null) {
        XFile image1 = _imageSelect!;
        List<int> imageBytes = await image1.readAsBytes();
        http.MultipartFile imageFile = http.MultipartFile.fromBytes(
            'image', imageBytes,
            filename: 'image.jpg', contentType: MediaType('image', 'jpg'));

        formData.files.add(imageFile);
      } else {
        formData.fields['image'] = "";
      }

      log("response--==> ${formData.fields}");
      // print("response--==> ${formData.files}");
      http.StreamedResponse response = await formData.send();
      print("response--==> $response");
      var responseString = await response.stream.toBytes();
      var res = jsonDecode(utf8.decode(responseString));

      if (response.statusCode == 200) {
        print("res : $res");
        if (res['success'] == true) {
          setState(() {
            isApiCalling = false;
          });
          print('Edited Details Fetched');
          dynamic userArr = res['userDataArray'];
          print("userArr $userArr");

          final prefs = await SharedPreferences.getInstance();
          prefs.setString("userDetails", jsonEncode(userArr));
          FirebaseProvider.firebaseCreateUser(true);
          APIs.userArry = res['userDataArray'];
          APIs.user_id = res['userDataArray']['user_id'].toString();
          updateUser(res['userDataArray'], res['userDataArray']['user_id']);
          if (await userExists(res['userDataArray']['user_id']) && mounted) {
            print("mounted $mounted");

            AppConstant.selectFooterIndex = 4;
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const MyFooterPage()));
          } else {
            createUser(res['userDataArray']['user_id'], res['userDataArray']);
          }
          AppConstant.selectFooterIndex = 4;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyFooterPage(),
            ),
          );
          SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
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

  static Future<void> createUser(userid, usserArry) async {
    print("user$usserArry");
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final chatUser = ChatUser(
        id: userid.toString(),
        name: usserArry['fullname'] != null
            ? usserArry['fullname'].toString()
            : "",
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

  static Future<void> updateUser(var usserArrey, userId) async {
    print("userId$userId");
    try {
      await firestore.collection('users').doc(userId.toString()).update({
        'name': usserArrey['name'] != null ? usserArrey['name'].toString() : "",
        'image':
            usserArrey['image'] != null ? usserArrey['image'].toString() : "",
      });
      print("User updated successfully!");
    } catch (e) {
      print("Error updating user: $e");
    }
  }

  //---------------------SEARCH FUNCTION COUNTRY--------------------///
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

//---------------------SEARCH FUNCTION CITY--------------------///
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

  //-----------------GET CITIES API CALL-----------------//
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

          // findCountry();

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

//-----------------GET COUNTRIES API CALL-----------------//
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

          // findCountry();

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
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColor.secondaryColor,
        body: SafeArea(
          child: Directionality(
            textDirection:
                language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            child: Container(
              height: MediaQuery.of(context).size.height * 100 / 100,
              width: MediaQuery.of(context).size.width * 100 / 100,
              color: AppColor.secondaryColor,
              child: Column(
                children: [
                  const NoInternetBanner(),
                  AppHeader(
                      text: AppLanguage.editProfileText[language],
                      onPress: () {
                        Navigator.pop(context);
                      }),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 2 / 100),
                  Container(
                    //margin: EdgeInsets.only(bottom: 100),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(width: 3, color: AppColor.themeColor),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        height: MediaQuery.of(context).size.width * 22 / 100,
                        width: MediaQuery.of(context).size.width * 22 / 100,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 22 / 100,
                            height:
                                MediaQuery.of(context).size.width * 22 / 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: fileName == 'NA'
                                ? profileImage != "NA"
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
                                      )
                                : Image.file(
                                    File(_imageSelect!.path),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 2 / 100),

                  //change pic
                  GestureDetector(
                    onTap: () {
                      imagePickerBottomSheet();
                    },
                    child: Container(
                      child: Text(
                        AppLanguage.changeProfileText[language],
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFont.fontFamily,
                          color: AppColor.themeColor,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColor.themeColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 5 / 100),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 90 / 100,
                        child: Column(
                          children: [
                            Container(
                              child: Row(
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        90 /
                                        100,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              43 /
                                              100,
                                          child: Text(
                                              AppLanguage
                                                  .firstNameInputText[language],
                                              style: const TextStyle(
                                                  color: AppColor
                                                      .hintTextinputColor,
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 14)),
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              4 /
                                              100,
                                        ),
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              43 /
                                              100,
                                          child: Text(
                                              AppLanguage
                                                  .lastNameInputText[language],
                                              style: const TextStyle(
                                                  color: AppColor
                                                      .hintTextinputColor,
                                                  fontFamily:
                                                      AppFont.fontFamily,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 14)),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      43 /
                                      100,
                                  height: MediaQuery.of(context).size.height *
                                      5.5 /
                                      100,
                                  child: TextFormField(
                                    readOnly: false,
                                    style: AppConstant.textFilledProfileHeading,
                                    textAlignVertical: TextAlignVertical.center,
                                    keyboardType: TextInputType.text,
                                    controller: firstNameTextEditingController,
                                    onTapOutside: (event) =>
                                        FocusScope.of(context).unfocus(),
                                    decoration: InputDecoration(
                                      border: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                AppColor.textinputBorderColor),
                                      ),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                AppColor.textinputBorderColor),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                AppColor.textinputBorderColor),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      hintText: AppLanguage
                                          .firstNameInputText[language],
                                      hintStyle: const TextStyle(
                                          color: AppColor.hintTextinputColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: AppFont.fontFamily),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        4 /
                                        100),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      43 /
                                      100,
                                  height: MediaQuery.of(context).size.height *
                                      5.5 /
                                      100,
                                  child: TextFormField(
                                    readOnly: false,
                                    style: AppConstant.textFilledProfileHeading,
                                    textAlignVertical: TextAlignVertical.center,
                                    keyboardType: TextInputType.text,
                                    controller: lastNameTextEditingController,
                                    onTapOutside: (event) =>
                                        FocusScope.of(context).unfocus(),
                                    decoration: InputDecoration(
                                      border: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                AppColor.textinputBorderColor),
                                      ),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                AppColor.textinputBorderColor),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                AppColor.textinputBorderColor),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      hintText: AppLanguage
                                          .lastNameInputText[language],
                                      hintStyle: const TextStyle(
                                          color: AppColor.hintTextinputColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: AppFont.fontFamily),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            //----------------------------country---------------------
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    3 /
                                    100),
                            Container(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Text(AppLanguage.countryText[language],
                                  style: const TextStyle(
                                      color: AppColor.hintTextinputColor,
                                      fontFamily: AppFont.fontFamily,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14)),
                            ),
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              height: MediaQuery.of(context).size.height *
                                  5.5 /
                                  100,
                              child: TextFormField(
                                readOnly: true,
                                style: AppConstant.textFilledProfileHeading,
                                textAlignVertical: TextAlignVertical.center,
                                keyboardType: TextInputType.text,
                                controller: countryTextEditingController,
                                onTapOutside: (event) =>
                                    FocusScope.of(context).unfocus(),
                                decoration: InputDecoration(
                                  suffixIcon: GestureDetector(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          child: Image.asset(
                                            AppImage.downArrowIcon,
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
                                  ),
                                  border: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColor.textinputBorderColor),
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColor.textinputBorderColor),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColor.textinputBorderColor),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  hintText:
                                      AppLanguage.selectCountryText[language],
                                  hintStyle: const TextStyle(
                                      color: AppColor.hintTextinputColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: AppFont.fontFamily),
                                ),
                                onTap: () {
                                  countryListBottomSheet(context, screenWidth);
                                },
                              ),
                            ),

                            //----------------------------city---------------------
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    3 /
                                    100),
                            Container(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Text(AppLanguage.cityText[language],
                                  style: const TextStyle(
                                      color: AppColor.hintTextinputColor,
                                      fontFamily: AppFont.fontFamily,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14)),
                            ),
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              height: MediaQuery.of(context).size.height *
                                  5.5 /
                                  100,
                              child: TextFormField(
                                readOnly: true,
                                style: AppConstant.textFilledProfileHeading,
                                textAlignVertical: TextAlignVertical.center,
                                keyboardType: TextInputType.text,
                                controller: cityTextEditingController,
                                onTapOutside: (event) =>
                                    FocusScope.of(context).unfocus(),
                                decoration: InputDecoration(
                                  suffixIcon: GestureDetector(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          child: Image.asset(
                                            AppImage.downArrowIcon,
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
                                  ),
                                  border: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColor.textinputBorderColor),
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColor.textinputBorderColor),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColor.textinputBorderColor),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  hintText:
                                      AppLanguage.selectcityText[language],
                                  hintStyle: const TextStyle(
                                      color: AppColor.hintTextinputColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: AppFont.fontFamily),
                                ),
                                onTap: () {
                                  cityListBottomSheet(context, screenWidth);
                                },
                              ),
                            ),

                            //--------------------dob---------------------------
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    3 /
                                    100),
                            Container(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Text(AppLanguage.dateOfBirth[language],
                                  style: const TextStyle(
                                      color: AppColor.hintTextinputColor,
                                      fontFamily: AppFont.fontFamily,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14)),
                            ),
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              height: MediaQuery.of(context).size.height *
                                  5.5 /
                                  100,
                              child: TextFormField(
                                readOnly: true,
                                style: AppConstant.textFilledProfileHeading,
                                textAlignVertical: TextAlignVertical.center,
                                keyboardType: TextInputType.datetime,
                                controller: dobTextEditingController,
                                onTapOutside: (event) =>
                                    FocusScope.of(context).unfocus(),
                                decoration: InputDecoration(
                                  suffixIcon: GestureDetector(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          child: Image.asset(
                                            AppImage.downArrowIcon,
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
                                  ),
                                  border: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColor.textinputBorderColor),
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColor.textinputBorderColor),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColor.textinputBorderColor),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  hintText: AppLanguage.dateOfBirth[language],
                                  hintStyle: const TextStyle(
                                      color: AppColor.hintTextinputColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: AppFont.fontFamily),
                                ),
                                onTap: () async {
                                  print(DateTime.now());
                                  // print(getDate);

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

                                  final DateTime? pickedDate =
                                      await showDatePicker(
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
                                            surface: AppColor.themeColor,
                                          ),
                                          buttonTheme: const ButtonThemeData(
                                            textTheme: ButtonTextTheme.primary,
                                          ),
                                          textButtonTheme: TextButtonThemeData(
                                            style: TextButton.styleFrom(foregroundColor: AppColor.themeColor),
                                          ),
                                          dialogTheme: const DialogThemeData(
                                            backgroundColor: AppColor.themeColor,
                                          ),
                                          highlightColor: AppColor.themeColor,
                                          textTheme: const TextTheme(
                                            bodyMedium: TextStyle(
                                              color: AppColor.themeColor,
                                            ),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );

                                  if (pickedDate != null) {
                                    String formattedDate =
                                        DateFormat('dd-MM-yyyy')
                                            .format(pickedDate);
                                    print(formattedDate);
                                    setState(() {
                                      getDate = formattedDate;
                                      dobTextEditingController.text = getDate;
                                      log('getDate$getDate');
                                      sendDate = DateFormat('yyyy-MM-dd')
                                          .format(pickedDate);
                                    });
                                  } else {
                                    print("No date selected");
                                  }
                                },
                              ),
                            ),

                            //--------------------mobile---------------------------
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    3 /
                                    100),
                            Container(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Text(
                                  AppLanguage.mobileNumberInputText[language],
                                  style: const TextStyle(
                                      color: AppColor.hintTextinputColor,
                                      fontFamily: AppFont.fontFamily,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14)),
                            ),

                            CustomEditTextFormField(
                                readOnly: false,
                                fillColorStatus: 0,
                                controller: mobileTextEditingController,
                                hintText:
                                    AppLanguage.mobileNumberInputText[language],
                                //  image: AppImage.upArrowIcon,
                                keyboardtype: TextInputType.number,
                                maxLength: AppConstant.mobileLength),

                            //---------------------email-------------------
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    3 /
                                    100),
                            Container(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              child: Text(AppLanguage.emailInputText[language],
                                  style: const TextStyle(
                                      color: AppColor.hintTextinputColor,
                                      fontFamily: AppFont.fontFamily,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14)),
                            ),
                            CustomEditTextFormField(
                              readOnly: true,
                              fillColorStatus: 0,
                              controller: emailTextEditingController,
                              hintText: AppLanguage.emailInputText[language],
                              //  image: AppImage.upArrowIcon,
                              keyboardtype: TextInputType.text,
                              maxLength: AppConstant.emailMaxLength,
                            ),

                            //---------------------address-------------------
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    3 /
                                    100),

                            AppButton(
                              text: AppLanguage.updateButtonText[language],
                              onPress: () {
                                editProfileValidation(
                                  firstNameTextEditingController.text,
                                  lastNameTextEditingController.text,
                                  countryTextEditingController.text,
                                  cityTextEditingController.text,
                                  dobTextEditingController.text,
                                  mobileTextEditingController.text,
                                  emailTextEditingController.text,
                                );
                              },
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    2 /
                                    100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //-------------------city list bottom sheet--------------------
  void countryListBottomSheet(BuildContext context, screenWidth) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      constraints: BoxConstraints.expand(
        width: screenWidth,
      ),
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
                    // color: Colors.white,
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
                      height: MediaQuery.of(context).size.height * 6 / 100,
                      child: TextFormField(
                        style: const TextStyle(
                          height: 0.9,
                          color: AppColor.primaryColor,
                          fontSize: 16,
                        ),
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
                            contentPadding: EdgeInsets.only(top: 4),
                            prefixIcon: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.width *
                                      7 /
                                      100,
                                  width: MediaQuery.of(context).size.width *
                                      7 /
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
                                fontSize: 16,
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

  //-------------------city list bottom sheet--------------------
  void cityListBottomSheet(BuildContext context, screenWidth) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      constraints: BoxConstraints.expand(
        width: screenWidth,
      ),
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
                    // color: Colors.white,
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
                      height: MediaQuery.of(context).size.height * 6 / 100,
                      child: TextFormField(
                        style: const TextStyle(
                          height: 0.9,
                          color: AppColor.primaryColor,
                          fontSize: 16,
                        ),
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
                            contentPadding: EdgeInsets.only(top: 4),
                            prefixIcon: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.width *
                                      7 /
                                      100,
                                  width: MediaQuery.of(context).size.width *
                                      7 /
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
                                fontSize: 16,
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
      cityTextEditingController.text = cityName;
    });
  }

  selectCountry(index, name, id) {
    setState(() {
      countryId = id;
      countryName = name;
      cityTextEditingController.clear();
      cityId = 0;
      getCities();
      countryTextEditingController.text = countryName;
    });
  }
}
