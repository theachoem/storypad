import 'package:flutter/cupertino.dart';
import 'package:follow_the_leader/follow_the_leader.dart';
import 'package:super_editor/super_editor.dart';

import '../reader_menu.dart';

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
        final buttons = <(String, VoidCallback)>[
          if (menu.hasSelection)
            (
              localizations.copyButtonLabel,
              () {
                menu.copy();
                controlsController.hideToolbar();
              },
            ),
          (localizations.selectAllButtonLabel, menu.selectAll),
          for (final action in menu.shownExtraActions)
            (
              action.label,
              () {
                controlsController.hideToolbar();
                action.onPressed();
              },
            ),
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
