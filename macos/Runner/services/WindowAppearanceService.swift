import Cocoa
import FlutterMacOS

/// Native side of `WindowAppearanceService` (Dart): the window's title bar and buttons follow the app's light/dark
/// theme rather than the system's. Only the window frame's appearance changes -- Flutter draws its own content.
///
/// The window's look itself (transparent title bar, hidden title, full-size content) is set in `MainMenu.xib`, never
/// at runtime: changing it before the first frame resizes the window while Flutter can't draw yet, which makes
/// Impeller fail on launch ("The texture and its descriptor disagree about its size").
enum WindowAppearanceService {
  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) -> Bool {
    switch call.method {
    case "WindowAppearanceService.setDark":
      let dark = (call.arguments as? [String: Any])?["dark"] as? Bool ?? false
      setDark(dark)
      result(nil)
      return true
    default:
      return false
    }
  }

  private static func setDark(_ dark: Bool) {
    for window in NSApp.windows where window is MainFlutterWindow {
      window.contentView?.superview?.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
      window.invalidateShadow()
    }
  }
}
