import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/app_config_provider.dart';
import '../controller/app_constant.dart';
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
      id: '',
      name: '',
      email: '',
      about: "Hey, I'm using We Chat!",
      image: '',
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
    try {
      final settings = await fMessaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      if (Platform.isIOS) {
        for (int i = 0; i < 6; i++) {
          final apnsToken = await fMessaging.getAPNSToken();
          if (apnsToken != null) break;
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }

      final String? t = await fMessaging.getToken();
      if (t != null) {
        me.pushToken = t;
        log('Push Token: $t');
      }
    } on PlatformException catch (e) {
      if (e.code == 'apns-token-not-set') return;
      log('Firebase Messaging token error: ${e.code}');
    } catch (e) {
      log('Firebase Messaging token error: $e');
    }
  }

  // for sending push notification (Updated Codes)

  static Future<void> sendPushNotification(
      ChatUser chatUser, String msg, bool isActive,
      {String? imageUrl}) async {
    if (isActive == false) {
      final url = Uri.parse("https://onesignal.com/api/v1/notifications");

      var headers = {
        'Content-Type': 'application/json',
        'Authorization':
            "os_v2_app_geb6suva35eedj42n4rbzc7hnlnri7jy4y6uafvocvbgr2o5ue5klxjij5hn6zr7m2eqi2qcq5v2cw5uxyrgizjzowy2ws5fa5g4mba",
      };

      final String? largeIconUrl =
          (me.image.isNotEmpty && me.image != 'NA' ? me.image : null);
      final bool hasLargeIconUrl = largeIconUrl != null &&
          (largeIconUrl.startsWith('http://') ||
              largeIconUrl.startsWith('https://'));

      final bool hasBigPictureUrl = imageUrl != null &&
          imageUrl.isNotEmpty &&
          imageUrl != 'NA' &&
          (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

      final String? iosAttachmentUrl = hasBigPictureUrl
          ? imageUrl
          : (hasLargeIconUrl ? largeIconUrl : null);
      final bool hasIosAttachmentUrl = iosAttachmentUrl != null &&
          iosAttachmentUrl.isNotEmpty &&
          (iosAttachmentUrl.startsWith('http://') ||
              iosAttachmentUrl.startsWith('https://'));

      var body = {
        'app_id': "3103e952-a0df-4841-a79a-6f221c8be76a",
        'ios_badgeType': 'Increase',
        'ios_badgeCount': 1,
        'android_badgeType': 'Increase',
        'android_badgeCount': 1,

        'include_player_ids': [
          // AppConstant.playerID
          chatUser.playerId
        ], // Send notification to this player ID
        'contents': {
          'en':
              '${(userArry is Map && userArry['name'] != null && userArry['name'].toString().trim().isNotEmpty) ? userArry['name'].toString() : (me.name.trim().isNotEmpty ? me.name : "Unknown")} sent a ${msg}.'
        },
        if (hasLargeIconUrl) 'large_icon': largeIconUrl,
        if (hasBigPictureUrl) 'big_picture': imageUrl,
        if (hasBigPictureUrl) 'chrome_big_picture': imageUrl,
        if (hasIosAttachmentUrl) 'ios_attachments': {'image': iosAttachmentUrl},
        if (hasIosAttachmentUrl) 'mutable_content': true,
        if (hasIosAttachmentUrl) 'content_available': true,
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
  static final Map<String, String> _conversationIdCache = {};

  static String _stableConversationId(String otherId) {
    final String a = user_id;
    final String b = otherId;

    final int? aInt = int.tryParse(a);
    final int? bInt = int.tryParse(b);

    if (aInt != null && bInt != null) {
      return aInt <= bInt ? '${aInt}_$bInt' : '${bInt}_$aInt';
    }

    return a.compareTo(b) <= 0 ? '${a}_$b' : '${b}_$a';
  }

  static List<String> _conversationIdCandidates(String otherId) {
    final String a = user_id;
    final String b = otherId;
    final String stable = _stableConversationId(otherId);
    final String direct1 = '${a}_$b';
    final String direct2 = '${b}_$a';
    final set = <String>{stable, direct1, direct2};
    return set.toList();
  }

  static Future<String> resolveConversationId(String otherId) async {
    final cached = _conversationIdCache[otherId];
    if (cached != null && cached.isNotEmpty) return cached;

    final candidates = _conversationIdCandidates(otherId);
    for (final id in candidates) {
      try {
        final snap = await firestore
            .collection('chats/$id/messages/')
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          _conversationIdCache[otherId] = id;
          return id;
        }
      } catch (_) {}
    }

    final fallback = _stableConversationId(otherId);
    _conversationIdCache[otherId] = fallback;
    return fallback;
  }

  static Future<String> _resolveConversationIdFromMessage(Message message) {
    final String otherId =
        message.fromId == user_id ? message.toId : message.fromId;
    return resolveConversationId(otherId);
  }

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

  static Stream<int> getUnreadMessagesCount() {
    final String uid = user_id.toString().trim();
    if (uid.isEmpty || uid == "12345678") {
      return Stream<int>.value(0);
    }

    final int? uidInt = int.tryParse(uid);

    int countUnreadMessages(QuerySnapshot<Map<String, dynamic>> snap) {
      int count = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final fromId = data['fromId']?.toString();

        final readValue = data['read'];
        final String readString = readValue == null ? "" : readValue.toString();
        final bool isUnread = readString.trim().isEmpty;

        if (!isUnread) continue;

        if (fromId == uid) continue;
        if (uidInt != null && fromId == uidInt.toString()) continue;

        count++;
      }
      return count;
    }

    late StreamController<int> controller;
    StreamSubscription? subString;
    StreamSubscription? subInt;

    int latestString = 0;
    int latestInt = 0;

    void emit() {
      if (!controller.isClosed) {
        controller.add(latestString + latestInt);
      }
    }

    controller = StreamController<int>.broadcast(
      onListen: () {
        subString = firestore
            .collectionGroup('messages')
            .where('toId', isEqualTo: uid)
            .snapshots()
            .listen(
          (snap) {
            latestString = countUnreadMessages(snap);
            emit();
          },
          onError: (_) {
            emit();
          },
        );

        if (uidInt != null) {
          subInt = firestore
              .collectionGroup('messages')
              .where('toId', isEqualTo: uidInt)
              .snapshots()
              .listen(
            (snap) {
              latestInt = countUnreadMessages(snap);
              emit();
            },
            onError: (_) {
              emit();
            },
          );
        } else {
          latestInt = 0;
          emit();
        }
      },
      onCancel: () async {
        await subString?.cancel();
        await subInt?.cancel();
        await controller.close();
      },
    );

    return controller.stream;
  }

  static Stream<int> getPendingBookingsCount() {
    late final StreamController<int> controller;
    Timer? timer;
    bool inFlight = false;
    int last = 0;

    Future<int> fetch() async {
      if (inFlight) return last;
      inFlight = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        final String rawUser = (prefs.getString("userDetails") ?? "").trim();
        if (rawUser.isEmpty) return 0;

        final dynamic decoded = jsonDecode(rawUser);
        final dynamic userIdRaw =
            decoded is Map ? decoded["user_id"] : null;
        final int userId = userIdRaw is int
            ? userIdRaw
            : int.tryParse(userIdRaw?.toString() ?? "") ?? 0;
        if (userId == 0) return 0;

        String token = AppConstant.token.toString().trim();
        if (token.isEmpty) {
          token = (prefs.getString("token") ?? "").toString().trim();
        }
        if (token.isEmpty) return 0;

        final headers = {'Authorization': 'Bearer $token'};

        final Uri tripsUrl = Uri.parse(
            "${AppConfigProvider.apiUrl}fetch_my_booking?user_id=$userId&trip_type_id=");
        final Uri propsUrl = Uri.parse(
            "${AppConfigProvider.apiUrl}get_user_property_booking?user_id=$userId&property_type_id=");

        final results = await Future.wait([
          http.get(tripsUrl, headers: headers),
          http.get(propsUrl, headers: headers),
        ]);

        int pending = 0;

        final tripsRes = results[0];
        if (tripsRes.statusCode == 200) {
          final dynamic body = jsonDecode(tripsRes.body);
          if (body is Map && body["success"] == true) {
            final dynamic arr = body["trip_arr"];
            if (arr is List) {
              for (final item in arr) {
                if (item is Map) {
                  final dynamic s = item["status"];
                  final int status = s is int ? s : int.tryParse(s?.toString() ?? "") ?? -1;
                  if (status == 0) pending++;
                }
              }
            }
          }
        }

        final propsRes = results[1];
        if (propsRes.statusCode == 200) {
          final dynamic body = jsonDecode(propsRes.body);
          if (body is Map && body["success"] == true) {
            final dynamic arr = body["data"];
            if (arr is List) {
              for (final item in arr) {
                if (item is Map) {
                  final dynamic s = item["booking_status"];
                  final int status = s is int ? s : int.tryParse(s?.toString() ?? "") ?? -1;
                  if (status == 0) pending++;
                }
              }
            }
          }
        }

        last = pending;
        return last;
      } catch (_) {
        return last;
      } finally {
        inFlight = false;
      }
    }

    controller = StreamController<int>.broadcast(
      onListen: () async {
        final v = await fetch();
        if (!controller.isClosed) controller.add(v);
        timer = Timer.periodic(const Duration(seconds: 30), (_) async {
          final vv = await fetch();
          if (!controller.isClosed) controller.add(vv);
        });
      },
      onCancel: () async {
        timer?.cancel();
        await controller.close();
      },
    );

    return controller.stream;
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

  static Future<List<ChatUser>> getUsersByIdsOnce(List<String> userIds) async {
    final ids = userIds.where((e) => e.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return <ChatUser>[];

    const int chunkSize = 10;
    final List<ChatUser> result = [];

    for (int i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(
        i,
        (i + chunkSize) > ids.length ? ids.length : (i + chunkSize),
      );
      final snap = await firestore
          .collection('users')
          .where('id', whereIn: chunk)
          .get();
      result.addAll(snap.docs.map((d) => ChatUser.fromJson(d.data())));
    }

    return result;
  }

  // for adding an user to my user when first message is send
  static Future<void> sendFirstMessage(
      ChatUser chatUser, String msg, TypeEnum type, bool isActive) async {
    await _ensureMutualChatLink(chatUser.id);
    await sendMessage(chatUser, msg, type, isActive);
  }

  static Future<void> _ensureMutualChatLink(String otherUserId) async {
    await firestore
        .collection('users')
        .doc(user_id)
        .collection('my_users')
        .doc(otherUserId)
        .set({}, SetOptions(merge: true));

    await firestore
        .collection('users')
        .doc(otherUserId)
        .collection('my_users')
        .doc(user_id)
        .set({}, SetOptions(merge: true));
  }

  static Future<void> backfillMyUsersFromRecentMessages({int limit = 100}) async {
    try {
      final String myId = user_id;
      if (myId.isEmpty) return;

      final int? myIdInt = int.tryParse(myId);

      final fromSnapshots = <QuerySnapshot<Map<String, dynamic>>>[
        await firestore
            .collectionGroup('messages')
            .where('fromId', isEqualTo: myId)
            .limit(limit)
            .get(),
      ];
      final toSnapshots = <QuerySnapshot<Map<String, dynamic>>>[
        await firestore
            .collectionGroup('messages')
            .where('toId', isEqualTo: myId)
            .limit(limit)
            .get(),
      ];

      if (myIdInt != null) {
        fromSnapshots.add(await firestore
            .collectionGroup('messages')
            .where('fromId', isEqualTo: myIdInt)
            .limit(limit)
            .get());
        toSnapshots.add(await firestore
            .collectionGroup('messages')
            .where('toId', isEqualTo: myIdInt)
            .limit(limit)
            .get());
      }

      final Set<String> otherIds = {};
      for (final snapshot in fromSnapshots) {
        for (final d in snapshot.docs) {
          final data = d.data();
          final toId = data['toId']?.toString();
          if (toId != null && toId.isNotEmpty && toId != myId) {
            otherIds.add(toId);
          }
        }
      }
      for (final snapshot in toSnapshots) {
        for (final d in snapshot.docs) {
          final data = d.data();
          final fromId = data['fromId']?.toString();
          if (fromId != null && fromId.isNotEmpty && fromId != myId) {
            otherIds.add(fromId);
          }
        }
      }

      if (otherIds.isEmpty) return;

      final batch = firestore.batch();
      for (final otherId in otherIds) {
        final docRef = firestore
            .collection('users')
            .doc(myId)
            .collection('my_users')
            .doc(otherId);
        batch.set(docRef, {}, SetOptions(merge: true));
      }
      await batch.commit();

      try {
        final batchOther = firestore.batch();
        for (final otherId in otherIds) {
          final docRef = firestore
              .collection('users')
              .doc(otherId)
              .collection('my_users')
              .doc(myId);
          batchOther.set(docRef, {}, SetOptions(merge: true));
        }
        await batchOther.commit();
      } catch (_) {}
    } catch (_) {}
  }

  static Future<Set<String>> getChatPartnerIdsFromRecentMessages(
      {int limit = 200}) async {
    try {
      final String myId = user_id;
      if (myId.isEmpty) return <String>{};

      final int? myIdInt = int.tryParse(myId);

      final fromSnapshots = <QuerySnapshot<Map<String, dynamic>>>[
        await firestore
            .collectionGroup('messages')
            .where('fromId', isEqualTo: myId)
            .limit(limit)
            .get(),
      ];
      final toSnapshots = <QuerySnapshot<Map<String, dynamic>>>[
        await firestore
            .collectionGroup('messages')
            .where('toId', isEqualTo: myId)
            .limit(limit)
            .get(),
      ];

      if (myIdInt != null) {
        fromSnapshots.add(await firestore
            .collectionGroup('messages')
            .where('fromId', isEqualTo: myIdInt)
            .limit(limit)
            .get());
        toSnapshots.add(await firestore
            .collectionGroup('messages')
            .where('toId', isEqualTo: myIdInt)
            .limit(limit)
            .get());
      }

      final Set<String> otherIds = {};
      for (final snapshot in fromSnapshots) {
        for (final d in snapshot.docs) {
          final data = d.data();
          final toId = data['toId']?.toString();
          if (toId != null && toId.isNotEmpty && toId != myId) {
            otherIds.add(toId);
          }
        }
      }
      for (final snapshot in toSnapshots) {
        for (final d in snapshot.docs) {
          final data = d.data();
          final fromId = data['fromId']?.toString();
          if (fromId != null && fromId.isNotEmpty && fromId != myId) {
            otherIds.add(fromId);
          }
        }
      }

      return otherIds;
    } catch (_) {
      return <String>{};
    }
  }

  static Future<Set<String>> getChatPartnerIdsFromChatsCollection(
      {int limit = 500}) async {
    try {
      final String myId = user_id;
      if (myId.isEmpty) return <String>{};

      final snap = await firestore.collection('chats').limit(limit).get();

      final Set<String> otherIds = {};
      for (final doc in snap.docs) {
        final id = doc.id;
        final parts = id.split('_');
        if (parts.length != 2) continue;

        final a = parts[0];
        final b = parts[1];

        if (a == myId && b.isNotEmpty) {
          otherIds.add(b);
        } else if (b == myId && a.isNotEmpty) {
          otherIds.add(a);
        }
      }

      return otherIds;
    } catch (_) {
      return <String>{};
    }
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
  static String getConversationID(String id) => _stableConversationId(id);

  static Query<Map<String, dynamic>> _messagesQueryByConversationId(
      String conversationId) {
    return firestore
        .collection('chats/$conversationId/messages/')
        .orderBy('sent', descending: true);
  }

  static Query<Map<String, dynamic>> _messagesQuery(ChatUser user) {
    return _messagesQueryByConversationId(getConversationID(user.id));
  }

  // for getting messages of a specific conversation from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(ChatUser user,
      {int? limit}) {
    final query = _messagesQuery(user);
    return (limit == null ? query : query.limit(limit)).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessagesByConversationId(
      String conversationId,
      {int? limit}) {
    final query = _messagesQueryByConversationId(conversationId);
    return (limit == null ? query : query.limit(limit)).snapshots();
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> getMessagesPage(
    ChatUser user, {
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    Query<Map<String, dynamic>> query = _messagesQuery(user).limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.get();
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> getMessagesPageByConversationId(
    String conversationId, {
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    Query<Map<String, dynamic>> query =
        _messagesQueryByConversationId(conversationId).limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.get();
  }

  // for sending message
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, TypeEnum type, bool isActive) async {
    try {
      await _ensureMutualChatLink(chatUser.id);
    } catch (_) {}

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

    final String conversationId = await resolveConversationId(chatUser.id);
    final ref = firestore.collection('chats/$conversationId/messages/');
    await ref.doc(time).set(message.toJson()).then((value) =>
        sendPushNotification(
            chatUser, type == TypeEnum.text ? msg : 'image', isActive,
            imageUrl: type == TypeEnum.image ? msg : null));
  }

  //update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    final String conversationId = await _resolveConversationIdFromMessage(message);
    firestore.collection('chats/$conversationId/messages/').doc(message.sent).update(
        {'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //get only last message of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessageByConversationId(
      String conversationId) {
    return firestore
        .collection('chats/$conversationId/messages/')
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
    final String conversationId = await resolveConversationId(chatUser.id);
    final ref = storage.ref().child(
        'images/$conversationId/${DateTime.now().millisecondsSinceEpoch}.$ext');

    //uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    //updating image in firestore database
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, TypeEnum.image, isActive);
  }

  //delete message
  static Future<void> deleteMessage(Message message) async {
    final String conversationId = await _resolveConversationIdFromMessage(message);
    await firestore
        .collection('chats/$conversationId/messages/')
        .doc(message.sent)
        .delete();

    if (message.type == TypeEnum.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  //update message
  static Future<void> updateMessage(Message message, String updatedMsg) async {
    final String conversationId = await _resolveConversationIdFromMessage(message);
    await firestore
        .collection('chats/$conversationId/messages/')
        .doc(message.sent)
        .update({'msg': updatedMsg});
  }
}
