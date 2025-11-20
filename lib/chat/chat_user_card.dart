//card to represent a single user in home screen
import 'package:flutter/material.dart';
import '../controller/app_color.dart';
import '../helper/apis.dart';
import '../helper/my_date_util.dart';
import '../helper/profile_dialog.dart';
import '../model/chat_user.dart';
import '../model/message.dart';
import 'chat_screen.dart';
import 'profile_image.dart';

//card to represent a single user in home screen
class ChatUserCard extends StatefulWidget {
  final ChatUser user;

  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  //last message info (if null --> no message)
  Message? _message;

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        color: AppColor.white,
        elevation: 0.5,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15))),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          onTap: () {
            //for navigating to chat screen

            print(widget.user);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen(user: widget.user)));
          },
          child: StreamBuilder(
            stream: APIs.getLastMessage(widget.user),
            builder: (context, snapshot) {
              final data = snapshot.data?.docs;
              final list =
                  data?.map((e) => Message.fromJson(e.data())).toList() ?? [];

              if (list.isNotEmpty) {
                _message = list[0];
              } else {
                return const SizedBox(); // Hide user if there's no last message
              }

              return ListTile(
                tileColor: AppColor.secondaryColor,
                // User profile picture
                leading: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => ProfileDialog(user: widget.user),
                    );
                  },
                  child: ProfileImage(size: 40, url: widget.user.image),
                ),

                // User name
                title: Text(widget.user.name),

                // Last message
                subtitle: Text(
                  _message!.type == Type.image ? 'Image' : _message!.msg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Last message time or unread indicator
                trailing: _message!.read.isEmpty &&
                        _message!.fromId != APIs.user_id
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 0, 230, 119),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      )
                    : Text(
                        MyDateUtil.getLastMessageTime(
                          context: context,
                          time: _message!.sent,
                        ),
                        style: const TextStyle(color: Colors.black54),
                      ),
              );
            },
          ),
        ));
  }
}
