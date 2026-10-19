import 'package:flutter/foundation.dart';

/// An extra item for the editor's selection menus, after the platform's own (cut/copy/paste/…):
///
/// - the Android floating toolbar,
/// - the iOS system context menu (iOS 16+; earlier versions keep the plain Flutter toolbar),
/// - the desktop right-click menu (native on macOS, Flutter-painted elsewhere; a custom `desktopContextMenu` gets them
///   in its request).
///
/// Read-only documents get the package's own menus: an Android toolbar, Flutter's iOS-style toolbar (iOS shows its
/// system menu for editable text only), and the desktop right-click menu. [whenEditing] and [whenReadOnly] choose
/// where an item shows.
@immutable
final class StoryContextMenuAction {
  const StoryContextMenuAction({
    required this.label,
    required this.onPressed,
    this.whenEditing = true,
    this.whenReadOnly = false,
    this.needsSelection = true,
  });

  final String label;
  final VoidCallback onPressed;

  /// Whether it's offered while the document is editable.
  final bool whenEditing;

  /// Whether it's offered while the document is read-only.
  final bool whenReadOnly;

  /// Whether it's only offered with some text selected (not just a caret).
  final bool needsSelection;

  /// Whether to offer it in the given state.
  bool isShown({required bool readOnly, required bool hasSelection}) =>
      (readOnly ? whenReadOnly : whenEditing) && (hasSelection || !needsSelection);
}
