part of 'story_header.dart';

class _StoryHeaderTitleField extends StatelessWidget {
  const _StoryHeaderTitleField({
    required this.focusNode,
    required this.titleController,
    required this.draftContent,
    required this.readOnly,
    required this.story,
  });

  final FocusNode? focusNode;
  final TextEditingController? titleController;
  final StoryContentDbModel draftContent;
  final StoryDbModel story;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    TextStyle baseStyle = Theme.of(context).textTheme.titleLarge!;

    if (story.preferences.titleFontFamily != null) {
      baseStyle = GoogleFonts.getFont(story.preferences.titleFontFamily!).copyWith(
        color: baseStyle.color,
        fontSize: baseStyle.fontSize,
        fontWeight: baseStyle.fontWeight,
      );
    }

    if (story.preferences.titleFontWeight != null) {
      baseStyle = baseStyle.copyWith(
        color: baseStyle.color,
        fontWeight: story.preferences.titleFontWeight != null
            ? AppTheme.calculateFontWeight(baseStyle.fontWeight!, story.preferences.titleFontWeight!)
            : baseStyle.fontWeight,
      );
    }

    return TextFormField(
      focusNode: focusNode,
      initialValue: titleController == null ? draftContent.title : null,
      key: titleController == null ? ValueKey(draftContent.title) : null,
      controller: titleController,
      readOnly: readOnly,
      style: baseStyle,
      maxLines: null,
      maxLength: null,
      autofocus: false,
      decoration: InputDecoration(
        hintText: tr("input.title.hint"),
        border: InputBorder.none,
        isCollapsed: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(top: 12.0, bottom: 12.0),
      ),
    );
  }
}
