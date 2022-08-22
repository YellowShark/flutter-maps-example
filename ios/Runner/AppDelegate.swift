import UIKit
import Flutter
import GoogleMaps
import YandexMapsMobile

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBLR3iEOULZSNtuNNhhGLIpTASvwxvVLg4")
    YMKMapKit.setLocale("ru_RU") // Your preferred language. Not required, defaults to system language
    YMKMapKit.setApiKey("acd191bb-dafb-485f-b131-b60ef3913a41") // Your generated API key
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
