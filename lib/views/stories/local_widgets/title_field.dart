part of 'story_pages_builder.dart';

class _TitleField extends StatelessWidget {
  const _TitleField({
    required this.titleFocusNode,
    required this.titleController,
    required this.preferences,
    required this.readOnly,
    required this.onChanged,
    required this.bodyFocusNode,
  });

  final FocusNode titleFocusNode;
  final FocusNode bodyFocusNode;
  final TextEditingController? titleController;
  final StoryPreferencesDbModel? preferences;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    TextStyle baseStyle = GoogleFonts.getFont(
      preferences?.titleFontFamily ??
          preferences?.fontFamily ??
          context.read<DevicePreferencesProvider>().preferences.fontFamily,
      color: Theme.of(context).textTheme.titleMedium?.color,
      fontSize: preferences?.titleFontSize ?? Theme.of(context).textTheme.titleMedium?.fontSize,
      fontWeight: AppTheme.getThemeFontWeight(context, preferences?.titleFontWeight ?? kTitleDefaultFontWeight),
    );

    return TextFormField(
      onChanged: readOnly ? null : onChanged,
      focusNode: titleFocusNode,
      readOnly: readOnly,
      controller: titleController,
      style: baseStyle,
      scrollPadding: EdgeInsets.zero,
      maxLines: null,
      maxLength: null,
      autofocus: false,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (value) => bodyFocusNode.requestFocus(),
      decoration: InputDecoration(
        hintText: tr('input.title.hint'),
        isCollapsed: true,
        contentPadding: const EdgeInsets.only(top: 12, left: 12.0, bottom: 4, right: 12.0),
        border: InputBorder.none,
      ),
    );
  }
}
