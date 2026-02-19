import Flutter
import UIKit

class AppLogoService {
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
