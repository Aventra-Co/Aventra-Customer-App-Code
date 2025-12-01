import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'controller/app_color.dart';
import 'controller/app_connectivity.dart';
import 'controller/app_constant.dart';
import 'controller/app_font.dart';
import 'controller/one_signal_service.dart';
import 'controller/route_observer.dart';
import 'controller/routes.dart';
import 'view/other_screen/splash_screen.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initOneSignal(AppConstant.oneSignalAppId);
  await OneSignalService.initOneSignal();

  runApp(const MyApp());

  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: AppConstant.apiKey,
          appId: AppConstant.appId,
          messagingSenderId: AppConstant.messagingSenderId,
          projectId: AppConstant.projectId));
}

Future<void> initOneSignal(oneSignalAppId) async {
  print("initOneSignal ------ ");
  var settings;
  if (AppConstant.deviceType == "android") {
    settings = {
      OSiOSSettings.autoPrompt: false,
      OSiOSSettings.inAppLaunchUrl: false
    };
  } else {
    settings = {
      OSiOSSettings.autoPrompt: true,
      OSiOSSettings.inAppLaunchUrl: true
    };
  }
  await OneSignal.shared.setAppId(AppConstant.oneSignalAppId);

  print("Prompting for Permission");
  OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
    print("Accepted permission: $accepted");
  });

  final status = await OneSignal.shared.getDeviceState();
  if (status != null) {
    print("main dart line 41");
    var tokenId = status.userId;
    if (tokenId != null) {
      print("player Id $tokenId");
      print(tokenId);
      AppConstant.playerID = tokenId;
      print("playerID : ${AppConstant.playerID}");
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => ConnectionProvider()..initialize()),
      ],
      child: MaterialApp(
        navigatorObservers: [routeObserver],
        title: 'Aventra',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColor.themeColor),
          fontFamily: AppFont.fontFamily,
        ),
        navigatorKey: navigatorKey,
        routes: routes,
        home: AppInitializer(),
      ),
    );
  }
}

// Wrapper widget to handle app initialization
class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Mark app as initialized after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OneSignalService.setAppInitialized(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Splash(); // Your splash screen will handle the rest
  }
}
