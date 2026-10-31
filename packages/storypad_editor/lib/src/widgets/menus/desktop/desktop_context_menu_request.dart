import 'package:flutter/material.dart';

import '../story_context_menu_action.dart';

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
  /// standard items -- [leadingActions] before them; choosing one calls its `onPressed` (return `null` from the handler).
  final List<StoryContextMenuAction> extraActions;

  /// The extra items that come before the standard ones: read-only, the [StoryContextMenuAction.leading] ones.
  List<StoryContextMenuAction> get leadingActions => [
    for (final action in extraActions)
      if (readOnly && action.leading) action,
  ];

  /// The extra items that come after the standard ones.
  List<StoryContextMenuAction> get trailingActions => [
    for (final action in extraActions)
      if (!(readOnly && action.leading)) action,
  ];
}
