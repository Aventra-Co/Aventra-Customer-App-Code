import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../chat/chat_user_card.dart';
import '../../controller/app_footer.dart';
import '../../helper/apis.dart';
import '../../model/chat_user.dart';
import '../../model/message.dart';
import '../authentication/login_screen.dart';
import '../../controller/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_font.dart';
import '../../controller/app_language.dart';
// import '../other_screen/chat_screen.dart';
// import '../other_screen/chat_screen.dart';

class Inbox extends StatefulWidget {
  static String routeName = './Inbox';
  const Inbox({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _InboxState createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  TextEditingController currentPasswordTextEditingController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool searchStatus = false;
  bool isApiCalling = false;
  int userId = 0;
  dynamic data;
  dynamic userDataArr;
  List<dynamic> chatList = [
    {
      "id": 1,
      "userImage": "./assets/icons/userProfile1.jpg",
      "userName": "Mahmoud Tst",
      "userMessage": "yes go for it",
      "timeAgo": "2 min ago",
      "readStatus": false,
    },
    {
      "id": 2,
      "userImage": "./assets/icons/userProfile1.jpg",
      "userName": "The Great Ocean Road",
      "userMessage": "yes go for it",
      "timeAgo": "5 min ago",
      "readStatus": true,
    },
  ];
  bool _isSearching = false;
  List<ChatUser> _allUsers = [];
  List<ChatUser> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    getUserDetails();
  }

  //----------------------------GET USER DETAILS--------------------------------//
  Future<dynamic> getUserDetails() async {
    setState(() {
      isApiCalling = true;
    });
    final prefs = await SharedPreferences.getInstance();
    data = prefs.getString("userDetails");

    // print("userDetails $userDetails");
    if (isGuest) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Login()));
      return;
    }
    if (data == null) {
      // print("worked");
      // SnackBarToastMessage.showSnackBar(
      //     context, AppLanguage.notRegisteredMsg[language]);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Login()));
    } else {
      userDataArr = jsonDecode(data);
      userId = userDataArr['user_id'] ?? 0;
    }

    isApiCalling = false;
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

// Update your _onSearchChanged method
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _filteredUsers = _allUsers.where((user) {
          return user.name.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColor.secondaryColor,
        statusBarIconBrightness: Brightness.dark));
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () async {
          AppConstant.selectFooterIndex = 0;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyFooterPage(),
            ),
          );
          return Future.value(false);
        },
        child: Scaffold(
          backgroundColor: AppColor.secondaryColor,
          body: SafeArea(
              child: Container(
            width: MediaQuery.of(context).size.width * 100 / 100,
            height: MediaQuery.of(context).size.height * 100 / 100,
            color: AppColor.secondaryColor,
            child: Column(
              children: [
                const NoInternetBanner(),
                Container(
                  // color: Colors.red,
                  height: MediaQuery.of(context).size.height * 7 / 100,
                  width: MediaQuery.of(context).size.width * 90 / 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLanguage.chatText[language],
                          style: const TextStyle(
                              color: AppColor.primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFont.fontFamily)),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            searchStatus = !searchStatus;
                          });
                        },
                        child: Container(
                          // color: Colors.green,
                          height: screenWidth > 600
                              ? MediaQuery.of(context).size.width * 10 / 100
                              : MediaQuery.of(context).size.width * 12 / 100,
                          width: screenWidth > 600
                              ? MediaQuery.of(context).size.width * 8 / 100
                              : MediaQuery.of(context).size.width * 13 / 100,
                          child: Image.asset(
                            AppImage.searchRoundIcon,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (searchStatus == true)
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 90 / 100,
                      height: MediaQuery.of(context).size.height * 6 / 100,
                      child: TextFormField(
                        readOnly: false,
                        style: AppConstant.textFilledHeading,
                        textAlignVertical: TextAlignVertical.center,
                        keyboardType: TextInputType.name,
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                child: Image.asset(
                                  AppImage.searchIcon1,
                                  height: screenWidth > 600
                                      ? MediaQuery.of(context).size.width *
                                          3 /
                                          100
                                      : MediaQuery.of(context).size.width *
                                          5 /
                                          100,
                                  width: screenWidth > 600
                                      ? MediaQuery.of(context).size.width *
                                          3 /
                                          100
                                      : MediaQuery.of(context).size.width *
                                          5 /
                                          100,
                                ),
                              ),
                            ],
                          ),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColor.textinputBorderColor),
                            borderRadius: BorderRadius.all(Radius.circular(25)),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColor.textinputBorderColor),
                            borderRadius: BorderRadius.all(Radius.circular(25)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColor.textinputBorderColor),
                            borderRadius: BorderRadius.all(Radius.circular(25)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 15),
                          filled: false,
                          counterText: '',
                          hintText: AppLanguage.searchInputText[language],
                          hintStyle: const TextStyle(
                              color: AppColor.hintTextinputColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              fontFamily: AppFont.fontFamily),
                        ),
                      ),
                    ),
                  ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 1 / 100,
                ),

                // User List
                Expanded(
                  child: StreamBuilder<List<ChatUser>>(
                    stream: getChatUsersSorted(),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const Center(
                              child: CircularProgressIndicator());

                        case ConnectionState.active:
                        case ConnectionState.done:
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }

                          // Update _allUsers when new data arrives
                          _allUsers = snapshot.data ?? [];

                          // Apply search filter if searching
                          final displayUsers =
                              _isSearching ? _filteredUsers : _allUsers;

                          if (displayUsers.isEmpty) {
                            return Center(
                              child: Text(
                                _isSearching
                                    ? 'No matching users found!'
                                    : 'No users available!',
                                style: const TextStyle(fontSize: 18),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: displayUsers.length,
                            padding: const EdgeInsets.only(top: 2),
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return Builder(
                                builder: (context) {
                                  if (displayUsers.isNotEmpty) {
                                    return ChatUserCard(
                                        user: displayUsers[index]);
                                  } else {
                                    return Column(
                                      children: [
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              20 /
                                              100,
                                        ),
                                        Container(
                                          alignment: Alignment.center,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              90 /
                                              100,
                                          child: const Text(
                                            'No users available',
                                            style: TextStyle(
                                                fontFamily: AppFont.fontFamily,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: AppColor.primaryColor),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              );
                            },
                          );
                      }
                    },
                  ),
                ),

                // Expanded(
                //   flex: 1,
                //   child: SingleChildScrollView(
                //     child: Column(
                //       children: [
                //         SizedBox(
                //             height:
                //                 MediaQuery.of(context).size.height * 2 / 100),
                //         Container(
                //           width: MediaQuery.of(context).size.width * 90 / 100,
                //           child: SingleChildScrollView(
                //             scrollDirection: Axis.vertical,
                //             child: Wrap(
                //               spacing: 10,
                //               runSpacing:
                //                   MediaQuery.of(context).size.height * 3 / 100,
                //               children: List.generate(chatList.length, (index) {
                //                 return GestureDetector(
                //                   onTap: () {
                //                     Navigator.push(
                //                         context,
                //                         MaterialPageRoute(
                //                             builder: (context) =>
                //                                 const Chat()));
                //                   },
                //                   child: Row(
                //                     mainAxisAlignment:
                //                         MainAxisAlignment.spaceBetween,
                //                     crossAxisAlignment:
                //                         CrossAxisAlignment.start,
                //                     children: [
                //                       ClipRRect(
                //                         borderRadius:
                //                             BorderRadius.circular(100),
                //                         child: Container(
                //                           width: screenWidth > 600
                //                               ? MediaQuery.of(context)
                //                                       .size
                //                                       .width *
                //                                   10 /
                //                                   100
                //                               : MediaQuery.of(context)
                //                                       .size
                //                                       .width *
                //                                   12 /
                //                                   100,
                //                           height: screenWidth > 600
                //                               ? MediaQuery.of(context)
                //                                       .size
                //                                       .width *
                //                                   10 /
                //                                   100
                //                               : MediaQuery.of(context)
                //                                       .size
                //                                       .width *
                //                                   12 /
                //                                   100,
                //                           child: Image.asset(
                //                             chatList[index]['userImage'],
                //                             fit: BoxFit.cover,
                //                           ),
                //                         ),
                //                       ),
                //                       Container(
                //                         width:
                //                             MediaQuery.of(context).size.width *
                //                                 57 /
                //                                 100,
                //                         margin: EdgeInsets.only(top: 5),
                //                         child: Column(
                //                           crossAxisAlignment:
                //                               CrossAxisAlignment.start,
                //                           mainAxisAlignment:
                //                               MainAxisAlignment.center,
                //                           children: [
                //                             Text(
                //                               chatList[index]['userName'],
                //                               style: const TextStyle(
                //                                   color: AppColor.primaryColor,
                //                                   fontSize: 14,
                //                                   fontWeight: FontWeight.w600,
                //                                   fontFamily:
                //                                       AppFont.fontFamily),
                //                             ),
                //                             Text(
                //                               chatList[index]['userMessage'],
                //                               style: const TextStyle(
                //                                   color: AppColor.primaryColor,
                //                                   fontSize: 12,
                //                                   fontWeight: FontWeight.w400,
                //                                   fontFamily:
                //                                       AppFont.fontFamily),
                //                             ),
                //                           ],
                //                         ),
                //                       ),
                //                       GestureDetector(
                //                         onTap: () {
                //                           Navigator.push(
                //                               context,
                //                               MaterialPageRoute(
                //                                   builder: (context) =>
                //                                       const Chat()));
                //                         },
                //                         child: Container(
                //                           // width:
                //                           //     MediaQuery.of(context).size.width *
                //                           //         6 /
                //                           //         100,
                //                           child: Column(
                //                             crossAxisAlignment:
                //                                 CrossAxisAlignment.end,
                //                             children: [
                //                               Container(
                //                                 // width: MediaQuery.of(context)
                //                                 //         .size
                //                                 //         .width *
                //                                 //     15 /
                //                                 //     100,
                //                                 margin: EdgeInsets.only(top: 5),
                //                                 child: Text(
                //                                   chatList[index]['timeAgo'],
                //                                   style: const TextStyle(
                //                                       color: AppColor
                //                                           .hintTextinputColor,
                //                                       fontSize: 12,
                //                                       fontWeight:
                //                                           FontWeight.w500,
                //                                       fontFamily:
                //                                           AppFont.fontFamily),
                //                                 ),
                //                               ),
                //                               SizedBox(
                //                                   height: MediaQuery.of(context)
                //                                           .size
                //                                           .height *
                //                                       .2 /
                //                                       100),
                //                               if (chatList[index]
                //                                       ['readStatus'] ==
                //                                   false)
                //                                 Container(
                //                                   width: MediaQuery.of(context)
                //                                           .size
                //                                           .width *
                //                                       5 /
                //                                       100,
                //                                   height: MediaQuery.of(context)
                //                                           .size
                //                                           .width *
                //                                       5 /
                //                                       100,
                //                                   decoration:
                //                                       const BoxDecoration(
                //                                     color: AppColor.themeColor,
                //                                     shape: BoxShape.circle,
                //                                   ),
                //                                   child: const Center(
                //                                     child: Text(
                //                                       "1",
                //                                       // textAlign: TextAlign.center,
                //                                       style: TextStyle(
                //                                           color: AppColor
                //                                               .secondaryColor,
                //                                           fontSize: 10,
                //                                           fontWeight:
                //                                               FontWeight.w500,
                //                                           fontFamily: AppFont
                //                                               .fontFamily),
                //                                     ),
                //                                   ),
                //                                 )
                //                             ],
                //                           ),
                //                         ),
                //                       )
                //                     ],
                //                   ),
                //                 );
                //               }),
                //             ),
                //           ),
                //         ),
                //         SizedBox(
                //             height:
                //                 MediaQuery.of(context).size.height * 2 / 100),
                //       ],
                //     ),
                //   ),
                // )
              ],
            ),
          )),
        ),
      ),
    );
  }

  Stream<List<ChatUser>> getChatUsersSorted() {
    return APIs.firestore
        .collection("users")
        .snapshots()
        .asyncMap((snapshot) async {
      final currentUserId = APIs.user_id;

      // Get all users except current user
      final users = snapshot.docs
          .map((doc) => ChatUser.fromJson(doc.data()))
          .where((user) => user.id != currentUserId)
          .toList();

      final List<MapEntry<ChatUser, DateTime>> userLastMessageTimes = [];

      for (final user in users) {
        try {
          DateTime lastMessageTime = DateTime(0);
          final messageQuery = await APIs.getLastMessage(user).first;

          if (messageQuery.docs.isNotEmpty) {
            final latestMessage = messageQuery.docs
                .map((doc) => Message.fromJson(doc.data()))
                .reduce((a, b) {
              final aTime = _parseMessageTime(a.sent);
              final bTime = _parseMessageTime(b.sent);
              return aTime.isAfter(bTime) ? a : b;
            });

            lastMessageTime = _parseMessageTime(latestMessage.sent);
          }

          userLastMessageTimes.add(MapEntry(user, lastMessageTime));

          // Debug print to verify timestamps
          debugPrint('User: ${user.name}, Last message: $lastMessageTime');
        } catch (e) {
          debugPrint('Error for user ${user.id}: $e');
          userLastMessageTimes.add(MapEntry(user, DateTime(0)));
        }
      }

      // Sort by last message time (newest first)
      userLastMessageTimes.sort((a, b) => b.value.compareTo(a.value));

      return userLastMessageTimes.map((entry) => entry.key).toList();
    });
  }

  DateTime _parseMessageTime(dynamic sentTime) {
    if (sentTime == null) return DateTime(0);
    if (sentTime is Timestamp) return sentTime.toDate();
    if (sentTime is String) {
      final dateTime = DateTime.tryParse(sentTime);
      if (dateTime != null) return dateTime;

      final epochMillis = int.tryParse(sentTime);
      if (epochMillis != null)
        return DateTime.fromMillisecondsSinceEpoch(epochMillis);
    }
    if (sentTime is int) return DateTime.fromMillisecondsSinceEpoch(sentTime);
    if (sentTime is DateTime) return sentTime;
    return DateTime(0);
  }
}
