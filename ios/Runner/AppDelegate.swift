import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyCY1_Ncz7dVOoaddm4ZXGqoAdG7cd8_exE")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
