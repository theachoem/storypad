import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/extensions/matrix_4_extension.dart';
import 'package:storypad/core/extensions/string_extension.dart';
import 'package:storypad/core/objects/story_tile_preferences_object.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/location/current_place_service.dart';
import 'package:storypad/core/services/map/place_selection_service.dart';
import 'package:storypad/core/services/story_time_picker_service.dart';
import 'package:storypad/core/services/tag_color_service.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/views/calendar/calendar_view.dart';
import 'package:storypad/widgets/bottom_sheets/sp_days_count_bottom_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_story_labels_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

class SpStoryLabelsDraftActions {
  final Future<void> Function() onSaveDraft;
  final Future<void> Function() onContinueEditing;
  final Future<void> Function() onDiscardDraft;
  final Future<void> Function() onViewPrevious;

  SpStoryLabelsDraftActions({
    required this.onSaveDraft,
    required this.onContinueEditing,
    required this.onDiscardDraft,
    required this.onViewPrevious,
  });
}

class SpStoryLabels extends StatelessWidget {
  const SpStoryLabels({
    super.key,
    required this.story,
    required this.preferences,
    required this.onToggleShowDayCount,
    required this.onChangeDate,
    required this.onToggleManagingPage,
    required this.editing,
    this.setFeeling,
    this.onToggleTags,
    this.onSetPlace,
    this.onAddCurrentPlace,
    this.currentPagesCount,
    this.voicesCount,
    this.draftActions,
    this.margin = EdgeInsets.zero,
    this.fromStoryTile = false,
  });

  final StoryDbModel story;
  final StoryTilePreferencesObject preferences;

  // sometime current pages count from current state & story is different.
  // example in edit view, there pages are store in seperated state.
  // in that case, we use this var instead.
  final int? currentPagesCount;

  // this count UI should only show in story tile.
  // when user open show/edit page, no need to show it because when user click on it,
  // we don't have any action yet.
  final int? voicesCount;

  final EdgeInsets margin;
  final bool fromStoryTile;

  // True in the edit view (see [SpStoryLabelsSheet.editing]).
  final bool editing;
  final SpStoryLabelsDraftActions? draftActions;
  final Future<void> Function()? onToggleShowDayCount;
  final Future<void> Function(String? feeling)? setFeeling;
  final Future<bool> Function(List<int> tags)? onToggleTags;
  final Future<void> Function(PlaceDbModel? place)? onSetPlace;

  /// The pin on a story dated today sets the current location in one tap (no sheet); false when there's
  /// none, and the Map tab opens instead.
  final Future<bool> Function()? onAddCurrentPlace;
  final Future<void> Function(DateTime dateTime)? onChangeDate;
  final void Function()? onToggleManagingPage;

  Future<void> showDraftActionSheet(BuildContext context) async {
    final action = await showModalActionSheet(
      context: context,
      actions: [
        SheetAction(
          label: tr("button.save"),
          icon: SpIcons.save,
          key: "save",
          isDefaultAction: true,
        ),
        SheetAction(
          label: tr("button.continue_editing"),
          icon: SpIcons.edit,
          key: "continue_editing",
          isDefaultAction: true,
        ),
        SheetAction(
          label: tr("button.view_previous"),
          icon: SpIcons.compare,
          key: "view_previous",
        ),
        SheetAction(
          label: tr("button.discard_draft"),
          icon: SpIcons.clear,
          key: "discard_draft",
          isDestructiveAction: true,
        ),
      ],
    );

    switch (action) {
      case "save":
        AnalyticsService.instance.logStorySaveDraft(story: story);
        draftActions!.onSaveDraft();
        break;
      case "continue_editing":
        AnalyticsService.instance.logStoryContinueEdit(story: story);
        draftActions!.onContinueEditing();
        break;
      case "discard_draft":
        AnalyticsService.instance.logStoryDiscardDraft(story: story);
        draftActions!.onDiscardDraft();
        break;
      case "view_previous":
        AnalyticsService.instance.logStoryViewPrevious(story: story);
        draftActions!.onViewPrevious();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    TagsProvider tagProvider = Provider.of<TagsProvider>(context);
    List<Widget> children = [];

    bool showTime = !fromStoryTile;
    if (showTime) {
      children.add(
        Consumer<DevicePreferencesProvider>(
          builder: (context, provider, child) {
            return buildPin(
              context: context,
              title: provider.timeFormatOf(context).formatTime(story.displayPathDate, context.locale),
              onTap: () => showTimePicker(context),
            );
          },
        ),
      );
    }

    bool showVoiceCount = preferences.showVoiceCount;
    if (showVoiceCount && voicesCount != null && voicesCount! > 0) {
      children.add(
        buildPin(
          leadingIconData: SpIcons.voice,
          context: context,
          title: plural('plural.voice', voicesCount!),
          onTap: null,
        ),
      );
    }

    int pageCount = currentPagesCount ?? (story.draftContent ?? story.latestContent)?.richPages?.length ?? 0;
    bool showPageCount = preferences.showPageCount || !fromStoryTile;
    if (pageCount > 1 && showPageCount) {
      children.add(
        buildPin(
          leadingIconData: SpIcons.managingPage,
          context: context,
          tooltip: tr('button.manage_pages'),
          title: plural("plural.page", pageCount),
          onTap: onToggleManagingPage,
        ),
      );
    }

    bool shouldShowDayCount = story.preferredShowDayCount || !fromStoryTile;
    if (shouldShowDayCount && story.dateDifferentCount.inDays > 0) {
      children.add(
        buildPin(
          context: context,
          title: "📌 ${plural("plural.day_ago", story.dateDifferentCount.inDays)}",
          onTap: () => SpDaysCountBottomSheet(
            story: story,
            onToggleShowDayCount: onToggleShowDayCount,
          ).show(context: context),
        ),
      );
    }

    bool showDraft = false;
    if (story.draftContent != null) showDraft = fromStoryTile || draftActions != null;
    if (showDraft) {
      children.add(
        buildPin(
          leadingIconData: SpIcons.draftEdit,
          context: context,
          title: tr("general.draft"),
          onTap: draftActions != null ? () => showDraftActionSheet(context) : null,
        ),
      );
    }

    if (story.inArchives) {
      children.add(
        buildPin(
          leadingIconData: SpIcons.archive,
          context: context,
          title: tr('snack_bar.archive_success'),
          onTap: null,
        ),
      );
    }

    if (story.inBins) {
      children.add(
        buildPin(
          leadingIconColor: ColorScheme.of(context).error,
          leadingIconData: SpIcons.delete,
          context: context,
          title: tr('snack_bar.move_to_bin_success'),
          onTap: null,
        ),
      );
    }

    // Tags labels including its add button. Topics (#) and people (@) are toggled independently.
    bool showTagLabels = preferences.showTagLabels || !fromStoryTile;
    bool showPeopleLabels = preferences.showPeopleLabels || !fromStoryTile;
    final topicLabels = buildTags(tagProvider, context, people: false);
    final peopleLabels = buildTags(tagProvider, context, people: true);

    if (showTagLabels) children.addAll(topicLabels);
    if (showPeopleLabels) children.addAll(peopleLabels);

    // Add button (opens the picker covering both tags & people) only when the story has neither.
    if (onToggleTags != null && topicLabels.isEmpty && peopleLabels.isEmpty) {
      children.add(
        _buildIconButton(
          context: context,
          icon: SpIcons.tag,
          tooltip: tr('page.tags.title'),
          onTap: () => _showLabelsSheet(context, .tags),
        ),
      );
    }

    if (onSetPlace != null && !story.hasLocation) {
      final addCurrentPlace = onAddCurrentPlace;

      // Where it's written, for a story about today; for another day the place is likely elsewhere: pick it on the map.
      if (addCurrentPlace != null && DateUtils.isSameDay(story.displayPathDate, DateTime.now())) {
        children.add(
          _AddCurrentPlaceButton(
            onAdd: addCurrentPlace,
            onUnavailable: () => _showLabelsSheet(context, .place),
            buildButton: (onTap) => _buildIconButton(
              context: context,
              icon: SpIcons.locationPin,
              tooltip: tr("button.add_current_location"),
              onTap: onTap,
            ),
            locating: _buildCurrentLocationPin(context, onTap: null),
          ),
        );
      } else {
        children.add(
          _buildIconButton(
            context: context,
            icon: SpIcons.locationPin,
            tooltip: tr("page.map.title"),
            onTap: () => _showLabelsSheet(context, .place),
          ),
        );
      }
    }

    bool showLocation = preferences.showLocation || !fromStoryTile;
    if (story.hasLocation && showLocation) {
      final place = story.place!;
      final onTap = onSetPlace != null ? () => _showLabelsSheet(context, .place) : null;

      children.add(
        // Set from the current location and its name still on the way: "Current location", not bare coordinates.
        // One of the user's own places shows its name at once.
        ValueListenableBuilder(
          valueListenable: CurrentPlaceService.locating,
          builder: (context, _, _) {
            final named = place.placeName?.trim().isNotEmpty == true;
            if (CurrentPlaceService.isLocating(place) && !named && PlaceSelectionService.needsDetails(place)) {
              return _buildCurrentLocationPin(context, onTap: onTap);
            }
            return buildPin(context: context, title: place.displayLabel, leadingIconData: SpIcons.map, onTap: onTap);
          },
        ),
      );
    }

    // Emoji labels including its add button
    final emojis = (story.validTags?.map((tag) => tagProvider.getEmojiTag(tag)) ?? []).whereType<String>();
    final emojiRow = Row(
      mainAxisSize: .min,
      children: emojis.map((emoji) {
        return Container(
          padding: EdgeInsets.all(MediaQuery.textScalerOf(context).scale(1)),
          height: MediaQuery.textScalerOf(context).scale(20),
          width: MediaQuery.textScalerOf(context).scale(20),
          alignment: .center,
          child: FittedBox(
            child: Text(
              emoji,
              textAlign: .center,
              softWrap: true,
              style: const TextStyle(fontSize: 40, height: 1.0),
              strutStyle: const StrutStyle(
                forceStrutHeight: true,
                fontSize: 40,
                height: 1.0,
              ),
            ),
          ),
        );
      }).toList(),
    );

    if (onToggleTags != null && emojis.isEmpty) {
      children.add(
        _buildIconButton(
          context: context,
          icon: SpIcons.addFeeling,
          tooltip: tr('general.stickers'),
          onTap: () => _showLabelsSheet(context, .stickers),
        ),
      );
    }

    if (emojis.isNotEmpty) {
      children.add(
        SpTapEffect(
          duration: Durations.medium3,
          curve: Curves.easeInOutCubicEmphasized,
          behavior: .translucent,
          onTap: onToggleTags != null ? () => _showLabelsSheet(context, .stickers) : null,
          child: emojiRow,
        ),
      );
    }

    if (story.event?.period == true) {
      children.add(
        SpTapEffect(
          scaleActive: 2.5,
          duration: Durations.medium3,
          curve: Curves.easeInOutCubicEmphasized,
          effects: [.scaleDown],
          behavior: .translucent,
          onTap: fromStoryTile
              ? null
              : () {
                  CalendarRoute(
                    initialMonth: story.event!.month,
                    initialYear: story.event!.year,
                    initialSegment: .period,
                  ).push(context);
                },
          child: SizedBox(
            height: MediaQuery.textScalerOf(context).scale(20),
            child: Align(
              alignment: .center,
              widthFactor: 1.0,
              child: Icon(
                SpIcons.waterDrop,
                color: Theme.of(context).colorScheme.error,
                size: MediaQuery.textScalerOf(context).scale(16.0),
              ),
            ),
          ),
        ),
      );
    }

    if (fromStoryTile && story.pinned == true) {
      children.add(
        SizedBox(
          height: MediaQuery.textScalerOf(context).scale(20),
          child: Align(
            alignment: .center,
            widthFactor: 1.0,
            child: Transform(
              alignment: .center,
              transform: Matrix4.identity()
                ..rotateZ(0.5)
                ..spScale(1.1),
              child: Icon(
                SpIcons.pin,
                color: Theme.of(context).colorScheme.secondary,
                size: MediaQuery.textScalerOf(context).scale(16.0),
              ),
            ),
          ),
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: margin,
      child: Wrap(
        spacing: MediaQuery.textScalerOf(context).scale(4),
        runSpacing: MediaQuery.textScalerOf(context).scale(4),
        children: children,
      ),
    );
  }

  Future<void> _showLabelsSheet(BuildContext context, SpStoryLabelsTab tab) {
    return SpStoryLabelsSheet(
      initialTab: tab,
      initialTags: story.validTags ?? [],
      initialPlace: story.place,
      onUpdateTags: onToggleTags,
      onSetPlace: onSetPlace,
      editing: editing,
    ).show(context: context);
  }

  Future<void> showTimePicker(BuildContext context) async {
    final newTime = await StoryTimePickerService(
      context: context,
      story: story,
    ).showPicker();

    if (newTime != null) {
      await onChangeDate?.call(story.copyWith(hour: newTime.hour, minute: newTime.minute).displayPathDate);
    }
  }

  List<Widget> buildTags(TagsProvider tagProvider, BuildContext context, {required bool people}) {
    if (people) {
      final peopleTags =
          tagProvider.peopleTags?.items.where((e) => story.validTags?.contains(e.id) == true).toList() ?? [];
      return [for (final person in peopleTags) buildTag(context, tagProvider, person, prefix: "@")];
    }

    final tags =
        tagProvider.tags?.items
            .where((e) => e.categoryId == null && e.emoji == null && story.validTags?.contains(e.id) == true)
            .toList() ??
        [];
    return [for (final tag in tags) buildTag(context, tagProvider, tag, prefix: "#")];
  }

  Widget buildTag(BuildContext context, TagsProvider provider, TagDbModel tag, {required String prefix}) {
    final seed = tag.colorSeed;
    final colors = seed != null ? TagColorService.resolve(seed, Theme.of(context).brightness) : null;

    return buildPin(
      context: context,
      title: "$prefix${tag.title.sanitizeUtf16}",
      backgroundColor: colors?.background,
      foregroundColor: colors?.foreground,
      onTap: onToggleTags != null
          ? () => _showLabelsSheet(context, tag.isPerson ? .people : .tags)
          : () => provider.viewTag(context: context, tag: tag, storyViewOnly: false),
    );
  }

  // Gently pulsing while the name is on the way: nothing to wait for, the story can be written meanwhile.
  Widget _buildCurrentLocationPin(BuildContext context, {required void Function()? onTap}) {
    return _Pulse(
      child: buildPin(
        context: context,
        title: tr("general.current_location"),
        leadingIconData: SpIcons.map,
        onTap: onTap,
      ),
    );
  }

  Widget _buildIconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required void Function() onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
        color: (AppTheme.isDarkMode(context) ? Colors.white : Colors.black).withValues(alpha: 0.06),
        child: InkWell(
          borderRadius: BorderRadius.circular(4.0),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.textScalerOf(context).scale(8.0)),
            height: MediaQuery.textScalerOf(context).scale(20),
            child: Icon(
              icon,
              size: MediaQuery.textScalerOf(context).scale(14.0),
              color: ColorScheme.of(context).onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPin({
    required BuildContext context,
    required String? title,
    required void Function()? onTap,
    String? tooltip,
    IconData? leadingIconData,
    Color? leadingIconColor,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final textStyle = TextTheme.of(context).labelMedium?.copyWith(color: foregroundColor);
    Widget? text;

    if (leadingIconData != null) {
      text = Text.rich(
        TextSpan(
          style: textStyle,
          children: [
            WidgetSpan(
              child: Icon(leadingIconData, size: 16.0, color: leadingIconColor),
              alignment: PlaceholderAlignment.middle,
            ),
            if (title != null) TextSpan(text: " $title"),
          ],
        ),
      );
    } else if (title != null) {
      text = Text(
        title,
        style: textStyle,
      );
    }

    final child = Material(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      color: backgroundColor ?? (AppTheme.isDarkMode(context) ? Colors.white : Colors.black).withValues(alpha: 0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(4.0),
        onTap: onTap,
        child: Container(
          height: MediaQuery.textScalerOf(context).scale(20),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.textScalerOf(context).scale(7),
          ),
          child: Align(
            alignment: .center,
            widthFactor: 1.0,
            child: text,
          ),
        ),
      ),
    );

    return Tooltip(
      message: tooltip ?? title,
      child: child,
    );
  }
}

/// The pin that sets the current location in one tap: shows [locating] until the coordinates are set (then
/// the story's place chip takes its place), or opens the Map tab ([onUnavailable]) when there are none.
class _AddCurrentPlaceButton extends StatefulWidget {
  const _AddCurrentPlaceButton({
    required this.onAdd,
    required this.onUnavailable,
    required this.buildButton,
    required this.locating,
  });

  final Future<bool> Function() onAdd;
  final void Function() onUnavailable;
  final Widget Function(void Function() onTap) buildButton;
  final Widget locating;

  @override
  State<_AddCurrentPlaceButton> createState() => _AddCurrentPlaceButtonState();
}

class _AddCurrentPlaceButtonState extends State<_AddCurrentPlaceButton> {
  bool _adding = false;

  Future<void> _add() async {
    if (_adding) return;
    setState(() => _adding = true);

    bool added = false;
    try {
      added = await widget.onAdd();
    } finally {
      // Also when adding threw (a failed save): otherwise the chip keeps pulsing.
      if (mounted) setState(() => _adding = false);
    }

    if (mounted && !added) widget.onUnavailable();
  }

  @override
  Widget build(BuildContext context) {
    return _adding ? widget.locating : widget.buildButton(_add);
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: widget.child);
  }
}
