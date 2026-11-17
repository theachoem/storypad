part of '../sp_story_labels_sheet.dart';

/// The full emoji picker, opened from a stickers section's "+"; pops the picked emoji.
class _CustomEmojiSheet extends BaseBottomSheet {
  const _CustomEmojiSheet({
    required this.category,
    required this.initialCategory,
  });

  final TagCategoryDbModel category;
  final Category? initialCategory;

  // Private class: name it for analytics (it's from the runtime type otherwise).
  @override
  String get className => 'CustomEmojiSheet';

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    final Category initialCategory =
        this.initialCategory ??
        switch (category.id) {
          1 => .SMILEYS,
          2 => .ACTIVITIES,
          _ => .RECENT,
        };

    return Column(
      mainAxisSize: .min,
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: EmojiPicker(
            onEmojiSelected: (_, emoji) => Navigator.of(context).pop(emoji.emoji),
            onCategoryChanged: (category) => PreferredEmojiTabStorage().setCategoryFor(this.category.id, category),
            config: Config(
              locale: context.locale,
              emojiViewConfig: const EmojiViewConfig(
                columns: 8,
                emojiSizeMax: 28.0,
                backgroundColor: Colors.transparent,
                buttonMode: kIsCupertino ? .CUPERTINO : .MATERIAL,
              ),
              categoryViewConfig: CategoryViewConfig(
                initCategory: initialCategory,
                backgroundColor: Colors.transparent,
                indicatorColor: ColorScheme.of(context).primary,
                iconColor: ColorScheme.of(context).onSurface.withValues(alpha: 0.4),
                iconColorSelected: ColorScheme.of(context).primary,
              ),
              bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
            ),
          ),
        ),
        SizedBox(height: bottomPadding),
      ],
    );
  }
}
