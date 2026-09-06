import Flutter
import GoogleMaps
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let CHANNEL = "default_platform_channel"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey(Bundle.main.infoDictionary?["GOOGLE_MAPS_IOS_API_KEY"] as? String ?? "")

    // Required by flutter_local_notifications to present/handle reminders in the foreground.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    let channel = FlutterMethodChannel(
      name: CHANNEL,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    // Each service owns matching its own method names and extracting its own
    // arguments via `handle(_:result:)` — this just chains them in order and
    // falls back to FlutterMethodNotImplemented if none claim the call.
    let services: [(FlutterMethodCall, @escaping FlutterResult) -> Bool] = [
      AppLogoService.handle,
      ICloudBackupService.handle,
    ]

    channel.setMethodCallHandler { call, result in
      for handle in services where handle(call, result) {
        return
      }
      result(FlutterMethodNotImplemented)
    }

    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
