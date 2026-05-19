import 'dart:async';
import 'dart:convert';
import '/view/authentication/notification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../chat/chat_screen.dart';
import '../main.dart';
import '../model/chat_user.dart';
import 'app_config_provider.dart';
import 'app_constant.dart';

class OneSignalService {
  // Static variable to store pending notification data
  static Map<String, dynamic>? _pendingNotificationData;
  static bool _hasPendingBroadcast = false;
  static bool _isAppInitialized = false;
  static bool _willDisplayListenerRegistered = false;
  static bool _clickListenerRegistered = false;
  static final List<String> _recentWillDisplayNotificationIds = <String>[];
  static final Set<String> _recentWillDisplayNotificationIdSet = <String>{};
  static Timer? _refreshNotificationCountTimer;
  static bool _refreshNotificationCountInFlight = false;
  static Completer<String>? _playerIdCompleter;
  static const String _prefsPlayerIdKey = "onesignal_player_id";
  static const String _prefsNotificationCountKey = "notification_badge_count";
  static const MethodChannel _badgeChannel =
      MethodChannel("com.aventra.app/badge");

  static final ValueNotifier<int> notificationBadgeCount =
      ValueNotifier<int>(0);

  static Future<void> _cacheNotificationCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsNotificationCountKey, count);
    } catch (_) {}
  }

  static Future<void> setAppIconBadgeCount(int count) async {
    final int v = count < 0 ? 0 : count;
    try {
      await _badgeChannel.invokeMethod("setBadge", {"count": v});
    } catch (_) {}
  }

  static Future<void> setNotificationBadgeCount(int count,
      {bool updateAppIcon = true}) async {
    final int v = count < 0 ? 0 : count;
    if (notificationBadgeCount.value != v) {
      notificationBadgeCount.value = v;
    }
    await _cacheNotificationCount(v);
    if (updateAppIcon) {
      await setAppIconBadgeCount(v);
    }
  }

  static Future<void> _loadNotificationBadgeFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int cached = prefs.getInt(_prefsNotificationCountKey) ?? 0;
      await setNotificationBadgeCount(cached);
    } catch (_) {}
  }

  static Future<void> _refreshNotificationCountFromApi() async {
    if (_refreshNotificationCountInFlight) return;
    _refreshNotificationCountInFlight = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rawUser = prefs.getString("userDetails");
      if (rawUser == null || rawUser.trim().isEmpty) return;

      final dynamic decoded = jsonDecode(rawUser);
      final dynamic userIdRaw =
          (decoded is Map) ? decoded["user_id"] : null;
      final int userId = userIdRaw is int
          ? userIdRaw
          : int.tryParse(userIdRaw?.toString() ?? "") ?? 0;
      if (userId == 0) return;

      String token = AppConstant.token.toString().trim();
      if (token.isEmpty) {
        token = (prefs.getString("token") ?? "").toString().trim();
      }
      if (token.isEmpty) return;

      final Uri url = Uri.parse(
          "${AppConfigProvider.apiUrl}home_page_api?user_id=$userId&tab_type=sea");
      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode != 200) return;
      final dynamic body = jsonDecode(res.body);
      if (body is! Map || body["success"] != true) return;

      final dynamic rawCount = body["notificationCount"];
      final int count = rawCount is int
          ? rawCount
          : int.tryParse(rawCount?.toString() ?? "") ?? 0;
      await setNotificationBadgeCount(count);
    } catch (_) {
    } finally {
      _refreshNotificationCountInFlight = false;
    }
  }

  static void _scheduleNotificationCountRefresh() {
    _refreshNotificationCountTimer?.cancel();
    _refreshNotificationCountTimer =
        Timer(const Duration(milliseconds: 350), () {
      _refreshNotificationCountFromApi();
    });
  }

  static Future<void> _cachePlayerId(String id) async {
    final String v = id.toString().trim();
    if (v.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsPlayerIdKey, v);
    } catch (_) {}
  }

  static Future<void> initOneSignal() async {
    print("Initializing OneSignal");

    OneSignal.initialize(AppConstant.oneSignalAppId);

    try {
      await OneSignal.Notifications.requestPermission(true)
          .timeout(const Duration(seconds: 6), onTimeout: () => false);
    } catch (_) {}

    await _loadNotificationBadgeFromCache();
    _scheduleNotificationCountRefresh();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefsPlayerIdKey) ?? "";
      if (cached.toString().trim().isNotEmpty) {
        AppConstant.playerID = cached.toString().trim();
      }
    } catch (_) {}

    // Get player ID
    final String? tokenId = OneSignal.User.pushSubscription.id;
    if (tokenId != null) {
      AppConstant.playerID = tokenId;
      await _cachePlayerId(tokenId);
      _playerIdCompleter?.complete(tokenId);
      _playerIdCompleter = null;
      print("playerID : ${AppConstant.playerID}");
    }

    try {
      final String? oneSignalId = await OneSignal.User.getOnesignalId();
      if (oneSignalId != null && oneSignalId.toString().trim().isNotEmpty) {
        if (AppConstant.playerID.toString().trim().isEmpty) {
          AppConstant.playerID = oneSignalId.toString().trim();
        }
        await _cachePlayerId(AppConstant.playerID);
      }
    } catch (_) {}
    assert(() {
      debugPrint('OneSignal pushSubscription.id (immediate): ${OneSignal.User.pushSubscription.id}');
      return true;
    }());

    // Listen for ID changes (in case it loads after init)
    OneSignal.User.pushSubscription.addObserver((state) {
      final String? id = state.current.id;
      if (id != null) {
        AppConstant.playerID = id;
        _cachePlayerId(id);
        _playerIdCompleter?.complete(id);
        _playerIdCompleter = null;
        print("playerID updated: ${AppConstant.playerID}");
      }
    });

    if (!_willDisplayListenerRegistered) {
      _willDisplayListenerRegistered = true;
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        final String id = event.notification.notificationId;
        if (id.trim().isNotEmpty) {
          if (_recentWillDisplayNotificationIdSet.contains(id)) return;
          _recentWillDisplayNotificationIdSet.add(id);
          _recentWillDisplayNotificationIds.add(id);
          if (_recentWillDisplayNotificationIds.length > 50) {
            final String removed =
                _recentWillDisplayNotificationIds.removeAt(0);
            _recentWillDisplayNotificationIdSet.remove(removed);
          }
        }
        _scheduleNotificationCountRefresh();
      });
    }

    assert(() {
      Future.delayed(const Duration(seconds: 2), () {
        debugPrint('OneSignal pushSubscription.id (after 2s): ${OneSignal.User.pushSubscription.id}');
      });
      return true;
    }());

    // Notification opened handler
    if (!_clickListenerRegistered) {
      _clickListenerRegistered = true;
      OneSignal.Notifications.addClickListener(
          (OSNotificationClickEvent event) async {
        print("Result: ${event.toString()}");
        print('additionalData ---? ${event.notification.additionalData}');

        Map<String, dynamic>? additionalData =
            event.notification.additionalData;
        print("line 47 $additionalData");

        if (additionalData != null) {
          _pendingNotificationData = additionalData;

          if (_isAppInitialized) {
            _handleNotificationNavigation(additionalData);
          } else {
            _storePendingNotification(additionalData);
          }
        }
      });
    }
  }

  static Future<String> getPlayerId({Duration timeout = const Duration(seconds: 4)}) async {
    final current = OneSignal.User.pushSubscription.id;
    if (current != null && current.toString().trim().isNotEmpty) {
      AppConstant.playerID = current;
      await _cachePlayerId(current);
      return current;
    }

    try {
      final String? oneSignalId = await OneSignal.User.getOnesignalId();
      if (oneSignalId != null && oneSignalId.toString().trim().isNotEmpty) {
        AppConstant.playerID = oneSignalId.toString().trim();
        await _cachePlayerId(AppConstant.playerID);
        return AppConstant.playerID;
      }
    } catch (_) {}

    final cached = AppConstant.playerID.toString().trim();
    if (cached.isNotEmpty) return cached;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPrefs = prefs.getString(_prefsPlayerIdKey) ?? "";
      if (cachedPrefs.toString().trim().isNotEmpty) {
        AppConstant.playerID = cachedPrefs.toString().trim();
        return AppConstant.playerID;
      }
    } catch (_) {}

    _playerIdCompleter ??= Completer<String>();

    try {
      final id = await _playerIdCompleter!.future.timeout(timeout);
      await _cachePlayerId(id);
      return id;
    } catch (_) {
      final fallback = AppConstant.playerID.toString().trim();
      if (fallback.isNotEmpty) return fallback;
      try {
        final String? lastResort = await OneSignal.User.getOnesignalId();
        final v = lastResort?.toString().trim() ?? "";
        if (v.isNotEmpty) return v;
      } catch (_) {}
      return "no_player_id";
    }
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
