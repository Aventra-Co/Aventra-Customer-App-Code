import 'dart:convert';
import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_constant.dart';

class FirebaseProvider {
  String name = '';
  static firebaseCreateUser(bool isOnline, [String value = 'yes']) async {
    String? token = AppConstant.token;
    // print("token $token");
    final prefs = await SharedPreferences.getInstance();
    dynamic userDetails = prefs.getString('userDetails');
    print("userDetails firebase details : $userDetails");

    if (userDetails != null) {
      dynamic userDetail = await jsonDecode(userDetails);
      log("lkjhgfdsa$userDetail");

      Map<String, dynamic> user = {
        'chat_room_id': 'no',
        'name': userDetail['name'],
        'user_name': userDetail['name'],
        'email': userDetail['email'],
        // 'image':"NA",
        'notification_stauts': 1,
        'online_status': isOnline ? 'true' : 'false',
        'player_id': AppConstant.playerID,
        'user_id': userDetail['user_id'],
        'user_type': 1,
        'login_type': 'app',
        'chat_screen_status': value,
        'device_token': token,
        'user_image': userDetail['image'] ?? '',
      };

      Future.delayed(const Duration(seconds: 2), () {
        FirebaseDatabase.instance
            .ref('users/' "u_${userDetail['user_id']}")
            .update(user)
            .then((value) {
          var onlineStatusRef = FirebaseDatabase.instance
              .ref('users/' "u_${userDetail['user_id']}" '/onlineStatus/');
          onlineStatusRef.onDisconnect().set('false');
        }).catchError((error) {
          debugPrint("error $error");
        });
      });
    }
  }

  static sendMessage(
    String userId,
    String otherUserId,
    String otherUserName,
    String message,
    String deviceToken,
    // String otherUserNameIdentify,
    // String acceptAt,
    // String otherUserImage
  ) async {
    // print("userId $userId");
    // print("otherUserId $otherUserId");

    String userIdSend = 'u_$userId';

    String otherUserIdSend = 'u_$otherUserId';

    String inboxIdMe = 'u_$otherUserId';

    String inboxIdOther = 'u_$userId';

    DateTime now = DateTime.now();

    Timestamp currentTimestamp = Timestamp.fromDate(now);

    print(currentTimestamp.toString());

    // print("myInbox :  ${"users/$userIdSend/myInbox/$otherUserIdSend"}");

    int messageCount = 0;

    FirebaseDatabase.instance
        .ref("users/$userIdSend/myInbox/$otherUserIdSend")
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        Map data = snapshot.value as Map;

        if (data['count'] == 0) {
          messageCount = messageCount + 1;
        } else {
          messageCount = (data['count'] + 1);
        }
      }

      FirebaseDatabase.instance
          .ref('users/$otherUserIdSend')
          .get()
          .then((snapshot) {
        if (snapshot.exists) {
          Map data = snapshot.value as Map;

          if (data['chat_screen_status'] == "no") {
            messageCount = 0;
          }
        }
      });

      Future.delayed(const Duration(milliseconds: 1000), () {
        Map<String, dynamic> jsonUserDataMe = ({
          'count': messageCount,
          'lastMessageType': 'text',
          'lastMsg': message,
          'user_id': otherUserId,
          'typing_status': 'no',
          "name": 'Admin',
          'block_status': 'no',
          'match_status': 'yes',
          'msg_time': DateFormat("yyyy-MM-dd HH:mm:ss")
              .format(DateTime.now())
              .toString(),
          'lastMsgTime': DateFormat("yyyy-MM-dd HH:mm:ss")
              .format(DateTime.now())
              .toString(),
          'last_seen': 'no',
        });

        Map<String, dynamic> jsonUserDataother = ({
          'count': messageCount,
          'lastMessageType': 'text',
          'lastMsg': message,
          'user_id': userId,
          "name": 'Other User',
          'typing_status': 'no',
          'block_status': 'no',
          'match_status': 'yes',
          'msg_time': DateFormat("yyyy-MM-dd HH:mm:ss")
              .format(DateTime.now())
              .toString(),
          'lastMsgTime': DateFormat("yyyy-MM-dd HH:mm:ss")
              .format(DateTime.now())
              .toString(),
          'last_seen': 'no'
        });

        print("jsonUserDataother $jsonUserDataother");

        updateUserInboxMe(userIdSend, inboxIdMe, jsonUserDataMe);
        updateUserInboxOther(otherUserIdSend, inboxIdOther, jsonUserDataother);

        //---------------------- this code for send message to both -----------
        String messageIdME = 'u_' + userId + '__u_' + otherUserId;
        String messageIdOther = 'u_' + otherUserId + '__u_' + userId;

        var senderId = userId;
        var inputId = 'xyz';

        Map<String, dynamic> messageJson = ({
          'message': message,
          'messageType': 'text',
          'senderId': senderId,
          'msg_time': DateFormat("yyyy-MM-dd HH:mm:ss")
              .format(DateTime.now())
              .toString(),
          'timestamp': DateFormat("yyyy-MM-dd HH:mm:ss")
              .format(DateTime.now())
              .toString(),
          'last_seen': 'no',
          'user_type': 1,
          "name": "Other User"
        });

        sendUserMessage(messageIdME, messageJson, 'text', inputId);
        sendUserMessage(messageIdOther, messageJson, 'text', inputId);
        print("Line no. 172");

        FirebaseDatabase.instance
            .ref('users/$otherUserIdSend')
            .get()
            .then((snapshot) {
          if (snapshot.exists) {
            Map data = snapshot.value as Map;
            if (data['chat_screen_status'] == "yes") {
              // sendNotification(
              //   message,
              //   otherUserName,
              //   deviceToken,
              //   userId,
              //   otherUserId,

              // );
            }
          } else {
            print('No data available');
          }
        });
        FirebaseDatabase.instance.ref('users/').get().then((snapshot) {
          //  if (chatScreenStatus == "yes") {
          // sendNotification(
          //   message,
          //   otherUserName,
          //   deviceToken,
          //   userId,
          //   otherUserId,

          // );
          // }
          return false;
          if (snapshot.exists) {
            Map value = snapshot.value as Map;
            List item = [];
            value.forEach((index, data) => item.add(data));
            String chatScreenStatus = "NA";

            for (var i = 0; i < item.length; i++) {
              if (item[i]['user_id'].toString() == otherUserId.toString()) {
                chatScreenStatus = item[i]['chat_screen_status'];
              }
            }
            print("chatScreenStatus $chatScreenStatus");
            print("Line no. 211");
            if (chatScreenStatus == "yes") {
              sendNotification(
                message,
                otherUserName,
                deviceToken,
                userId,
                otherUserId,

                // otherUserNameIdentify,
                // acceptAt,
                // otherUserImage,
              );
            }
          }
        });
      });
    });
  }

  static sendNotification(
    message,
    otherUserName,
    deviceToken,
    userId,
    otherUserId,
  ) async {
    final url = Uri.parse("https://onesignal.com/api/v1/notifications");

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': "ZTg2ZTQxYmYtZjZjYi00YmViLWI5ZDktMThkNTY0ODRmZDE",
    };
    print("otherUserName$otherUserName");
    print("otherUserName256$userId");
    var body = {
      'app_id': '60e0937d-d285-4bdd-b86e-23b960793f2e',
      // 'include_player_ids': [AppConstant.playerID],
      'contents': {'en': '$otherUserName sent you a new message.'},
      'data': {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'id': '1025525',
        'status': 'done',
        'sound': 'default',
        'userId': userId,
        "otherUserId": int.parse("1"),
        'otherUserName': otherUserName,
        'message': message,
      },
    };

    // Convert the body map to JSON string
    String jsonBody = jsonEncode(body);

    http.Response response = await http.post(
      url,
      headers: headers,
      body: jsonBody,
    );

    if (response.statusCode == 200) {
      // Parse the JSON response
      var res = jsonDecode(response.body);
      print("res $res");
      print("Notification sent successfully");
    } else {
      print("Failed to send notification: ${response.statusCode}");
      print("Response body: ${response.body}");
    }
  }

  static updateUserInboxMe(id, otherId, jsonUserData) {
    // ignore: prefer_interpolation_to_compose_strings
    FirebaseDatabase.instance
        .ref("users/$id/myInbox/$otherId")
        .update(jsonUserData)
        .then((value) {
      // print("Update Inbox succeeded.");
    }).catchError((error) {
      print("Update Inbox failed: $error");
    });
  }

  static updateUserInboxOther(id, otherId, jsonUserData2) {
    print("Inde users/$id/myInbox/$otherId");
    FirebaseDatabase.instance
        .ref("users/$id/myInbox/$otherId")
        .update(jsonUserData2)
        .then((value) {
      // print("Update Inbox succeeded.");
    }).catchError((error) {
      print("Update Inbox failed: $error");
    });
  }

  static sendUserMessage(String messageId, messageJson, messageType, inputId) {
    FirebaseDatabase.instance
        .ref("message/$messageId")
        .push()
        .set(messageJson)
        .then((value) {
      // print("Send User Message Succeeded");
    }).catchError((error) {
      print("Update Inbox failed: $error");
    });
  }

  static setOtherUserMessageCountZero(String userId, String otherUserId) {
    String userIdSend = 'u_$otherUserId';

    String inboxIdMe = 'u_$userId';

    Map<String, dynamic> jsonUserDataother = ({
      'count': 0,
    });

    // print("jsonUserDataother $jsonUserDataother");

    updateUserInboxOther(userIdSend, inboxIdMe, jsonUserDataother);
  }
}
