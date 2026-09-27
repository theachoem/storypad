import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var nativeContextMenuHandler: NativeContextMenuHandler?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    nativeContextMenuHandler = NativeContextMenuHandler(viewController: flutterViewController)

    super.awakeFromNib()
  }
}

/// Bridges the `"storypad_editor_example/native_context_menu"` method channel to a
/// real AppKit `NSMenu`, so Dart code can show a genuinely native (not
/// Flutter-painted) right-click menu on macOS — including the OS-managed
/// Services submenu (see [SelectionServicesRequestor]).
///
/// This is plain host-app code, not a Flutter plugin (storypad_editor ships no native code): an app wires it up here
/// and passes its Dart half (`showDesktopContextMenu` in `lib/native_context_menu.dart`) to
/// `RawEditor.desktopContextMenu`. It lives in this file so it needs no Xcode project changes.
final class NativeContextMenuHandler: NSObject {
  private static let channelName = "storypad_editor_example/native_context_menu"

  private let viewController: FlutterViewController
  private let servicesRequestor = SelectionServicesRequestor()
  // An `NSMenu` can only ever be the submenu of one menu item at a time — the same
  // way an `NSView` can only have one superview. `NSApp.servicesMenu` is already
  // the submenu of the app's own menu-bar "Services" item (wired up in
  // MainMenu.xib), so it can't *also* be handed to a second, contextual menu item
  // simultaneously; attempting that crashes with an NSInternalInconsistencyException
  // out of `-[NSMenuItem setSubmenu:]`. This is our own, otherwise-unused menu
  // instead, which we temporarily install as `NSApp.servicesMenu` (see showMenu)
  // so AppKit populates *it* instead, for the life of one popup.
  private let temporaryServicesMenu = NSMenu(title: "Services")
  private var selectionForOpenMenu: String?

  init(viewController: FlutterViewController) {
    self.viewController = viewController
    super.init()

    // Tells the OS "this app can hand plain text to a Service" so that
    // text-accepting services (Search With Google, Add to Notes, etc.) show up
    // as enabled entries in the Services submenu. We never *accept* text back
    // from a service, so returnTypes is empty.
    NSApp.registerServicesMenuSendTypes([.string], returnTypes: [])

    let channel = FlutterMethodChannel(
      name: NativeContextMenuHandler.channelName,
      binaryMessenger: viewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
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

    result(showMenu(items: items, selectedText: args["selectedText"] as? String, atFlutterLocalX: x, y: y))
  }

  /// Builds and pops up a real `NSMenu`, blocking (via AppKit's own menu tracking
  /// loop) until the user picks an item or dismisses the menu.
  ///
  /// Returns the `id` of the selected item, or `nil` if nothing was picked
  /// (including when a Services entry handled the pick itself).
  private func showMenu(items: [[String: Any]], selectedText: String?, atFlutterLocalX x: Double, y: Double) -> String? {
    let menu = NSMenu()
    menu.autoenablesItems = false

    for itemArgs in items {
      if (itemArgs["divider"] as? Bool) == true {
        menu.addItem(.separator())
        continue
      }

      if (itemArgs["servicesMenu"] as? Bool) == true {
        let servicesItem = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        servicesItem.submenu = temporaryServicesMenu
        menu.addItem(servicesItem)
        continue
      }

      guard
        let id = itemArgs["id"] as? String,
        let title = itemArgs["title"] as? String
      else {
        continue
      }

      let menuItem = NSMenuItem(title: title, action: #selector(handleSelection(_:)), keyEquivalent: "")
      menuItem.target = self
      menuItem.isEnabled = (itemArgs["enabled"] as? Bool) ?? true
      menuItem.representedObject = id
      menu.addItem(menuItem)
    }

    selectionForOpenMenu = nil

    let view = viewController.view
    // Flutter's root view uses a flipped (top-left origin) coordinate system that
    // matches Flutter's own conventions, so Flutter's "global position" can be used
    // directly as a point in this view, with no manual axis flip needed. Guard on
    // `isFlipped` anyway so this keeps working if that engine behavior ever changes.
    let location = view.isFlipped ? NSPoint(x: x, y: y) : NSPoint(x: x, y: view.bounds.height - y)

    // The Services submenu is filled in lazily by AppKit — based on whatever
    // `NSApp.servicesMenu` currently points at, and whatever the *current first
    // responder* can offer (see SelectionServicesRequestor) — right as the user
    // opens it. Neither of those is naturally ours (our Flutter text is never a
    // real first responder, and the app's real `servicesMenu` belongs to the menu
    // bar), so we swap both in for the life of this popup only, then put
    // everything back exactly as it was.
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

/// Stands in for the current SuperEditor selection when the OS's Services menu
/// asks "what's selected right now?". This is the same `NSServicesMenuRequestor`
/// protocol every native `NSTextView` implements to power its own Services
/// submenu; we implement it directly since our text lives in Flutter, not in a
/// real AppKit text view.
///
/// It only ever *provides* text to a service (a "Send" type); it doesn't accept
/// text back (no "Return" type), so services that need to write into the
/// document (e.g. paste-style services) won't offer themselves here — cut,
/// copy, and paste already cover that through the normal menu items.
final class SelectionServicesRequestor: NSResponder, NSServicesMenuRequestor {
  var selectedPlainText: String?

  override var acceptsFirstResponder: Bool { true }

  override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?)
    -> Any?
  {
    guard returnType == nil, sendType == .string, selectedPlainText != nil else {
      return super.validRequestor(forSendType: sendType, returnType: returnType)
    }
    return self
  }

  func writeSelection(to pboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) -> Bool {
    guard let text = selectedPlainText, types.contains(.string) else {
      return false
    }
    pboard.declareTypes([.string], owner: nil)
    return pboard.setString(text, forType: .string)
  }
}
