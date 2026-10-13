import 'package:flutter/material.dart';
import 'package:storypad/core/objects/story_page_object.dart';
import 'package:storypad/widgets/rich_editor/sp_editor_toolbar.dart';

/// The formatting toolbar of whichever page is being edited. One toolbar for the whole page: the page title is the
/// page's leading heading, formatted like any other line.
class SpPagesToolbar extends StatefulWidget {
  const SpPagesToolbar({
    super.key,
    required this.pages,
    required this.backgroundColor,
    required this.managingPage,
  });

  final bool managingPage;
  final List<StoryPageObject> pages;
  final Color? backgroundColor;

  @override
  State<SpPagesToolbar> createState() => SpPagesToolbarState();
}

class SpPagesToolbarState extends State<SpPagesToolbar> {
  Map<int, void Function()> bodyFocusListenters = {};

  int? bodyFocusedIndex;

  @override
  void initState() {
    super.initState();
    setupListeners();
  }

  void setupListeners() {
    for (int index = 0; index < widget.pages.length; index++) {
      bodyFocusListenters[index] = () => bodyFocusListener(index);
      widget.pages[index].bodyFocusNode.addListener(bodyFocusListenters[index]!);
    }
  }

  @override
  void didUpdateWidget(covariant SpPagesToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    clearPreviousListeners(oldWidget.pages);
    setupListeners();
  }

  void clearPreviousListeners(List<StoryPageObject> pages) {
    for (int index = 0; index < pages.length; index++) {
      if (bodyFocusListenters[index] != null) {
        pages[index].bodyFocusNode.removeListener(bodyFocusListenters[index]!);
      }
    }

    bodyFocusListenters.clear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    clearPreviousListeners(widget.pages);
    setupListeners();
  }

  void bodyFocusListener(int index) {
    if (index >= widget.pages.length) return;
    if (widget.pages[index].bodyFocusNode.hasFocus) bodyFocusedIndex = index;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    clearPreviousListeners(widget.pages);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !widget.managingPage,
      child: Stack(
        fit: StackFit.loose,
        children: List.generate(
          widget.pages.length,
          (index) {
            return Visibility(
              visible: index == bodyFocusedIndex,
              child: _AboveKeyboard(
                color: widget.backgroundColor,
                child: SpEditorToolbar(controller: widget.pages[index].bodyController),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Sits [child] above the keyboard (and the home indicator without one). The keyboard's animation changes that space on
/// every frame: read here alone, it rebuilds this padding only -- not the toolbar, whose ~30 buttons are a frame's work.
class _AboveKeyboard extends StatelessWidget {
  const _AboveKeyboard({required this.color, required this.child});

  final Color? color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + MediaQuery.viewInsetsOf(context).bottom),
      child: child,
    );
  }
}
