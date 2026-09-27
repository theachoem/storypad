import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:storypad_editor/storypad_editor.dart';

import 'toolbar_buttons.dart';

/// The editor with a formatting toolbar, the way an app composes them: a toolbar always above the editor on
/// desktop, and one above the keyboard on touch, shown while editing.
class EditorWithToolbar extends StatelessWidget {
  const EditorWithToolbar({super.key, required this.controller, required this.editor});

  final StoryEditorController controller;
  final Widget editor;

  static bool get _isDesktop =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context) {
    final desktop = _isDesktop;
    return Column(
      children: [
        if (desktop) ...[DesktopEditorToolbar(controller: controller), const Divider(height: 1)],
        Expanded(child: editor),
        if (!desktop) MobileEditorToolbar(controller: controller),
      ],
    );
  }
}

/// Desktop: always visible.
class DesktopEditorToolbar extends StatelessWidget {
  const DesktopEditorToolbar({super.key, required this.controller});

  final StoryEditorController controller;

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: controller.tapRegionGroupId,
      child: Material(
        elevation: 1,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: buildToolbarButtons(context, controller)),
          ),
        ),
      ),
    );
  }
}

/// Touch: shown only while editing (the editor has focus, or a toolbar popup holds its selection), in the editor's
/// tap region group, so tapping it doesn't count as tapping outside the editor.
class MobileEditorToolbar extends StatelessWidget {
  const MobileEditorToolbar({super.key, required this.controller});

  final StoryEditorController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isToolbarActive,
      builder: (context, active, _) {
        if (!active) return const SizedBox.shrink();
        return TapRegion(
          groupId: controller.tapRegionGroupId,
          child: Material(
            elevation: 4,
            child: SafeArea(
              top: false,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: buildToolbarButtons(context, controller)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
