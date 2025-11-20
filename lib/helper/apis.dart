import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../model/chat_user.dart';
import '../model/message.dart';

class APIs {
  // for authentication

  // for accessing cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // for accessing firebase storage
  static FirebaseStorage storage = FirebaseStorage.instance;
  static var userArry;

  // for storing self information
  static ChatUser me = ChatUser(
      id: user_id.toString(),
      name: userArry['name'] != null ? userArry['name'].toString() : "",
      email: userArry['email'] != null ? userArry['email'].toString() : "",
      about: "Hey, I'm using We Chat!",
      image: userArry['image'] != null ? userArry['imege'].toString() : "",
      createdAt: '',
      isOnline: false,
      lastActive: '',
      pushToken: '',
      mobile: "",
      playerId: '',
      groups: []);

  // to return current user

  // for accessing firebase messaging (Push Notification)
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  // for getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();

    await fMessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log('Push Token: $t');
      }
    });
  }

  // for sending push notification (Updated Codes)

  static Future<void> sendPushNotification(
      ChatUser chatUser, String msg, bool isActive) async {
    if (isActive == false) {
      print("Sending notification to: ${chatUser.name}");

      final url = Uri.parse("https://onesignal.com/api/v1/notifications");

      var headers = {
        'Content-Type': 'application/json',
        'Authorization':
            "os_v2_app_geb6suva35eedj42n4rbzc7hnlnri7jy4y6uafvocvbgr2o5ue5klxjij5hn6zr7m2eqi2qcq5v2cw5uxyrgizjzowy2ws5fa5g4mba",
      };

      var body = {
        'app_id': "3103e952-a0df-4841-a79a-6f221c8be76a",

        'include_player_ids': [
          // AppConstant.playerID
          chatUser.playerId
        ], // Send notification to this player ID
        'contents': {
          'en':
              '${userArry['name'] != null ? userArry['name'] : "Unknown"} sent a ${msg}.'
        },
        'data': {
          "action_json": {
            'action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1025525',
            'status': 'done',
            'sound': 'default',
            'userId': user_id,
            'otherUserId': chatUser.id,
            'otherUserName': chatUser.name,
            'message': msg,
          }
        },
      };

      try {
        http.Response response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          print("Notification sent successfully: ${response.body}");
        } else {
          print("Failed to send notification: ${response.statusCode}");
          print("Response body: ${response.body}");
        }
      } catch (e) {
        print("Error sending notification: $e");
      }
    }
  }

  // for adding an chat user for our conversation
  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    log('data: ${data.docs}');

    if (data.docs.isNotEmpty && data.docs.first.id != user_id) {
      //user exists

      log('user exists: ${data.docs.first.data()}');

      firestore
          .collection('users')
          .doc(user_id)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});

      return true;
    } else {
      //user doesn't exists

      return false;
    }
  }

  // for getting current user info
  static Future<void> getSelfInfo() async {
    print("user_id111$user_id");
    await firestore.collection('users').doc(user_id).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();

        //for setting user status to active
        APIs.updateActiveStatus(true);
        log('My Data: ${user.data()}');
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  static String user_id = "12345678";

  // for creating a new user
  static Future<void> createUser() async {
    print("user");
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    print('UserArray 264 $userArry');
    final chatUser = ChatUser(
        id: user_id.toString(),
        name: userArry['name'] != null ? userArry['name'].toString() : "",
        email: userArry['email'] != null ? userArry['email'].toString() : "",
        about: "Hey, I'm using We Chat!",
        image: userArry['image'] != null ? userArry['imege'].toString() : "",
        createdAt: time,
        isOnline: false,
        lastActive: time,
        pushToken: '',
        mobile: "",
        playerId: '',
        groups: []);

    return await firestore
        .collection('users')
        .doc(user_id)
        .set(chatUser.toJson());
  }

  // for getting id's of known users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return firestore
        .collection('users')
        .doc(user_id)
        .collection('my_users')
        .snapshots();
  }

  // for getting all users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String> userIds) {
    log('\nUserIds1111: $userIds');

    return firestore
        .collection('users')
        .where('id',
            whereIn: userIds.isEmpty
                ? ['']
                : userIds) //because empty list throws an error
        // .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  // for adding an user to my user when first message is send
  static Future<void> sendFirstMessage(
      ChatUser chatUser, String msg, Type type, bool isActive) async {
    await firestore
        .collection('users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user_id)
        .set({}).then((value) => sendMessage(chatUser, msg, type, isActive));
  }

  // for updating user information
  static Future<void> updateUserInfo() async {
    await firestore.collection('users').doc(user_id).update({
      'name': me.name,
      'about': me.about,
    });
  }

  // update profile picture of user
  static Future<void> updateProfilePicture(File file) async {
    //getting image file extension
    final ext = file.path.split('.').last;
    log('Extension: $ext');

    //storage file ref with path
    final ref = storage.ref().child('profile_pictures/${user_id}.$ext');

    //uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    //updating image in firestore database
    me.image = await ref.getDownloadURL();
    await firestore
        .collection('users')
        .doc(user_id)
        .update({'image': me.image});
  }

  // for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChatUser chatUser) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  // update online or last active status of user
  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user_id).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  ///************** Chat Screen Related APIs **************

  // useful for getting conversation id
  static String getConversationID(String id) =>
      user_id.hashCode <= id.hashCode ? '${user_id}_$id' : '${id}_${user_id}';

  // for getting all messages of a specific conversation from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  // for sending message
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type, bool isActive) async {
    //message sending time (also used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    //message to send
    final Message message = Message(
        toId: chatUser.id,
        msg: msg,
        read: '',
        type: type,
        fromId: user_id,
        sent: time);

    final ref = firestore
        .collection('chats/${getConversationID(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson()).then((value) =>
        sendPushNotification(
            chatUser, type == Type.text ? msg : 'image', isActive));
  }

  //update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection('chats/${getConversationID(message.fromId)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //get only last message of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser user) {
    print("user$user");
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  //send chat image
  static Future<void> sendChatImage(
      ChatUser chatUser, File file, bool isActive) async {
    //getting image file extension
    final ext = file.path.split('.').last;

    //storage file ref with path
    final ref = storage.ref().child(
        'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    //uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    //updating image in firestore database
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image, isActive);
  }

  //delete message
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .delete();

    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  //update message
  static Future<void> updateMessage(Message message, String updatedMsg) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .update({'msg': updatedMsg});
  }
}
