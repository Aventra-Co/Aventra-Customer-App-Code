import '../view/authentication/ResetPassword_screen.dart';
import '/view/other_screen/faq_screen.dart';
import '/view/other_screen/help_support_screen.dart';
import 'package:flutter/material.dart';
import '../view/authentication/change_password_screen.dart';
import '../view/authentication/deleteAccount_screen.dart';
import '../view/authentication/forgetPassword_otpverify_screen.dart';
import '../view/authentication/forgot_password_screen.dart';
import '../view/authentication/login_screen.dart';
import '../view/authentication/notification_screen.dart';
import '../view/authentication/otp_verify_screen.dart';
import '../view/authentication/signup_screen.dart';
import '../view/content_screen/content_screen.dart';
import '../view/other_screen/booking_history_screen.dart';
import '../view/other_screen/chat_screen.dart';
import '../view/other_screen/splash_screen.dart';

final Map<String, WidgetBuilder> routes = {
  Splash.routeName: (context) => Splash(),
  Signup.routeName: (context) => const Signup(),
  Login.routeName: (context) => const Login(),
  SignUpOtpVerifyHeader.routeName: (context) => const SignUpOtpVerifyHeader(),
  ForgetPasswordOtpVerifyHeader.routeName: (context) =>
      const ForgetPasswordOtpVerifyHeader(),

  Content.routeName: (context) => const Content(),
  NotificationScreen.routeName: (context) => const NotificationScreen(),
  DeleteAccount.routeName: (context) => const DeleteAccount(),
  ChangePassword.routeName: (context) => const ChangePassword(),
  ForgotPassword.routeName: (context) => const ForgotPassword(),

  //-----------------------Anurag-----------
  HelpSupport.routeName: (context) => const HelpSupport(),
  FAQ.routeName: (context) => const FAQ(),
  BookingHistory.routeName: (context) => const BookingHistory(),
  Chat.routeName: (context) => const Chat(),
  ResetPasswordHeader.routeName: (context) => const ResetPasswordHeader(),
};
