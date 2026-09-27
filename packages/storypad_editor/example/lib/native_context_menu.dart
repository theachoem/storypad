import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:storypad_editor/storypad_editor.dart';

/// The example's desktop right-click menu: a real `NSMenu` on macOS (including the OS Services submenu, fed the
/// selected text), through the platform channel implemented in `macos/Runner/MainFlutterWindow.swift`; the package's
/// Flutter-painted menu everywhere else, or if the channel isn't there (e.g. in tests).
///
/// Pass it to `RawEditor.desktopContextMenu` / `MarkdownEditor.desktopContextMenu`.
Future<DesktopContextMenuAction?> showDesktopContextMenu(DesktopContextMenuRequest request) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) return showDefaultDesktopContextMenu(request);

  try {
    final id = await _channel.invokeMethod<String>('show', {
      'x': request.globalPosition.dx,
      'y': request.globalPosition.dy,
      'selectedText': ?(request.hasSelection ? request.selectedText : null),
      'items': [
        _item(DesktopContextMenuAction.cut, 'Cut', enabled: request.hasSelection && !request.readOnly),
        _item(DesktopContextMenuAction.copy, 'Copy', enabled: request.hasSelection),
        _item(DesktopContextMenuAction.paste, 'Paste', enabled: !request.readOnly),
        const {'divider': true},
        _item(DesktopContextMenuAction.selectAll, 'Select All'),
        const {'divider': true},
        const {'servicesMenu': true},
      ],
    });
    return DesktopContextMenuAction.values.where((action) => action.name == id).firstOrNull;
  } on MissingPluginException {
    return showDefaultDesktopContextMenu(request);
  }
}

const _channel = MethodChannel('storypad_editor_example/native_context_menu');

Map<String, Object> _item(DesktopContextMenuAction action, String title, {bool enabled = true}) => {
  'id': action.name,
  'title': title,
  'enabled': enabled,
};
