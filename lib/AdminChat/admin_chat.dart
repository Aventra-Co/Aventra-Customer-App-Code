import 'dart:async';
import 'dart:convert';
import '/controller/app_image.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/app_color.dart';
import '../controller/app_config_provider.dart';
import '../controller/app_constant.dart';
import '../controller/app_firebase.dart';
import '../controller/app_font.dart';
import '../controller/app_language.dart';
import '../controller/app_loader.dart';
import '../controller/app_snack_bar_toast_message.dart';
import '../view/authentication/login_screen.dart';
import 'dart:ui' as ui;

class AdminChat extends StatefulWidget {
  final int otherUserId;
  // final String otherUserImage;
  final String otherUserName;
  // final String otherUserNameIdentify;
  final String deviceToken;
  // final String acceptAt;
  final String chatMetStatus;

  const AdminChat({
    super.key,
    required this.otherUserId,
    // required this.otherUserImage,
    required this.otherUserName,
    // required this.otherUserNameIdentify,
    required this.deviceToken,
    // required this.acceptAt,
    required this.chatMetStatus,
  });

  @override
  State<AdminChat> createState() => _ChatState();
}

class _ChatState extends State<AdminChat> {
  static const int _messagesPageSize = 30;
  bool _isApiCalling = false;
  final TextEditingController _textInputChatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<DatabaseEvent>? _latestMessagesSub;
  DatabaseReference? _messagesRef;
  final Map<String, Map<String, dynamic>> _messagesByKey = {};
  bool _isLoadingInitialMessages = true;
  bool _isLoadingMoreMessages = false;
  bool _hasMoreMessages = true;
  String? _oldestKey;
  // late DatabaseReference dbRef;
  List<Map<String, dynamic>> _listMessage = <Map<String, dynamic>>[];
  int _userId = 0;
  bool _isTextInputEmpty = false;
  bool _height = false;
  List<dynamic> _messageAll = <dynamic>[];
  int _openTextField = 0;
  String _userCreatedChatId = "";
  String _deleteUserChatId = "";
  String _otherUserCreatedChatId = "";
  bool _isMessageEmpty = false;
  final FocusNode _chatFocusNode = FocusNode();
  String _mobileNumber = "";

  @override
  void initState() {
    // getGetMetUserApi(widget.otherUserId);
    super.initState();
    _scrollController.addListener(_onScroll);
    _getUserDetails().then((_) {
      if (_userCreatedChatId.isNotEmpty) {
        _initMessagePagination();
      }
    });
    getNumberApiCall();
    FirebaseProvider.firebaseCreateUser(true, 'yes');
  }

  //------------------------GET NUMBER API CALL--------------------------------//
  Future<void> getNumberApiCall() async {
    Uri url = Uri.parse("${AppConfigProvider.apiUrl}get_admin_number");
    String token = AppConstant.token;

    // if (token.isEmpty) return;


    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      final http.Response response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);

        if (res['success'] == true) {
          _mobileNumber = res['admin_number'].toString();
        }
        else {
          // ignore: use_build_context_synchronously
          if (res['active_status'] == 0) {
            SnackBarToastMessage.showSnackBar(context, res['msg'][language]);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
          }
        }
      }
    }
    catch (e) {
      debugPrint(e.toString());
    }
  }

  //===============DIAL PAD FUNCTION===============//
  Future<void> openDialPad(String phoneNumber) async {
    final Uri url = Uri.parse('tel:+965$phoneNumber');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingInitialMessages || _isLoadingMoreMessages || !_hasMoreMessages) return;
    final ScrollPosition position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMoreMessages();
    }
  }

  Future<void> _initMessagePagination() async {
    _messagesRef = FirebaseDatabase.instance.ref('message/$_userCreatedChatId');
    await _loadInitialMessages();
    _listenForLatestMessages();
  }

  void _listenForLatestMessages() {
    final DatabaseReference? ref = _messagesRef;
    if (ref == null) return;
    _latestMessagesSub?.cancel();
    _latestMessagesSub = ref.orderByKey().limitToLast(_messagesPageSize).onValue.listen((event) {
      final List<Map<String, dynamic>> entries = _snapshotToEntries(event.snapshot);
      _upsertEntries(entries);
    });
  }

  Future<void> _loadInitialMessages() async {
    final DatabaseReference? ref = _messagesRef;
    if (ref == null) return;
    if (mounted) {
      setState(() {
        _isLoadingInitialMessages = true;
        _isLoadingMoreMessages = false;
        _hasMoreMessages = true;
        _oldestKey = null;
        _messagesByKey.clear();
        _listMessage = [];
      });
    }

    try {
      final DataSnapshot snapshot = await ref.orderByKey().limitToLast(_messagesPageSize).get();
      final List<Map<String, dynamic>> entries = _snapshotToEntries(snapshot);
      if (entries.isEmpty) {
        if (mounted) {
          setState(() => _hasMoreMessages = false);
        }
        return;
      }

      _hasMoreMessages = entries.length == _messagesPageSize;
      _upsertEntries(entries);
      _ensureScrollableOrDone();
    }
    catch (_) {
      if (mounted) {
        setState(() => _hasMoreMessages = false);
      }
    }
    finally {
      if (mounted) {
        setState(() => _isLoadingInitialMessages = false);
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMoreMessages || !_hasMoreMessages) return;
    final DatabaseReference? ref = _messagesRef;
    if (ref == null) return;
    final String? oldestKey = _oldestKey;
    if (oldestKey == null) {
      if (mounted) {
        setState(() => _hasMoreMessages = false);
      }
      return;
    }
    if (mounted) {
      setState(() => _isLoadingMoreMessages = true);
    }

    try {
      final DataSnapshot snapshot = await ref.orderByKey().endAt(oldestKey).limitToLast(_messagesPageSize + 1).get();
      final List<Map<String, dynamic>> entries = _snapshotToEntries(snapshot);
      if (entries.isEmpty) {
        if (mounted) {
          setState(() => _hasMoreMessages = false);
        }
        return;
      }

      final bool added = _upsertEntries(entries);
      if (!added) {
        if (mounted) {
          setState(() => _hasMoreMessages = false);
        }
        return;
      }

      _hasMoreMessages = entries.length == _messagesPageSize + 1;
      _ensureScrollableOrDone();
    }
    catch (_) {
      if (mounted) {
        setState(() => _hasMoreMessages = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMoreMessages = false);
      }
    }
  }

  void _ensureScrollableOrDone() {
    if (!mounted || _isLoadingInitialMessages || _isLoadingMoreMessages || !_hasMoreMessages) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent < 50) {
        _loadMoreMessages();
      }
    });
  }

  List<Map<String, dynamic>> _snapshotToEntries(DataSnapshot snapshot) {
    final Object? value = snapshot.value;
    if (value == null || value is! Map) return [];

    final List<Map<String, dynamic>> entries = [];
    value.forEach((key, data) {
      if (data is Map) {
        entries.add(_normalizeEntry(key.toString(), Map<String, dynamic>.from(data)));
      }
    });
    return entries;
  }

  Map<String, dynamic> _normalizeEntry(String key, Map<String, dynamic> data) {
    final String ts = (data['timestamp'] ?? '').toString();
    return {
      'key': key,
      'senderId': data['senderId'],
      'last_seen': data['last_seen'],
      'messageType': data['messageType'],
      'msg_time': data['msg_time'],
      'message': data['message'],
      'timestamp': data['timestamp'],
      'MsgTimeShamp': ts,
    };
  }

  bool _upsertEntries(List<Map<String, dynamic>> entries) {
    bool changed = false;

    for (final Map<String, dynamic> entry in entries) {
      final String key = (entry['key'] ?? '').toString();
      if (key.isEmpty) continue;

      final Map<String, dynamic>? previous = _messagesByKey[key];
      if (previous == null ||
          previous['message'] != entry['message'] ||
          previous['last_seen'] != entry['last_seen'] ||
          previous['messageType'] != entry['messageType'] ||
          previous['timestamp'] != entry['timestamp']) {
        _messagesByKey[key] = entry;
        changed = true;
      }
    }

    if (!changed || !mounted) return false;

    final List<Map<String, dynamic>> merged = _messagesByKey.values.toList()
      ..sort((a, b) {
        final String one = (a['key'] ?? '').toString();
        final String two = (b['key'] ?? '').toString();
        return two.compareTo(one);
      });

    final String? oldest = merged.isNotEmpty ? (merged.last['key'] ?? '').toString() : null;

    setState(() {
      _listMessage = merged;
      _oldestKey = (oldest == null || oldest.isEmpty) ? null : oldest;
    });

    return true;
  }

  Future<void> _getUserDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic userDetails = prefs.getString('userDetails');

    //--------------Firebase Get Other User Inbox ---------------
    if (userDetails != null) {
      setState(() => _isApiCalling = false);
      dynamic userDetail = jsonDecode(userDetails);
      // print("userDetail $userDetail['avatar']");
      _userId = userDetail['user_id'];

      FirebaseProvider.setOtherUserMessageCountZero(_userId.toString(), widget.otherUserId.toString());

      String otherUserId = widget.otherUserId.toString();
      // print('otherUserId $otherUserId');

      // print("u_$otherUserId");

      _deleteUserChatId = "u_$otherUserId";
      // print("deleteUserChatId : $_deleteUserChatId");

      String userChatId = 'u_${_userId}__u_$otherUserId';
      // print("userChatId : $userChatId");

      _userCreatedChatId = userChatId;

      _otherUserCreatedChatId = 'u_${otherUserId}__u_$_userId';
    }

    await FirebaseDatabase.instance.ref('message/$_userCreatedChatId').get().then((snap) {
      if (snap.value == null) {
        _isMessageEmpty = true;
      }
      _isApiCalling = false;
      setState(() {});
    }).catchError((error) {});

    setState(() {});
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  bool _shouldHideKeyboard() => true;

  @override
  void dispose() {
    _latestMessagesSub?.cancel();
    _scrollController.dispose();
    _textInputChatController.dispose();
    _chatFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      inAsyncCall: _isApiCalling,
      opacity: 0.5,
      child: _buildUIScreen(context),
    );
  }

  Widget _buildUIScreen(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColor.transparentColor,
      statusBarIconBrightness: Brightness.dark,
    ));
    final bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (keyboardVisible == false) {
      setState(() => _height = false);
    }
    if (keyboardVisible == true) {
      setState(() => _height = true);
    }

    return WillPopScope(
      onWillPop: () async {
        // Capture a print value when the back button is pressed

        // Determine whether to hide the keyboard or not
        if (_shouldHideKeyboard()) {
          FocusScope.of(context).unfocus();
        }

        return true; // Allow back navigation
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // SizedBox(height: MediaQuery.of(context).size.height * 1 / 100),
                    Directionality(
                      textDirection: language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 7 / 100,
                        width: MediaQuery.of(context).size.width * 90 / 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Transform.rotate(
                                angle: language == 1 ? 3.1416 : 0,
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.width * 5 / 100,
                                  width: MediaQuery.of(context).size.width * 5 / 100,
                                  child: Image.asset(
                                    AppImage.navigateBackIcon,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.width * 4 / 100,
                              width: MediaQuery.of(context).size.width * 4 / 100,
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 73 / 100,
                              child: Text(
                                AppLanguage.helpAndSupportText[language],
                                style: const TextStyle(
                                  color: AppColor.primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppFont.fontFamily,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => openDialPad(_mobileNumber),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.width * 5 / 100,
                                width: MediaQuery.of(context).size.width * 5 / 100,
                                child: Image.asset(AppImage.phoneIcon),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(bottom: 11),
                      height: _height == false ? MediaQuery.of(context).size.height * 78 / 100 : MediaQuery.of(context).size.height * 42 / 100,
                      width: MediaQuery.of(context).size.width * 100 / 100,
                      color: Colors.white,
                      child: Builder(builder: (context) {
                        if (_isLoadingInitialMessages) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (_listMessage.isEmpty) {
                          return const Text('');
                        }

                        final bool showLoader = _isLoadingMoreMessages;
                        final bool showNoMore = !_hasMoreMessages && _listMessage.isNotEmpty;
                        final int itemCount = _listMessage.length + (showLoader ? 1 : 0) + (showNoMore ? 1 : 0);

                        return ListView.builder(
                          controller: _scrollController,
                          physics: const ClampingScrollPhysics(),
                          reverse: true,
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          itemCount: itemCount,
                          itemBuilder: (BuildContext context, index) {
                            if (index >= _listMessage.length) {
                              final int extraIndex = index - _listMessage.length;
                              if (showLoader && extraIndex == 0) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(color: AppColor.primaryColor, strokeWidth: 2),
                                  ),
                                );
                              }

                              return SizedBox();
                            }

                            final Map<String, dynamic> item = _listMessage[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: Column(
                                children: [
                                  InkWell(
                                    onLongPress: () {},
                                    child: Container(
                                      alignment: (item['senderId'].toString() != _userId.toString()) ? Alignment.topLeft : Alignment.topRight,
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.80,
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                        margin: const EdgeInsets.symmetric(vertical: 2),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(15),
                                            topRight: const Radius.circular(15),
                                            bottomRight: Radius.circular((item['senderId'].toString() != _userId.toString()) ? 15 : 0),
                                            bottomLeft: Radius.circular((item['senderId'].toString() != _userId.toString()) ? 0 : 15),
                                          ),
                                          color: (item['senderId'].toString() != _userId.toString()) ? AppColor.themeColor : AppColor.themeColor,
                                        ),
                                        child: Text(
                                          item['message'].toString(),
                                          style: TextStyle(
                                            color: (item['senderId'].toString() != _userId.toString()) ? Colors.white : Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    alignment: (item['senderId'].toString() != _userId.toString()) ? Alignment.topLeft : Alignment.topRight,
                                    child: Row(
                                      mainAxisAlignment: (item['senderId'].toString() != _userId.toString()) ? MainAxisAlignment.start : MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(item['MsgTimeShamp'].toString())),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: MediaQuery.of(context).size.height * 2 / 100),
                                ],
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
                Directionality(
                  textDirection: language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          _chatFocusNode.hasFocus ? BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 5,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ) : BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 5,
                            blurRadius: 5,
                            offset: const Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(0),
                        child: TextFormField(
                          enabled: true,
                          controller: _textInputChatController,
                          textCapitalization: TextCapitalization.sentences,
                          cursorColor: Colors.grey,
                          keyboardType: TextInputType.text,
                          focusNode: _chatFocusNode,
                          decoration: InputDecoration(
                            counterText: '',
                            suffixIcon: InkWell(
                              onTap: () {
                                if (_textInputChatController.text.isNotEmpty) {
                                  FirebaseProvider.sendMessage(
                                    _userId.toString(),
                                    widget.otherUserId.toString(),
                                    widget.otherUserName,
                                    _textInputChatController.text,
                                    widget.deviceToken,
                                  );

                                  _messageAll = [];
                                  if (_height == false) {
                                    setState(() => _height = false);
                                  }
                                  if (_height == true) {
                                    setState(() => _height = true);
                                  }
                                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                                }
                                _textInputChatController.clear();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(9.0),
                                child: Transform.rotate(
                                  angle: language == 1 ? 3.1416 : 0,
                                  child: Image.asset(
                                    _isTextInputEmpty ? AppImage.sendIcon : AppImage.sendIcon,
                                    width: 5,
                                    height: 5,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey, width: 0.6),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey, width: 0.6),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey, width: 0.6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                            fillColor: Colors.white,
                            filled: true,
                            errorStyle: const TextStyle(color: Colors.red),
                            hintText: AppLanguage.enterMsgText[language],
                            hintStyle: const TextStyle(
                              color: Color(0xff999999),
                              fontSize: 14.0,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          onTap: () {
                            if (_listMessage.isNotEmpty) {
                              _scrollToBottom();
                            }

                            setState(() {
                              _openTextField = 1;
                              _height = true;
                            });
                          },
                          onEditingComplete: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() {
                              _openTextField = 0;
                              _height = false;
                            });
                          },
                          onChanged: (input) {
                            if (input.isNotEmpty) {
                              _isTextInputEmpty = true;
                            }
                            else {
                              _isTextInputEmpty = false;
                            }
                            setState(() => _height = true);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
