import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_header.dart';

class Content extends StatelessWidget {
  static String routeName = './Content';
  const Content({super.key});

  @override
  Widget build(BuildContext context) {
    ContentClass? object;
    object = ModalRoute.of(context)!.settings.arguments as ContentClass;
    return Scaffold(
      body: ContentScreen(
        header: object.header,
        contenttype: object.contenttype,
      ),
    );
  }
}

class ContentScreen extends StatefulWidget {
  final String header;
  final String contenttype;

  const ContentScreen(
      {super.key, required this.header, required this.contenttype});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen>
    with SingleTickerProviderStateMixin {
  bool isApiCalling = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColor.secondaryColor,
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: AppBar(
              backgroundColor: AppColor.secondaryColor,
              systemOverlayStyle: const SystemUiOverlayStyle(
                  systemNavigationBarColor: AppColor.secondaryColor,
                  systemNavigationBarIconBrightness: Brightness.dark,
                  statusBarColor: AppColor.secondaryColor,
                  statusBarIconBrightness: Brightness.dark))),
      body: SafeArea(
          child: Container(
        height: screenHeight,
        width: screenWidth,
        color: AppColor.secondaryColor,
        child: Column(
          children: [
            const NoInternetBanner(),
            AppHeader(
              text: widget.header,
              onPress: () {
                Navigator.pop(context);
              },
            ),
            Expanded(
                flex: 1,
                child: Container(
                  height: screenHeight,
                  width: screenWidth * 0.95,
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      // WebView - Hidden initially
                      AnimatedOpacity(
                        opacity: isApiCalling ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: WebView(
                          initialUrl: widget.contenttype,
                          backgroundColor: AppColor.secondaryColor,
                          onWebViewCreated:
                              (WebViewController webViewController) {},
                          onProgress: (int progress) {
                            print("WebView is loading (progress : $progress%)");
                          },
                          onPageStarted: (String url) {
                            print('Page started loading: $url');
                            if (mounted) {
                              setState(() {
                                isApiCalling = true;
                              });
                            }
                          },
                          onPageFinished: (String url) {
                            print('Page finished loading: $url');
                            Future.delayed(const Duration(milliseconds: 800),
                                () {
                              if (mounted) {
                                setState(() {
                                  isApiCalling = false;
                                });
                              }
                            });
                          },
                        ),
                      ),

                      // Loading Overlay - Responsive Design
                      if (isApiCalling)
                        Container(
                          color: AppColor.secondaryColor,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: screenWidth * 0.08,
                                  height: screenWidth * 0.08,
                                  child: RotationTransition(
                                    turns: _animationController,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColor.themeColor,
                                      ),
                                      strokeWidth: 2.5,
                                      backgroundColor:
                                          Colors.grey.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                )),
          ],
        ),
      )),
    );
  }
}
