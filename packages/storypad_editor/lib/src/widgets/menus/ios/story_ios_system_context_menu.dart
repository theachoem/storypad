import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:follow_the_leader/follow_the_leader.dart';
import 'package:super_editor/super_editor.dart';
import '../story_context_menu_action.dart';

/// iOS's own context menu (iOS 16+) over the editor's selection, with the standard items plus the app's
/// [extraActions]. super_editor's equivalent (`IOSSystemContextMenu`) can only show the standard items.
///
/// Only for an editable document: iOS shows its system menu for editable text only.
class StoryIosSystemContextMenu extends StatefulWidget {
  const StoryIosSystemContextMenu({
    super.key,
    required this.leaderLink,
    required this.selection,
    required this.extraActions,
  });

  /// Where the selection is on screen.
  final LeaderLink leaderLink;

  final ValueListenable<DocumentSelection?> selection;
  final List<StoryContextMenuAction> extraActions;

  /// The items for a selection: what `EditableText` offers on iOS, then the shown [extraActions].
  static List<IOSSystemContextMenuItemData> itemsFor({
    required WidgetsLocalizations localizations,
    required bool hasSelection,
    required List<StoryContextMenuAction> extraActions,
  }) {
    return [
      if (hasSelection) const IOSSystemContextMenuItemDataCut(),
      if (hasSelection) const IOSSystemContextMenuItemDataCopy(),
      const IOSSystemContextMenuItemDataPaste(),
      const IOSSystemContextMenuItemDataSelectAll(),
      if (hasSelection) IOSSystemContextMenuItemDataLookUp(title: localizations.lookUpButtonLabel),
      if (hasSelection) IOSSystemContextMenuItemDataSearchWeb(title: localizations.searchWebButtonLabel),
      if (hasSelection) IOSSystemContextMenuItemDataShare(title: localizations.shareButtonLabel),
      for (final action in extraActions)
        if (action.isShown(readOnly: false, hasSelection: hasSelection))
          IOSSystemContextMenuItemDataCustom(title: action.label, onPressed: action.onPressed),
    ];
  }

  @override
  State<StoryIosSystemContextMenu> createState() => _StoryIosSystemContextMenuState();
}

class _StoryIosSystemContextMenuState extends State<StoryIosSystemContextMenu> {
  final _controller = SystemContextMenuController();

  @override
  void initState() {
    super.initState();
    widget.leaderLink.addListener(_onLeaderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  @override
  void didUpdateWidget(StoryIosSystemContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.leaderLink != oldWidget.leaderLink) {
      oldWidget.leaderLink.removeListener(_onLeaderChanged);
      widget.leaderLink.addListener(_onLeaderChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) => _show());
    }
  }

  @override
  void dispose() {
    widget.leaderLink.removeListener(_onLeaderChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onLeaderChanged() {
    if (widget.leaderLink.offset == null || widget.leaderLink.leaderSize == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  void _show() {
    final offset = widget.leaderLink.offset;
    final size = widget.leaderLink.leaderSize;
    if (!mounted || offset == null || size == null) return;

    final selection = widget.selection.value;
    _controller.showWithItems(
      offset & size,
      StoryIosSystemContextMenu.itemsFor(
        localizations: WidgetsLocalizations.of(context),
        hasSelection: selection != null && !selection.isCollapsed,
        extraActions: widget.extraActions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
