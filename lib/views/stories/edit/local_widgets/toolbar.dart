part of '../edit_story_view.dart';

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.pages,
    required this.preferences,
    required this.onThemeChanged,
    required this.backgroundColor,
  });

  final List<StoryPageObject> pages;
  final StoryPreferencesDbModel preferences;
  final void Function(StoryPreferencesDbModel) onThemeChanged;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final page in pages) ...[
          SpFocusNodeBuilder(
            focusNode: page.titleFocusNode,
            child: Container(
              color: backgroundColor,
              padding: EdgeInsets.only(
                left: MediaQuery.of(context).padding.left,
                right: MediaQuery.of(context).padding.right,
                bottom: MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: _TitleToolbar(
                preferences: preferences,
                onThemeChanged: (preferences) => onThemeChanged(preferences),
              ),
            ),
            builder: (context, titleFocused, child) {
              return Visibility(
                visible: titleFocused,
                child: child!,
              );
            },
          ),
          SpFocusNodeBuilder(
            focusNode: page.bodyFocusNode,
            child: Container(
              color: backgroundColor,
              padding: EdgeInsets.only(
                left: MediaQuery.of(context).padding.left,
                right: MediaQuery.of(context).padding.right,
                bottom: MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: _QuillToolbar(
                controller: page.bodyController,
                context: context,
                backgroundColor: backgroundColor,
              ),
            ),
            builder: (context, bodyFocused, child) {
              return Visibility(
                visible: bodyFocused,
                child: child!,
              );
            },
          ),
        ],
      ],
    );
  }
}
