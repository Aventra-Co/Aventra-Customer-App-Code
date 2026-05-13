import 'dart:async';
import 'dart:ui';
import 'package:boatapp/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
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

Future<void> initFirebaseAuth() async {
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
      debugPrint('✅ Firebase Auth: signed in anonymously');
    }
    else {
      debugPrint('✅ Firebase Auth: already signed in');
    }
  }
  catch (e) {
    debugPrint('❌ Firebase Auth failed: $e');
  }
}

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    runApp(const MyApp());
    unawaited(initFirebaseAuth());
    unawaited(OneSignalService.initOneSignal());
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}


Future<void> initOneSignal() async {
  OneSignal.initialize(AppConstant.oneSignalAppId);

  await OneSignal.Notifications.requestPermission(true);

  final OneSignalPushSubscription pushSubscription = OneSignal.User.pushSubscription;
  final String? tokenId = pushSubscription.id;
  if (tokenId != null) AppConstant.playerID = tokenId;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData appTheme = ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColor.themeColor,
        brightness: Brightness.light,
      ),
      fontFamily: AppFont.fontFamily,
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: Colors.white,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.themeColor,
        ),
      ),
    );

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
        theme: appTheme,
        darkTheme: appTheme,
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

class _AppInitializerState extends State<AppInitializer> with WidgetsBindingObserver {

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
