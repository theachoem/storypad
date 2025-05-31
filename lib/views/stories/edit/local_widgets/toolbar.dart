part of '../edit_story_view.dart';

class _Toolbar extends StatefulWidget {
  const _Toolbar({
    required this.pages,
    required this.preferences,
    required this.onThemeChanged,
    required this.backgroundColor,
    required this.managingPage,
  });

  final bool managingPage;
  final List<StoryPageObject> pages;
  final StoryPreferencesDbModel preferences;
  final void Function(StoryPreferencesDbModel) onThemeChanged;
  final Color? backgroundColor;

  @override
  State<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<_Toolbar> {
  Map<int, void Function()> titleFocusListenters = {};
  Map<int, void Function()> bodyFocusListenters = {};

  bool titleFocused = false;
  int? bodyFocusedIndex;

  @override
  void initState() {
    super.initState();
    setupListeners();
  }

  void setupListeners() {
    for (int index = 0; index < widget.pages.length; index++) {
      titleFocusListenters[index] = () => titleFocusListener(index);
      bodyFocusListenters[index] = () => bodyFocusListener(index);

      widget.pages[index].titleFocusNode.addListener(titleFocusListenters[index]!);
      widget.pages[index].bodyFocusNode.addListener(bodyFocusListenters[index]!);
    }
  }

  @override
  void didUpdateWidget(covariant _Toolbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    clearPreviousListeners();
    setupListeners();
  }

  void clearPreviousListeners() {
    for (int index = 0; index < widget.pages.length; index++) {
      if (titleFocusListenters[index] != null) {
        widget.pages[index].titleFocusNode.removeListener(titleFocusListenters[index]!);
      }
      if (bodyFocusListenters[index] != null) {
        widget.pages[index].bodyFocusNode.removeListener(bodyFocusListenters[index]!);
      }
    }

    titleFocusListenters.clear();
    bodyFocusListenters.clear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    clearPreviousListeners();
    setupListeners();
  }

  void titleFocusListener(int index) {
    if (widget.pages[index].titleFocusNode.hasFocus) {
      titleFocused = true;
    } else {
      bool everyBodyNoFocus = widget.pages.every((e) => !e.bodyFocusNode.hasFocus);
      if (everyBodyNoFocus && titleFocused) {
        titleFocused = true;
      } else {
        titleFocused = false;
      }
    }

    if (mounted) setState(() {});
  }

  void bodyFocusListener(int index) {
    if (widget.pages[index].bodyFocusNode.hasFocus) {
      bodyFocusedIndex = index;
      titleFocused = false;
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    clearPreviousListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !widget.managingPage,
      child: Stack(
        fit: StackFit.loose,
        children: [
          if (titleFocused) buildTitleToolbar(context),
          if (!titleFocused)
            ...List.generate(
              widget.pages.length,
              (index) {
                return Visibility(
                  visible: index == bodyFocusedIndex,
                  child: Container(
                    color: widget.backgroundColor,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: _QuillToolbar(
                      controller: widget.pages[index].bodyController,
                      context: context,
                      backgroundColor: widget.backgroundColor,
                    ),
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  Widget buildTitleToolbar(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).padding.left,
        right: MediaQuery.of(context).padding.right,
        bottom: MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _TitleToolbar(
        preferences: widget.preferences,
        onThemeChanged: (preferences) => widget.onThemeChanged(preferences),
      ),
    );
  }
}
