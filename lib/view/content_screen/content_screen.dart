import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../controller/app_color.dart';
import '../../controller/app_constant.dart';
import '../../controller/app_header.dart';
import 'dart:ui' as ui;

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

class _ContentScreenState extends State<ContentScreen> {
  bool isApiCalling = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    log(widget.contenttype);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: AppColor.secondaryColor,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return Scaffold(
      backgroundColor: AppColor.secondaryColor,
      body: SafeArea(
          child: Directionality(
        textDirection:
            language == 1 ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Container(
          height: MediaQuery.of(context).size.height * 100 / 100,
          width: MediaQuery.of(context).size.width * 100 / 100,
          color: AppColor.secondaryColor,
          child: Column(
            children: [
              // const NoInternetBanner(),

              AppHeader(
                  text: widget.header,
                  onPress: () {
                    Navigator.pop(context);
                  }),
              Expanded(
                  flex: 1,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 100 / 100,
                    width: MediaQuery.of(context).size.width * 95 / 100,
                    alignment: Alignment.center,
                    child: WebView(
                      initialUrl: widget.contenttype,
                      onProgress: (int progress) {
                        print("WebView is loading (progress : $progress%)");
                      },
                      onPageStarted: (String url) {
                        print('Page started loading: $url');
                        setState(() {
                          isApiCalling = true;
                        });
                      },
                      onPageFinished: (String url) {
                        print('Page finished loading: $url');

                        Future.delayed(const Duration(milliseconds: 500), () {
                          setState(() {
                            isApiCalling = false;
                          });
                        });
                      },
                    ),
                  )),
            ],
          ),
        ),
      )),
    );
  }
}
