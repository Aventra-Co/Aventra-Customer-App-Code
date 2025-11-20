import 'package:firebase_auth/firebase_auth.dart';

class ChatUser {
  ChatUser({
    required this.image,
    required this.about,
    required this.name,
    required this.createdAt,
    required this.isOnline,
    required this.id,
    required this.lastActive,
    required this.email,
    required this.pushToken,
    required this.mobile,
    required this.playerId,
    required this.groups,
  });

  late String image;
  late String about;
  late String name;
  late String createdAt;
  late bool isOnline;
  late String id;
  late String lastActive;
  late String email;
  late String pushToken;
  late String mobile;
  late String playerId;
  late List<String> groups; // List to store group IDs

  ChatUser.fromJson(Map<String, dynamic> json) {
    image = json['image'] ?? '';
    about = json['about'] ?? '';
    name = json['name'] ?? '';
    createdAt = json['created_at'] ?? '';
    isOnline = json['is_online'] ?? false;
    id = json['id'] ?? '';
    lastActive = json['last_active'] ?? '';
    email = json['email'] ?? '';
    pushToken = json['push_token'] ?? '';
    mobile = json['mobile'] ?? '';
    playerId = json['playerId'] ?? '';
    groups = List<String>.from(
        json['groups'] ?? []); // Convert JSON list to List<String>
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'about': about,
      'name': name,
      'created_at': createdAt,
      'is_online': isOnline,
      'id': id,
      'last_active': lastActive,
      'email': email,
      'push_token': pushToken,
      'mobile': mobile,
      'playerId': playerId,
      'groups': groups, // Convert List<String> to JSON list
    };
  }
}
