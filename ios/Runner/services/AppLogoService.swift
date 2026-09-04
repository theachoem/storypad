import Flutter
import UIKit

class AppLogoService {
  /// Routes a `default_platform_channel` call to this service if it's one of
  /// ours, returning whether it was handled — see `AppDelegate.swift`, which
  /// chains every service's `handle` rather than switching on method names
  /// itself.
  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) -> Bool {
    switch call.method {
    case "AppLogoService.set":
      let arguments = call.arguments as? [String: Any]
      let xcodeLogoName = arguments?["xcodeLogoName"] as? String
      set(xcodeLogoName: xcodeLogoName, result: result)
      return true
    default:
      return false
    }
  }

  static func set(xcodeLogoName: String?, result: @escaping FlutterResult) {
    guard UIApplication.shared.supportsAlternateIcons else {
      result(
        FlutterError(
          code: "UNSUPPORTED",
          message: "Alternate icons are not supported on this device",
          details: nil
        ))
      return
    }

    let iconName: String? = xcodeLogoName

    UIApplication.shared.setAlternateIconName(iconName) { error in
      if let error = error {
        let nsError = error as NSError
        let errorMsg =
          "Failed to set alternate icon: \(error.localizedDescription) (xcodeLogoName: \(xcodeLogoName)) (code: \(nsError.code))"
        result(
          FlutterError(
            code: "FAILED",
            message: errorMsg,
            details: nil
          ))
      } else {
        result(nil)
      }
    }
  }
}
