import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/tag_category_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/tags/tags_view.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_section_title.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

enum _SheetSegment { stickers, tags }

class SpStoryTagsBottomSheet extends BaseBottomSheet {
  final List<int> initialTags;
  final Future<bool> Function(List<int> tags) onUpdated;
  final bool showTagAsInitialSegment;

  SpStoryTagsBottomSheet({
    required this.initialTags,
    required this.onUpdated,
    this.showTagAsInitialSegment = false,
  });

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    // padding top + app bar height + story header height. Because we want the header UI to be visible even sheet is shown above it.
    final double pageHeader = MediaQuery.of(HomeView.homeContext ?? context).padding.top + kToolbarHeight + 88;
    final contentHeight = MediaQuery.of(HomeView.homeContext ?? context).size.height - pageHeader - kToolbarHeight;

    // It is safe to store selected tags on local variable.
    // This is opened as sheet and will not likely to rebuild.
    List<int> selectedTags = initialTags;

    return SpSingleStateWidget<_SheetSegment>.listen(
      initialValue: showTagAsInitialSegment ? .tags : .stickers,
      builder: (context, segment, notifier) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentButtons(context, segment, notifier),
            SizedBox(
              height: contentHeight.clamp(200, 600),
              child: switch (segment) {
                _SheetSegment.stickers => _StickersTab(
                  initialTags: selectedTags,
                  onUpdated: (tags) async {
                    selectedTags = tags;
                    bool updated = await onUpdated(tags);
                    if (!updated) selectedTags = initialTags;
                    return updated;
                  },
                  bottomPadding: bottomPadding,
                ),
                _SheetSegment.tags => TagsView(
                  params: TagsRoute(
                    initialSelectedTags: selectedTags,
                    onToggleTags: (tags) async {
                      selectedTags = tags;
                      bool updated = await onUpdated(tags);
                      if (!updated) selectedTags = initialTags;
                      return updated;
                    },
                    bottomPadding: bottomPadding,
                  ),
                ),
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSegmentButtons(BuildContext context, _SheetSegment segment, CmValueNotifier<_SheetSegment> notifier) {
    Widget control;

    if (kIsCupertino) {
      control = CupertinoSlidingSegmentedControl<_SheetSegment>(
        groupValue: segment,
        onValueChanged: (v) {
          if (v != null) notifier.value = v;
        },
        children: {
          _SheetSegment.stickers: Text(tr("general.stickers")),
          _SheetSegment.tags: Text(tr("page.tags.title")),
        },
      );
    } else {
      control = SegmentedButton<_SheetSegment>(
        selected: {segment},
        multiSelectionEnabled: false,
        onSelectionChanged: (value) {
          if (value.isNotEmpty) notifier.value = value.first;
        },
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: _SheetSegment.stickers, label: Text(tr("general.stickers"))),
          ButtonSegment(value: _SheetSegment.tags, label: Text(tr("page.tags.title"))),
        ],
      );
    }

    return Container(
      margin: EdgeInsets.only(
        left: MediaQuery.of(context).padding.left,
        right: MediaQuery.of(context).padding.right,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      width: double.infinity,
      child: control,
    );
  }
}

class _StickersTab extends StatefulWidget {
  final List<int> initialTags;
  final Future<bool> Function(List<int> tags) onUpdated;
  final double bottomPadding;

  const _StickersTab({
    required this.initialTags,
    required this.onUpdated,
    required this.bottomPadding,
  });

  @override
  State<_StickersTab> createState() => _StickersTabState();
}

class _StickersTabState extends State<_StickersTab> with DebounchedCallback {
  late Set<int> selectedTags = widget.initialTags.toSet();
  Map<TagCategoryDbModel, List<TagDbModel>>? stickersByCategory;

  @override
  void initState() {
    super.initState();
    _loadStickers();
  }

  Future<void> _loadStickers() async {
    final result = await TagCategoryDbModel.db.getSuggestTagsByCategory(selectedTagIds: selectedTags);
    if (mounted) setState(() => stickersByCategory = result);
  }

  Future<void> _onToggle(TagDbModel tag) async {
    final category = stickersByCategory?.entries.firstWhere((entry) => entry.key.id == tag.categoryId).key;
    if (category == null) return;

    List<int> newTags;

    if (category.multiSelect) {
      newTags = selectedTags.contains(tag.id)
          ? ({...selectedTags}..remove(tag.id)).toList()
          : ({...selectedTags, tag.id}).toList();
    } else {
      if (selectedTags.contains(tag.id)) {
        newTags = ({...selectedTags}..remove(tag.id)).toList();
      } else {
        final otherTagIdsInCategory =
            stickersByCategory?[category]?.map((e) => e.id).where((id) => id != tag.id).toSet() ?? {};
        newTags =
            ({...selectedTags}
                  ..removeAll(otherTagIdsInCategory)
                  ..add(tag.id))
                .toList();
      }
    }

    selectedTags = newTags.toSet();
    setState(() {});

    // Must save persist the emoji tag before saving to stories.
    if (!tag.exist()) await tag.save();

    final success = await widget.onUpdated(newTags);
    if (!success) {
      selectedTags = widget.initialTags.toSet();
      setState(() {});
    }

    // reload stickers to ensure everything is update to date,
    // especially for newly persisted emoji tags to be loaded from DB instead of using old in-memory data.
    debouncedCallback(() {
      _loadStickers();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (stickersByCategory == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: widget.bottomPadding + 16.0, top: 16.0),
      itemCount: stickersByCategory!.entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16.0),
      itemBuilder: (context, index) {
        final entry = stickersByCategory!.entries.elementAt(index);
        return _StickerCategorySection(
          category: entry.key,
          tags: entry.value,
          selectedTags: selectedTags,
          onToggle: _onToggle,
        );
      },
    );
  }
}

class _StickerCategorySection extends StatelessWidget {
  final TagCategoryDbModel category;
  final List<TagDbModel> tags;
  final Set<int> selectedTags;
  final Future<void> Function(TagDbModel tag) onToggle;

  const _StickerCategorySection({
    required this.category,
    required this.tags,
    required this.selectedTags,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      spacing: 4.0,
      children: [
        SpSectionTitle(title: category.title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const minTileSize = 44.0;
              const spacing = 8.0;
              final crossAxisCount = math.max(1, ((constraints.maxWidth + spacing) / (minTileSize + spacing)).floor());

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: tags.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  final isSelected = selectedTags.contains(tag.id);

                  return _StickerChip(
                    tag: tag,
                    isSelected: isSelected,
                    onTap: () => onToggle(tag),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StickerChip extends StatelessWidget {
  final TagDbModel tag;
  final bool isSelected;
  final VoidCallback onTap;

  const _StickerChip({
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return SpTapEffect(
      onTap: onTap,
      scaleActive: 0.9,
      effects: [.scaleDown],
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: .circle,
          color: isSelected ? colorScheme.surface : Colors.transparent,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.7),
            width: isSelected ? 2 : 1.0,
          ),
        ),
        child: Text(
          tag.emoji ?? '',
          style: const TextStyle(fontSize: 28.0),
        ),
      ),
    );
  }
}
