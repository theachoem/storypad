part of 'story_pages_builder.dart';

class _StoryPage extends StatelessWidget {
  const _StoryPage({
    required super.key,
    required this.preferences,
    required this.storyContent,
    required this.page,
    required this.onFocusChange,
    required this.onTitleVisibilityChanged,
    required this.onSwap,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.canDeletePage,
    required this.onDelete,
    required this.onChanged,
    required this.onGoToEdit,
    required this.pageIndex,
    this.showBorder = true,
    this.readOnly = false,
  });

  final StoryPreferencesDbModel? preferences;
  final StoryContentDbModel storyContent;
  final StoryPageObject page;
  final void Function(bool titleFocused, bool bodyFocused)? onFocusChange;
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
  final bool showBorder;

  void onChange() {
    StoryPageDbModel richPage = page.page.copyWith(
      title: page.titleController.text.trim().isNotEmpty == true ? page.titleController.text.trim() : null,
      plainText: QuillRootToPlainTextService.call(page.bodyController.document.root),
      body: page.bodyController.document.toDelta().toJson(),
    );

    onChanged?.call(richPage);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showBorder
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
            if (!readOnly && preferences?.layoutType == PageLayoutType.list) buildMoreVertButton(context),
          ]
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
        if (readOnly && page.titleController.text.trim().isEmpty) ...[
          const SizedBox(height: 8)
        ] else ...[
          VisibilityDetector(
            key: ValueKey('page-title-${page.id}'),
            onVisibilityChanged: onTitleVisibilityChanged,
            child: _TitleField(
              titleFocusNode: page.titleFocusNode,
              bodyFocusNode: page.bodyFocusNode,
              titleController: page.titleController,
              preferences: preferences,
              readOnly: readOnly,
              onChanged: (_) => onChange(),
            ),
          ),
        ],
        _QuillEditor(
          onChanged: onChanged != null ? () => onChange() : null,
          bodyFocusNode: page.bodyFocusNode,
          bodyController: page.bodyController,
          scrollController: page.bodyScrollController,
          readOnly: readOnly,
          storyContent: storyContent,
          onGoToEdit: onGoToEdit,
        ),
      ],
    );
  }

  Widget buildMoreVertButton(BuildContext context) {
    return Positioned(
      top: -16.0,
      right: -16.0,
      child: SpFocusNodeBuilder2(
        focusNode1: page.titleFocusNode,
        focusNode2: page.bodyFocusNode,
        onFucusChangeAfterInitialized: onFocusChange,
        child: _MoreVertActionButtons(
          pageIndex: pageIndex,
          canMoveUp: canMoveUp,
          canMoveDown: canMoveDown,
          canDeletePage: canDeletePage,
          onSwap: onSwap!,
          onDelete: onDelete!,
        ),
        builder: (context, titleFocused, bodyFocused, child) {
          return SpAnimatedIcons.fadeScale(
            duration: Durations.medium3,
            showFirst: titleFocused || bodyFocused,
            firstChild: child!,
            secondChild: const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
