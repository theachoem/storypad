part of 'story_pages_builder.dart';

class _StoryPage extends StatelessWidget {
  const _StoryPage({
    required super.key,
    required this.preferences,
    required this.storyContent,
    required this.page,
    required this.onTitleVisibilityChanged,
    required this.onSwap,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.canDeletePage,
    required this.onDelete,
    required this.onChanged,
    required this.onGoToEdit,
    required this.pageIndex,
    this.smallPage = true,
    this.readOnly = false,
  });

  final StoryPreferencesDbModel? preferences;
  final StoryContentDbModel storyContent;
  final StoryPageObject page;
  final void Function(VisibilityInfo info)? onTitleVisibilityChanged;

  final int pageIndex;

  final bool canMoveUp;
  final bool canMoveDown;
  final bool canDeletePage;

  final void Function(int oldIndex, int newIndex)? onSwap;
  final void Function()? onDelete;
  final void Function(StoryPageDbModel newRichPage)? onChanged;
  final void Function()? onGoToEdit;

  final bool readOnly;
  final bool smallPage;

  void onChange() {
    // A story with a page from a newer app version is shown read-only and never saved (e.g. by a checkbox toggle).
    if (page.page.isUnsupported || storyContent.hasUnsupportedPages) return;
    onChanged?.call(page.page.withMarkdown(page.bodyController.serialize()));
  }

  /// How the page title -- the page's leading heading -- looks: the story's title font, size and weight.
  TextStyle _titleStyle(BuildContext context) {
    double? fontSize = preferences?.titleFontSize ?? Theme.of(context).textTheme.titleMedium?.fontSize;
    if (fontSize != null && !smallPage) fontSize += 2;

    return GoogleFonts.getFont(
      preferences?.titleFontFamily ??
          preferences?.fontFamily ??
          context.read<DevicePreferencesProvider>().preferences.fontFamily,
      color: Theme.of(context).textTheme.titleMedium?.color,
      fontSize: fontSize,
      fontWeight: AppTheme.getThemeFontWeight(context, preferences?.titleFontWeight ?? kTitleDefaultFontWeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      decoration: smallPage
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Theme.of(context).dividerColor),
            )
          : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          buildEditor(context),
          if (canMoveUp || canMoveDown || canDeletePage) ...[
            if (!readOnly &&
                (preferences?.layoutType == PageLayoutType.list || preferences?.layoutType == PageLayoutType.grid))
              buildMoreVertButton(context),
          ],
        ],
      ),
    );
  }

  Widget buildEditor(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      spacing: 0.0,
      children: [
        // Marks the page's top (where its title is), for finding the page to open when going to edit.
        VisibilityDetector(
          key: ValueKey('page-title-${page.id}'),
          onVisibilityChanged: onTitleVisibilityChanged,
          child: const SizedBox(height: 8, width: double.infinity),
        ),
        if (page.page.isUnsupported)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text(
              tr('page.newer_version_notice'),
              style: TextTheme.of(context).bodySmall?.copyWith(color: ColorScheme.of(context).error),
            ),
          ),
        Padding(
          padding: smallPage ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 4.0),
          child: editorAdapter.buildEditor(
            context: context,
            controller: page.bodyController,
            focusNode: page.bodyFocusNode,
            scrollController: page.bodyScrollController,
            readOnly: readOnly,
            storyContent: storyContent,
            layoutType: preferences?.layoutType,
            onChanged: onChanged != null ? () => onChange() : null,
            onGoToEdit: onGoToEdit,
            titleStyle: _titleStyle(context),
          ),
        ),
      ],
    );
  }

  Widget buildMoreVertButton(BuildContext context) {
    return Positioned(
      top: -16.0,
      right: -16.0,
      child: SpFocusNodeBuilder(
        focusNode: page.bodyFocusNode,
        child: MoreVertActionButtons(
          pageIndex: pageIndex,
          canMoveUp: canMoveUp,
          canMoveDown: canMoveDown,
          canDeletePage: canDeletePage,
          onSwap: onSwap!,
          onDelete: onDelete!,
        ),
        builder: (context, focused, child) {
          return SpAnimatedIcons.fadeScale(
            duration: Durations.medium3,
            showFirst: focused,
            firstChild: child!,
            secondChild: const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
