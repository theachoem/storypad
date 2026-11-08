import 'package:flutter/cupertino.dart';
import 'package:follow_the_leader/follow_the_leader.dart';
import 'package:super_editor/super_editor.dart';

import '../reader_menu.dart';
import '../story_context_menu_action.dart';

/// The iOS read-only menu: Flutter's iOS-style toolbar at the selection ([focalPoint]).
class StoryIosReaderToolbar extends StatelessWidget {
  const StoryIosReaderToolbar({
    super.key,
    required this.focalPoint,
    required this.menu,
    required this.controlsController,
  });

  final LeaderLink focalPoint;
  final ReaderMenu menu;
  final SuperReaderIosControlsController controlsController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([focalPoint, menu.composer.selectionNotifier]),
      builder: (context, _) {
        final offset = focalPoint.offset;
        final size = focalPoint.leaderSize;
        if (offset == null || size == null) return const SizedBox.shrink();

        final localizations = CupertinoLocalizations.of(context);
        (String, VoidCallback) extra(StoryContextMenuAction action) => (
          action.label,
          () {
            controlsController.hideToolbar();
            action.onPressed();
          },
        );
        final buttons = <(String, VoidCallback)>[
          for (final action in menu.leadingActions) extra(action),
          if (menu.hasSelection)
            (
              localizations.copyButtonLabel,
              () {
                menu.copy();
                controlsController.hideToolbar();
              },
            ),
          (localizations.selectAllButtonLabel, menu.selectAll),
          for (final action in menu.trailingActions) extra(action),
        ];

        final rect = offset & size;
        return CupertinoTextSelectionToolbar(
          anchorAbove: rect.topCenter,
          anchorBelow: rect.bottomCenter,
          children: [
            for (final (index, (label, onPressed)) in buttons.indexed)
              CupertinoTextSelectionToolbarButton.text(key: ValueKey(index), text: label, onPressed: onPressed),
          ],
        );
      },
    );
  }
}
