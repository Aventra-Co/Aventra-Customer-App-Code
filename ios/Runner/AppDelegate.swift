import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyCY1_Ncz7dVOoaddm4ZXGqoAdG7cd8_exE")

    if let controller = window?.rootViewController as? FlutterViewController {
      let badgeChannel = FlutterMethodChannel(
        name: "com.aventra.app/badge",
        binaryMessenger: controller.binaryMessenger
      )

      badgeChannel.setMethodCallHandler { call, result in
        if call.method == "setBadge" {
          let args = call.arguments as? [String: Any]
          let count = args?["count"] as? Int ?? 0
          DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = max(0, count)
            result(nil)
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
