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
  if (AppConstant.deviceType == "android") {
  } else {}
  await OneSignal.shared.setAppId(AppConstant.oneSignalAppId);

  OneSignal.shared
      .promptUserForPushNotificationPermission()
      .then((accepted) {});

  final status = await OneSignal.shared.getDeviceState();
  if (status != null) {
    var tokenId = status.userId;
    if (tokenId != null) {
      AppConstant.playerID = tokenId;
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
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0), // ✅ modern approach
            ),
            child: child!,
          );
        },
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

class _AppInitializerState extends State<AppInitializer>
    with WidgetsBindingObserver {
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Mark app as initialized after the first frame_buildPromotionsSection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OneSignalService.setAppInitialized(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Splash();
  }
}
