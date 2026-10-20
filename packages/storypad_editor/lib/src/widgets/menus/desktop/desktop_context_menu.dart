import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'desktop_context_menu_request.dart';
import 'desktop_context_menu_action.dart';

/// The editor's right-click menu on desktop: native on macOS, Material elsewhere.
class DesktopContextMenu {
  const DesktopContextMenu._();

  /// The default desktop context menu: the platform's own where the package has one -- a native `NSMenu` on macOS (with
  /// the Services submenu, fed the selected text; `macos/`) -- else [DesktopContextMenu.showMaterial]. A native menu
  /// everywhere is the goal; Windows and Linux are still Flutter-painted.
  static Future<DesktopContextMenuAction?> showDefault(DesktopContextMenuRequest request) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) return DesktopContextMenu.showMaterial(request);
    try {
      return await DesktopContextMenu.showNativeMacos(request);
    } on MissingPluginException {
      // No native side (e.g. in tests): the Flutter-painted menu.
      return DesktopContextMenu.showMaterial(request);
    }
  }

  static const _macosChannel = MethodChannel('storypad_editor/context_menu');

  /// The macOS `NSMenu`: Cut, Copy, Paste, Select All (with their usual shortcuts shown), the app's extra items, then
  /// Services. Throws a [MissingPluginException] without the package's macOS side.
  @visibleForTesting
  static Future<DesktopContextMenuAction?> showNativeMacos(DesktopContextMenuRequest request) async {
    final localizations = MaterialLocalizations.of(request.context);
    Map<String, Object> item(String id, String title, {bool enabled = true, String? keyEquivalent}) => {
      'id': id,
      'title': title,
      'enabled': enabled,
      'keyEquivalent': ?keyEquivalent,
    };

    final id = await _macosChannel.invokeMethod<String>('show', {
      'x': request.globalPosition.dx,
      'y': request.globalPosition.dy,
      'selectedText': ?(request.hasSelection ? request.selectedText : null),
      'items': [
        item(
          DesktopContextMenuAction.cut.name,
          localizations.cutButtonLabel,
          enabled: request.hasSelection && !request.readOnly,
          keyEquivalent: 'x',
        ),
        item(
          DesktopContextMenuAction.copy.name,
          localizations.copyButtonLabel,
          enabled: request.hasSelection,
          keyEquivalent: 'c',
        ),
        item(
          DesktopContextMenuAction.paste.name,
          localizations.pasteButtonLabel,
          enabled: !request.readOnly,
          keyEquivalent: 'v',
        ),
        const {'divider': true},
        item(DesktopContextMenuAction.selectAll.name, localizations.selectAllButtonLabel, keyEquivalent: 'a'),
        if (request.extraActions.isNotEmpty) const {'divider': true},
        for (final (index, action) in request.extraActions.indexed) item('$_extraPrefix$index', action.label),
        const {'divider': true},
        const {'servicesMenu': true},
      ],
    });

    if (id == null) return null;
    if (id.startsWith(_extraPrefix)) {
      request.extraActions.elementAtOrNull(int.parse(id.substring(_extraPrefix.length)))?.onPressed();
      return null;
    }
    return DesktopContextMenuAction.values.asNameMap()[id];
  }

  static const _extraPrefix = 'extra:';

  /// A Flutter-painted Cut/Copy/Paste/Select All menu, with the app's extra items -- the default where there's no
  /// native menu.
  static Future<DesktopContextMenuAction?> showMaterial(DesktopContextMenuRequest request) {
    final overlay = Overlay.of(request.context).context.findRenderObject()! as RenderBox;
    final position = request.globalPosition;
    final localizations = MaterialLocalizations.of(request.context);
    return showMenu<DesktopContextMenuAction>(
      context: request.context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: [
        PopupMenuItem(
          value: DesktopContextMenuAction.cut,
          enabled: request.hasSelection && !request.readOnly,
          child: Text(localizations.cutButtonLabel),
        ),
        PopupMenuItem(
          value: DesktopContextMenuAction.copy,
          enabled: request.hasSelection,
          child: Text(localizations.copyButtonLabel),
        ),
        PopupMenuItem(
          value: DesktopContextMenuAction.paste,
          enabled: !request.readOnly,
          child: Text(localizations.pasteButtonLabel),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(value: DesktopContextMenuAction.selectAll, child: Text(localizations.selectAllButtonLabel)),
        if (request.extraActions.isNotEmpty) const PopupMenuDivider(),
        for (final action in request.extraActions) PopupMenuItem(onTap: action.onPressed, child: Text(action.label)),
      ],
    );
  }
}

/// Shows a desktop context menu and returns the chosen action, or `null` if dismissed. Pass one to
/// `RawEditor.desktopContextMenu` to replace the default menu.
typedef DesktopContextMenuHandler = Future<DesktopContextMenuAction?> Function(DesktopContextMenuRequest request);
