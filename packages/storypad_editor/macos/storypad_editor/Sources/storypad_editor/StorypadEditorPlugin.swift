import Cocoa
import FlutterMacOS

/// storypad_editor's macOS side: the editor's right-click menu as a real AppKit `NSMenu`, through the
/// `storypad_editor/context_menu` method channel (Dart side: `DesktopContextMenu.showNativeMacos` in
/// `lib/src/widgets/menus/desktop/desktop_context_menu.dart`), including the OS Services submenu fed the selected text.
public final class StorypadEditorPlugin: NSObject, FlutterPlugin {
  private static let channelName = "storypad_editor/context_menu"

  private let registrar: FlutterPluginRegistrar
  private let servicesRequestor = SelectionServicesRequestor()
  // An `NSMenu` can only be the submenu of one menu item at a time, and `NSApp.servicesMenu` already is (the menu
  // bar's Services item): handing it to the context menu too crashes in `-[NSMenuItem setSubmenu:]`. This otherwise
  // unused menu is installed as `NSApp.servicesMenu` for the life of one popup instead, so AppKit fills it.
  private let temporaryServicesMenu = NSMenu(title: "Services")
  private var selectionForOpenMenu: String?

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    super.init()
    // Tells the OS this app can hand plain text to a Service, so text-accepting services (Search With Google, Add to
    // Notes, ...) are enabled in the Services submenu. Nothing is accepted back, so no return types.
    NSApp.registerServicesMenuSendTypes([.string], returnTypes: [])
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = StorypadEditorPlugin(registrar: registrar)
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "show" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard
      let args = call.arguments as? [String: Any],
      let items = args["items"] as? [[String: Any]],
      let x = args["x"] as? Double,
      let y = args["y"] as? Double
    else {
      result(FlutterError(code: "bad_args", message: "Expected items, x, and y", details: nil))
      return
    }
    guard let view = registrar.view else {
      result(FlutterError(code: "no_view", message: "No Flutter view to show the menu in", details: nil))
      return
    }
    result(
      showMenu(
        items: items, servicesTitle: args["servicesTitle"] as? String, selectedText: args["selectedText"] as? String,
        in: view, x: x, y: y))
  }

  /// Builds and pops up the menu, blocking (in AppKit's own menu tracking loop) until an item is picked or the menu
  /// is dismissed. Returns the picked item's `id`, or nil (also when a Services entry handled the pick itself).
  private func showMenu(
    items: [[String: Any]], servicesTitle: String?, selectedText: String?, in view: NSView, x: Double, y: Double
  ) -> String? {
    let menu = NSMenu()
    menu.autoenablesItems = false

    for itemArgs in items {
      if (itemArgs["divider"] as? Bool) == true {
        menu.addItem(.separator())
        continue
      }
      if (itemArgs["servicesMenu"] as? Bool) == true {
        let servicesItem = NSMenuItem(title: servicesTitle ?? "Services", action: nil, keyEquivalent: "")
        servicesItem.submenu = temporaryServicesMenu
        menu.addItem(servicesItem)
        continue
      }
      guard let id = itemArgs["id"] as? String, let title = itemArgs["title"] as? String else { continue }

      let menuItem = NSMenuItem(
        title: title, action: #selector(handleSelection(_:)), keyEquivalent: itemArgs["keyEquivalent"] as? String ?? "")
      menuItem.keyEquivalentModifierMask = .command
      menuItem.target = self
      menuItem.isEnabled = (itemArgs["enabled"] as? Bool) ?? true
      menuItem.representedObject = id
      menu.addItem(menuItem)
    }

    selectionForOpenMenu = nil

    // Flutter's view is flipped (top-left origin, as Flutter's own coordinates), so the position is used as is.
    let location = view.isFlipped ? NSPoint(x: x, y: y) : NSPoint(x: x, y: view.bounds.height - y)

    // AppKit fills the Services submenu lazily, from `NSApp.servicesMenu` and the current first responder. Neither is
    // naturally ours (Flutter text is never a real first responder; the real Services menu belongs to the menu bar),
    // so both are swapped in for this popup only, then put back.
    let window = view.window
    let previousResponder = window?.firstResponder
    let previousServicesMenu = NSApp.servicesMenu
    servicesRequestor.selectedPlainText = selectedText
    NSApp.servicesMenu = temporaryServicesMenu
    _ = window?.makeFirstResponder(servicesRequestor)

    menu.popUp(positioning: nil, at: location, in: view)

    _ = window?.makeFirstResponder(previousResponder)
    NSApp.servicesMenu = previousServicesMenu
    servicesRequestor.selectedPlainText = nil

    let selected = selectionForOpenMenu
    selectionForOpenMenu = nil
    return selected
  }

  @objc private func handleSelection(_ sender: NSMenuItem) {
    selectionForOpenMenu = sender.representedObject as? String
  }
}

/// Stands in for the editor's selection when the Services menu asks what's selected: the `NSServicesMenuRequestor`
/// protocol every `NSTextView` implements, since the text lives in Flutter. It only sends text to a service (no return
/// type), so services that would write into the document don't offer themselves; Cut/Copy/Paste cover that.
final class SelectionServicesRequestor: NSResponder, NSServicesMenuRequestor {
  var selectedPlainText: String?

  override var acceptsFirstResponder: Bool { true }

  override func validRequestor(
    forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?
  ) -> Any? {
    guard returnType == nil, sendType == .string, selectedPlainText != nil else {
      return super.validRequestor(forSendType: sendType, returnType: returnType)
    }
    return self
  }

  func writeSelection(to pboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) -> Bool {
    guard let text = selectedPlainText, types.contains(.string) else { return false }
    pboard.declareTypes([.string], owner: nil)
    return pboard.setString(text, forType: .string)
  }
}
