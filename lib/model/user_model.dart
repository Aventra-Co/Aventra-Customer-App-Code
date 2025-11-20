import 'city_model.dart';
import 'country_model.dart';

class UserModel {
  final int userId;
  final int loginType;
  final int loginTypeFirst;
  final int userType;
  final String email;
  final String name;
  final String fName;
  final String lName;
  final String dob;
  final int age;
  final CountryModel country;
  final int city;
  final CityModel cityName;
  final int mobile;
  final String otp;
  final int otpVerify;
  final String image;
  final int gender;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? zipcode;
  final int activeFlag;
  final int approveFlag;
  final int profileComplete;
  final String? instagramId;
  final String? deleteReason;
  final String createTime;
  final String updateTime;
  final String? bio;
  final int viewHome;
  final int manageHome;
  final int viewMyAdd;
  final int manageMyAdd;
  final int chat;
  final int viewUnavailability;
  final int manageUnavailability;
  final int viewMyWallet;
  final int viewHistory;

  UserModel({
    required this.userId,
    required this.loginType,
    required this.loginTypeFirst,
    required this.userType,
    required this.email,
    required this.name,
    required this.fName,
    required this.lName,
    required this.dob,
    required this.age,
    required this.country,
    required this.city,
    required this.cityName,
    required this.mobile,
    required this.otp,
    required this.otpVerify,
    required this.image,
    required this.gender,
    required this.address,
    this.latitude,
    this.longitude,
    this.zipcode,
    required this.activeFlag,
    required this.approveFlag,
    required this.profileComplete,
    this.instagramId,
    this.deleteReason,
    required this.createTime,
    required this.updateTime,
    this.bio,
    required this.viewHome,
    required this.manageHome,
    required this.viewMyAdd,
    required this.manageMyAdd,
    required this.chat,
    required this.viewUnavailability,
    required this.manageUnavailability,
    required this.viewMyWallet,
    required this.viewHistory,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'],
      loginType: json['login_type'],
      loginTypeFirst: json['login_type_first'],
      userType: json['user_type'],
      email: json['email'],
      name: json['name'],
      fName: json['f_name'],
      lName: json['l_name'],
      dob: json['dob'],
      age: json['age'],
      country: CountryModel.fromJson(json['country']),
      city: json['city'],
      cityName: CityModel.fromJson(json['city_name']),
      mobile: json['mobile'],
      otp: json['otp'],
      otpVerify: json['otp_verify'],
      image: json['image'],
      gender: json['gender'],
      address: json['address'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      zipcode: json['zipcode'],
      activeFlag: json['active_flag'],
      approveFlag: json['approve_flag'],
      profileComplete: json['profile_complete'],
      instagramId: json['instagram_id'],
      deleteReason: json['delete_reason'],
      createTime: json['createtime'],
      updateTime: json['updatetime'],
      bio: json['bio'],
      viewHome: json['view_home'],
      manageHome: json['manage_home'],
      viewMyAdd: json['view_my_add'],
      manageMyAdd: json['manage_my_add'],
      chat: json['chat'],
      viewUnavailability: json['view_unavailability'],
      manageUnavailability: json['manage_unavailability'],
      viewMyWallet: json['view_my_wallet'],
      viewHistory: json['view_history'],
    );
  }
}
