import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    setUpMethodChannel(messenger: flutterViewController.engine.binaryMessenger)
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  /// Mirrors `ios/Runner/AppDelegate.swift`'s `default_platform_channel` setup —
  /// each service owns matching its own method names and extracting its own
  /// arguments via `handle(_:result:)`; this just chains them in order and
  /// falls back to `FlutterMethodNotImplemented` if none claim the call.
  private func setUpMethodChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "default_platform_channel", binaryMessenger: messenger)

    let services: [(FlutterMethodCall, @escaping FlutterResult) -> Bool] = [
      ICloudBackupService.handle
    ]

    channel.setMethodCallHandler { call, result in
      for handle in services where handle(call, result) {
        return
      }
      result(FlutterMethodNotImplemented)
    }
  }
}
