import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import 'android_toolbar.dart' show plainTextInSelection;
import 'context_menu_action.dart';

/// An action from the desktop right-click menu.
enum DesktopContextMenuAction { cut, copy, paste, selectAll }

/// What a desktop context menu needs to know to show itself.
final class DesktopContextMenuRequest {
  const DesktopContextMenuRequest({
    required this.context,
    required this.globalPosition,
    required this.hasSelection,
    required this.selectedText,
    this.readOnly = false,
    this.extraActions = const [],
  });

  final BuildContext context;

  /// Where the user right-clicked, in global coordinates.
  final Offset globalPosition;

  /// Whether some text is selected (so Cut/Copy apply).
  final bool hasSelection;

  /// The selected text as plain text (empty without a selection) -- e.g. for a native menu's Services submenu.
  final String selectedText;

  /// Whether the editor is read-only, so Cut and Paste don't apply.
  final bool readOnly;

  /// The app's extra items for this state (`RawEditor.contextMenuActions`, already filtered). Show them after the
  /// standard items; choosing one calls its `onPressed` (return `null` from the handler).
  final List<StoryContextMenuAction> extraActions;
}

/// Shows a desktop context menu and returns the chosen action, or `null` if dismissed. Pass one to
/// `RawEditor.desktopContextMenu` to replace the default menu.
typedef DesktopContextMenuHandler = Future<DesktopContextMenuAction?> Function(DesktopContextMenuRequest request);

/// The default desktop context menu: the platform's own where the package has one -- a native `NSMenu` on macOS (with
/// the Services submenu, fed the selected text; `macos/`) -- else [showMaterialDesktopContextMenu]. A native menu
/// everywhere is the goal; Windows and Linux are still Flutter-painted.
Future<DesktopContextMenuAction?> showDefaultDesktopContextMenu(DesktopContextMenuRequest request) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) return showMaterialDesktopContextMenu(request);
  try {
    return await showNativeMacosContextMenu(request);
  } on MissingPluginException {
    // No native side (e.g. in tests): the Flutter-painted menu.
    return showMaterialDesktopContextMenu(request);
  }
}

const _macosChannel = MethodChannel('storypad_editor/context_menu');

/// The macOS `NSMenu`: Cut, Copy, Paste, Select All (with their usual shortcuts shown), the app's extra items, then
/// Services. Throws a [MissingPluginException] without the package's macOS side.
@visibleForTesting
Future<DesktopContextMenuAction?> showNativeMacosContextMenu(DesktopContextMenuRequest request) async {
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

const _extraPrefix = 'extra:';

/// A Flutter-painted Cut/Copy/Paste/Select All menu, with the app's extra items -- the default where there's no
/// native menu.
Future<DesktopContextMenuAction?> showMaterialDesktopContextMenu(DesktopContextMenuRequest request) {
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

/// Adds a right-click context menu around [child], for desktop/web, where super_editor shows no selection menu of
/// its own. Right-clicking outside the selection first moves the caret there, like native text editors.
class DesktopContextMenuRegion extends StatelessWidget {
  const DesktopContextMenuRegion({
    super.key,
    required this.document,
    required this.composer,
    required this.editorOps,
    required this.documentLayoutResolver,
    required this.showMenu,
    required this.child,
    this.readOnly = false,
    this.extraActions = const [],
  });

  /// In read-only mode, Cut and Paste are ignored (and the default menu disables them).
  final bool readOnly;

  /// The app's extra items (`RawEditor.contextMenuActions`); only those shown in the current state are offered.
  final List<StoryContextMenuAction> extraActions;

  final Document document;
  final DocumentComposer composer;
  final CommonEditorOperations editorOps;
  final DocumentLayout Function() documentLayoutResolver;
  final DesktopContextMenuHandler showMenu;
  final Widget child;

  Future<void> _handleSecondaryTapUp(BuildContext context, TapUpDetails details) async {
    final layout = documentLayoutResolver();
    final position = layout.getDocumentPositionNearestToOffset(
      layout.getDocumentOffsetFromAncestorOffset(details.globalPosition),
    );
    if (position == null) return;

    final selection = composer.selection;
    if (selection == null || !selection.containsPosition(document, position)) {
      editorOps.insertCaretAtPosition(position);
    }

    final current = composer.selection;
    final hasSelection = current != null && !current.isCollapsed;
    final action = await showMenu(
      DesktopContextMenuRequest(
        context: context,
        globalPosition: details.globalPosition,
        hasSelection: hasSelection,
        selectedText: hasSelection ? plainTextInSelection(document: document, selection: current) : '',
        readOnly: readOnly,
        extraActions: [
          for (final action in extraActions)
            if (action.isShown(readOnly: readOnly, hasSelection: hasSelection)) action,
        ],
      ),
    );

    switch (action) {
      case DesktopContextMenuAction.cut when !readOnly:
        editorOps.cut();
      case DesktopContextMenuAction.copy:
        editorOps.copy();
      case DesktopContextMenuAction.paste when !readOnly:
        editorOps.paste();
      case DesktopContextMenuAction.selectAll:
        editorOps.selectAll();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onSecondaryTapUp: (details) => _handleSecondaryTapUp(context, details), child: child);
  }
}
