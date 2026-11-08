import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart' show kIsCupertino;
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_category_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/objects/sp_latlng_bounds.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/geocoding/sp_geocoding_service.dart';
import 'package:storypad/core/services/map/map_app_opener_service.dart';
import 'package:storypad/core/services/map/place_selection_service.dart';
import 'package:storypad/core/services/location/sp_app_location_service.dart';
import 'package:storypad/core/services/location/sp_location_service.dart';
import 'package:storypad/core/services/map/initial_map_camera_resolver.dart';
import 'package:storypad/core/storages/preferred_emoji_tab_storage.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_place_name_sheet.dart';
import 'package:storypad/widgets/maps/map_types.dart';
import 'package:storypad/widgets/maps/sp_flutter_map.dart';
import 'package:storypad/widgets/maps/sp_google_maps_flutter.dart';
import 'package:storypad/widgets/maps/sp_map_center_pin.dart';
import 'package:storypad/widgets/maps/sp_map_controller.dart';
import 'package:storypad/widgets/maps/sp_map_dot_marker.dart';
import 'package:storypad/widgets/maps/sp_map_side_button.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_filled_button.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';
import 'package:storypad/widgets/sp_tag_title.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

part 'story_labels/tags_tab.dart';
part 'story_labels/stickers_tab.dart';
part 'story_labels/place_tab.dart';
part 'story_labels/place_lookup.dart';
part 'story_labels/custom_emoji_sheet.dart';

enum SpStoryLabelsTab { tags, people, place, stickers }

/// One sheet for a story's labels — Tags, People, Map and Stickers tabs — opened on
/// the tab of the label that was tapped (see `SpStoryLabels`).
///
/// Tags, people and stickers all live in the story's one tag list and are saved on
/// every toggle via [onUpdateTags]; the Map tab saves with its own Save button
/// via [onSetPlace], then closes the sheet. A tab shows only when its callback is given.
class SpStoryLabelsSheet extends BaseBottomSheet {
  const SpStoryLabelsSheet({
    required this.initialTab,
    required this.initialTags,
    required this.initialPlace,
    required this.onUpdateTags,
    required this.onSetPlace,
    required this.autofocusSearch,
  });

  final SpStoryLabelsTab initialTab;
  final List<int> initialTags;
  final PlaceDbModel? initialPlace;
  final Future<bool> Function(List<int> tags)? onUpdateTags;
  final Future<void> Function(PlaceDbModel? place)? onSetPlace;

  /// Focus the Tags/People search field on open — only while editing a story, not when viewing one.
  final bool autofocusSearch;

  @override
  bool get fullScreen => false;

  // The map runs edge to edge; each tab applies the side insets once itself.
  @override
  bool get edgeToEdge => true;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return _StoryLabelsBody(
      sheet: this,
      contentHeight: fixedContentHeight(context, bottomPadding),
      bottomPadding: bottomPadding,
    );
  }
}

class _StoryLabelsBody extends StatefulWidget {
  const _StoryLabelsBody({
    required this.sheet,
    required this.contentHeight,
    required this.bottomPadding,
  });

  final SpStoryLabelsSheet sheet;
  final double contentHeight;
  final double bottomPadding;

  @override
  State<_StoryLabelsBody> createState() => _StoryLabelsBodyState();
}

class _StoryLabelsBodyState extends State<_StoryLabelsBody> {
  late final List<SpStoryLabelsTab> tabs = [
    if (widget.sheet.onUpdateTags != null) ...[.tags, .people],
    if (widget.sheet.onSetPlace != null) .place,
    if (widget.sheet.onUpdateTags != null) .stickers,
  ];

  late SpStoryLabelsTab tab = tabs.contains(widget.sheet.initialTab) ? widget.sheet.initialTab : tabs.first;

  // Shared by the tags, people and stickers tabs: they all edit the story's one tag list,
  // so each toggle must start from the others' latest changes.
  late Set<int> selectedTags = widget.sheet.initialTags.toSet();

  // Counted once for both tag tabs (switching Tags ⇄ People rebuilds the tab).
  late final Map<int, int> storyCountByTagId = () {
    final provider = context.read<TagsProvider>();
    return StoryDbModel.db.getStoryCountByTags(
      tagIds: [...?provider.tags?.items.map((e) => e.id), ...?provider.peopleTags?.items.map((e) => e.id)],
    );
  }();

  // Every tag tab toggles through here, from the latest set, so quick taps never undo each other.
  // [exclusiveWith]: tags that can't be on the story together with [id] (a single-select sticker category).
  Future<void> _toggleTag(int id, {Iterable<int> exclusiveWith = const []}) async {
    final previous = selectedTags;
    final next = previous.contains(id)
        ? ({...previous}..remove(id))
        : ({...previous}
            ..removeAll(exclusiveWith)
            ..add(id));
    setState(() => selectedTags = next);

    final success = await widget.sheet.onUpdateTags!(next.toList());
    // Undo only if no newer toggle came since, or that one would be lost.
    if (!success && mounted && identical(selectedTags, next)) setState(() => selectedTags = previous);
  }

  void _setTab(SpStoryLabelsTab tab) {
    if (this.tab == tab) return;
    setState(() => this.tab = tab);
    if (tab == .people) AnalyticsService.instance.logTagPickerPeopleModeEntered(method: 'button');
  }

  String _labelOf(SpStoryLabelsTab tab) {
    return switch (tab) {
      .tags => tr('page.tags.title'),
      .people => tr('general.tag_category.people_title'),
      .stickers => tr('general.stickers'),
      .place => tr('page.map.title'),
    };
  }

  @override
  Widget build(BuildContext context) {
    // The body runs to the sheet's bottom edge; the insets (sides, and safe area + keyboard at the
    // bottom) reach the tabs as MediaQuery padding, and each tab applies them once (see [BaseBottomSheet.edgeToEdge]).
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: mediaQuery.padding.copyWith(top: 0.0, bottom: widget.bottomPadding),
        viewPadding: mediaQuery.viewPadding.copyWith(top: 0.0, bottom: widget.bottomPadding),
        viewInsets: mediaQuery.viewInsets.copyWith(bottom: 0.0),
      ),
      child: SizedBox(
        height: widget.contentHeight + widget.bottomPadding,
        child: Column(
          children: [
            if (tabs.length > 1) ...[
              _SideInset(
                minimum: 16.0,
                child: SizedBox(width: double.infinity, child: _buildTabSwitch()),
              ),
              const SizedBox(height: 12.0),
            ],
            // Only the open tab is built (the map loads only when its tab opens), and tabs
            // switch by tap only: a swipe would fight the map and swiping a tag row.
            Expanded(child: _buildTab()),
          ],
        ),
      ),
    );
  }

  // Each tab gets a quarter of the width: a long label (e.g. French "Autocollants", or a big text size)
  // shrinks a little to fit instead of being cut off.
  Widget _buildTabLabel(SpStoryLabelsTab tab) {
    return FittedBox(
      fit: .scaleDown,
      child: Text(_labelOf(tab), maxLines: 1),
    );
  }

  Widget _buildTabSwitch() {
    if (kIsCupertino) {
      return CupertinoSlidingSegmentedControl<SpStoryLabelsTab>(
        groupValue: tab,
        onValueChanged: (tab) {
          if (tab != null) _setTab(tab);
        },
        children: {
          for (final tab in tabs) tab: _buildTabLabel(tab),
        },
      );
    }

    return SegmentedButton<SpStoryLabelsTab>(
      showSelectedIcon: false,
      selected: {tab},
      onSelectionChanged: (value) => _setTab(value.first),
      segments: [
        for (final tab in tabs)
          ButtonSegment(
            value: tab,
            label: _buildTabLabel(tab),
          ),
      ],
    );
  }

  Widget _buildTab() {
    return switch (tab) {
      .tags || .people => _TagsTab(
        key: ValueKey(tab),
        peopleMode: tab == .people,
        selectedTags: selectedTags,
        storyCountByTagId: storyCountByTagId,
        onToggle: _toggleTag,
        autofocusSearch: widget.sheet.autofocusSearch,
      ),
      .stickers => _StickersTab(
        selectedTags: selectedTags,
        onToggle: _toggleTag,
      ),
      .place => _PlaceTab(
        savedPlace: widget.sheet.initialPlace,
        onSetPlace: widget.sheet.onSetPlace!,
      ),
    };
  }
}

/// Keeps [child] clear of the sheet's side insets, with at least [minimum] on each side — what a
/// [ListTile] does for its own content (a SafeArea with its padding as the minimum), so other rows
/// line up with list rows. Lists themselves pad only the bottom: their tiles handle the sides.
class _SideInset extends StatelessWidget {
  const _SideInset({
    required this.minimum,
    required this.child,
  });

  final double minimum;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      minimum: EdgeInsets.symmetric(horizontal: minimum),
      child: child,
    );
  }
}
