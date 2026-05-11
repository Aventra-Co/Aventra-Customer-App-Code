import 'dart:convert';
import '/view/authentication/notification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../chat/chat_screen.dart';
import '../main.dart';
import '../model/chat_user.dart';
import 'app_constant.dart';

class OneSignalService {
  // Static variable to store pending notification data
  static Map<String, dynamic>? _pendingNotificationData;
  static bool _hasPendingBroadcast = false;
  static bool _isAppInitialized = false;

  static Future<void> initOneSignal() async {
    print("Initializing OneSignal");

    OneSignal.initialize(AppConstant.oneSignalAppId);

    await OneSignal.Notifications.requestPermission(true);

    // Get player ID
    final String? tokenId = OneSignal.User.pushSubscription.id;
    if (tokenId != null) {
      AppConstant.playerID = tokenId;
      print("playerID : ${AppConstant.playerID}");
    }
    assert(() {
      debugPrint('OneSignal pushSubscription.id (immediate): ${OneSignal.User.pushSubscription.id}');
      return true;
    }());

    // Listen for ID changes (in case it loads after init)
    OneSignal.User.pushSubscription.addObserver((state) {
      final String? id = state.current.id;
      if (id != null) {
        AppConstant.playerID = id;
        print("playerID updated: ${AppConstant.playerID}");
      }
    });

    assert(() {
      Future.delayed(const Duration(seconds: 2), () {
        debugPrint('OneSignal pushSubscription.id (after 2s): ${OneSignal.User.pushSubscription.id}');
      });
      return true;
    }());

    // Notification opened handler
    OneSignal.Notifications.addClickListener((OSNotificationClickEvent event) async {
      print("Result: ${event.toString()}");
      print('additionalData ---? ${event.notification.additionalData}');

      Map<String, dynamic>? additionalData = event.notification.additionalData;
      print("line 47 $additionalData");

      if (additionalData != null) {
        _pendingNotificationData = additionalData;

        if (_isAppInitialized) {
          _handleNotificationNavigation(additionalData);
        }
        else {
          _storePendingNotification(additionalData);
        }
      }
    });
  }

  // Store pending notification and set flags
  static void _storePendingNotification(Map<String, dynamic> additionalData) {
    try {
      var decodeData = json.decode(json.encode(additionalData))['action_json']['action'];

      if (decodeData.toString().toLowerCase() == "broadcast") {
        print("Storing pending broadcast notification");
        _hasPendingBroadcast = true;
      }
    } catch (e) {
      print("Error storing pending notification: $e");
    }
  }

  // Method to handle notification navigation
  static void _handleNotificationNavigation(Map<String, dynamic> additionalData) {
    print("Not reaching");
    try {
      var decodeData = json.decode(json.encode(additionalData))['action_json']['action'];

      print("Worked92");

      if (decodeData.toString().toLowerCase() == "broadcast" ||
          decodeData.toString().toLowerCase() == "trip_booking" ||
          decodeData.toString().toLowerCase() == "trip_cancellation" ||
          decodeData.toString().toLowerCase() == "property_cancellation" ||
          decodeData.toString().toLowerCase() == "property_booking") {
        print("Broadcast action received");

        // Check if navigator is ready and app is initialized
        if (navigatorKey.currentState != null &&
            navigatorKey.currentContext != null &&
            _isAppInitialized) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => const NotificationScreen(),
            ),
          );
          // Clear pending data after successful navigation
          clearPendingNotifications();
        } else {
          print(
              "Navigator not ready or app not initialized, storing for later");
          _hasPendingBroadcast = true;
        }
      }

      if (decodeData.toString() == "FLUTTER_NOTIFICATION_CLICK") {
        print("Follow action received");

        var otheruserId =
            json.decode(json.encode(additionalData))['action_json']['userId'];
        print("otheruserId:123 $otheruserId");

        bool isNavigated = false;
        FirebaseFirestore.instance
            .collection("users")
            .where("id", isEqualTo: otheruserId)
            .get()
            .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            var data = snapshot.docs.first.data();
            ChatUser user = ChatUser.fromJson(data);

            if (!isNavigated &&
                navigatorKey.currentState != null &&
                _isAppInitialized) {
              isNavigated = true;
              // Add your navigation code here
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(user: user),
                ),
              );
              clearPendingNotifications();
            }
          } else {
            print("User not found in Firestore.");
          }
        }).catchError((error) {
          print("Error fetching user: $error");
        });
      }
    } catch (e) {
      print("Error handling notification: $e");
    }
  }

  // Method to check if there's a pending broadcast notification
  static bool hasPendingBroadcastNotification() {
    return _hasPendingBroadcast;
  }

  // Method to handle pending notifications after app initialization
  static void handlePendingNotifications() {
    _isAppInitialized = true;
    if (_pendingNotificationData != null) {
      print("Processing pending notification after app initialization");
      _handleNotificationNavigation(_pendingNotificationData!);
    }
  }

  // Method to clear pending notifications
  static void clearPendingNotifications() {
    _pendingNotificationData = null;
    _hasPendingBroadcast = false;
  }

  // Method to manually navigate to notifications (called from splash after login)
  static void navigateToNotifications(BuildContext context) {
    if (_hasPendingBroadcast) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      );
      clearPendingNotifications();
    }
  }

  // Method to set app as initialized
  static void setAppInitialized(bool initialized) {
    _isAppInitialized = initialized;
  }
}
