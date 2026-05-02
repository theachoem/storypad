import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:animated_clipper/animated_clipper.dart';
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
import 'package:storypad/core/services/story_time_picker_service.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/views/calendar/calendar_view.dart';
import 'package:storypad/views/map/picker/map_picker_view.dart';
import 'package:storypad/widgets/bottom_sheets/sp_days_count_bottom_sheet.dart';
import 'package:storypad/widgets/sp_floating_pop_up_button.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_emoji_tag_picker.dart';
import 'package:storypad/widgets/sp_floating_tag_picker.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';
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
    this.setFeeling,
    this.onToggleTags,
    this.onSetPlace,
    this.onAddCurrentLocation,
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
  final SpStoryLabelsDraftActions? draftActions;
  final Future<void> Function()? onToggleShowDayCount;
  final Future<void> Function(String? feeling)? setFeeling;
  final Future<bool> Function(List<int> tags)? onToggleTags;
  final Future<void> Function(PlaceDbModel? place)? onSetPlace;
  final Future<void> Function()? onAddCurrentLocation;
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
              title: provider.preferences.timeFormat.formatTime(story.displayPathDate, context.locale),
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

    if (onAddCurrentLocation != null && !story.hasLocation) {
      children.add(
        _buildIconButton(
          context: context,
          icon: SpIcons.locationPin,
          tooltip: tr("button.add_current_location"),
          onTap: () async => onAddCurrentLocation!(),
        ),
      );
    }

    bool showLocation = preferences.showLocation || !fromStoryTile;
    if (story.hasLocation && showLocation) {
      children.add(
        buildPin(
          context: context,
          title: story.place!.displayLabel,
          leadingIconData: SpIcons.map,
          onTap: onSetPlace != null
              ? () async {
                  final result = await MapPickerRoute(
                    initialSelectedPlace: story.place,
                  ).push(context);

                  if (result is MapPickerResult) {
                    switch (result.action) {
                      case MapPickerFinalAction.confirm:
                        final selected = result.place;
                        if (selected != null) {
                          await onSetPlace?.call(selected);
                        }
                        break;
                      case MapPickerFinalAction.remove:
                        await onSetPlace?.call(null);
                        break;
                      case MapPickerFinalAction.cancel:
                        break;
                    }
                  }
                }
              : null,
        ),
      );
    }

    // Tags labels including its add button
    bool showTagLabels = preferences.showTagLabels || !fromStoryTile;
    final tagLabels = buildTags(tagProvider, context);
    if (showTagLabels) children.addAll(tagLabels);
    if (onToggleTags != null && tagLabels.isEmpty) {
      children.add(
        SpFloatingPopUpButton(
          estimatedFloatingWidth: 288,
          bottomToTop: false,
          dyGetter: (dy) => dy + 24,
          pathBuilder: PathBuilders.slideDown,
          floatingBuilder: (close) => SpFloatingTagPicker(
            initialTags: story.validTags ?? [],
            onUpdated: onToggleTags!,
            close: close,
          ),
          builder: (open) => _buildIconButton(
            context: context,
            icon: SpIcons.tag,
            tooltip: tr('page.tags.title'),
            onTap: open,
          ),
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
        SpFloatingPopUpButton(
          estimatedFloatingWidth: 288,
          bottomToTop: false,
          dyGetter: (dy) => dy + 24,
          pathBuilder: PathBuilders.slideDown,
          floatingBuilder: (close) => SpEmojiTagPicker(
            initialTags: story.validTags ?? [],
            onUpdated: onToggleTags!,
            close: close,
          ),
          builder: (open) => _buildIconButton(
            context: context,
            icon: SpIcons.addFeeling,
            tooltip: tr('general.stickers'),
            onTap: open,
          ),
        ),
      );
    }

    if (emojis.isNotEmpty) {
      children.add(
        SpFloatingPopUpButton(
          estimatedFloatingWidth: 288,
          bottomToTop: false,
          dyGetter: (dy) => dy + 24,
          pathBuilder: PathBuilders.slideDown,
          floatingBuilder: (close) => SpEmojiTagPicker(
            initialTags: story.validTags ?? [],
            onUpdated: onToggleTags!,
            close: close,
          ),
          builder: (open) => SpTapEffect(
            duration: Durations.medium3,
            curve: Curves.easeInOutCubicEmphasized,
            behavior: .translucent,
            onTap: onToggleTags != null ? open : null,
            child: emojiRow,
          ),
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

  Future<void> showTimePicker(BuildContext context) async {
    final newTime = await StoryTimePickerService(
      context: context,
      story: story,
    ).showPicker();

    if (newTime != null) {
      await onChangeDate?.call(story.copyWith(hour: newTime.hour, minute: newTime.minute).displayPathDate);
    }
  }

  List<Widget> buildTags(TagsProvider tagProvider, BuildContext context) {
    final tags =
        tagProvider.tags?.items
            .where((e) => e.categoryId == null && e.emoji == null && story.validTags?.contains(e.id) == true)
            .toList() ??
        [];
    final children = tags.map((tag) {
      return buildTag(context, tagProvider, tag);
    }).toList();
    return children;
  }

  Widget buildTag(BuildContext context, TagsProvider provider, TagDbModel tag) {
    if (onToggleTags != null) {
      return SpFloatingPopUpButton(
        estimatedFloatingWidth: 288,
        bottomToTop: false,
        dyGetter: (dy) => dy + 24,
        pathBuilder: PathBuilders.slideDown,
        floatingBuilder: (close) => SpFloatingTagPicker(
          initialTags: story.validTags ?? [],
          onUpdated: onToggleTags!,
          close: close,
        ),
        builder: (open) => buildPin(
          context: context,
          title: "# ${tag.title.sanitizeUtf16}",
          onTap: open,
        ),
      );
    }

    return buildPin(
      context: context,
      title: "# ${tag.title.sanitizeUtf16}",
      onTap: () => provider.viewTag(context: context, tag: tag, storyViewOnly: false),
    );
  }

  Widget _buildIconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required FutureOr<void> Function() onTap,
  }) {
    return SpSingleStateWidget.listen(
      initialValue: false,
      builder: (context, loading, notifier) {
        return Tooltip(
          message: tooltip,
          child: Material(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
            color: (AppTheme.isDarkMode(context) ? Colors.white : Colors.black).withValues(alpha: 0.06),
            child: InkWell(
              borderRadius: BorderRadius.circular(4.0),
              onTap: onTap is Future<void> Function()
                  ? () async {
                      notifier.value = true;
                      await onTap();
                      notifier.value = false;
                    }
                  : onTap,
              child: loading
                  ? Container(
                      padding: EdgeInsets.all(MediaQuery.textScalerOf(context).scale(4)),
                      height: MediaQuery.textScalerOf(context).scale(20),
                      width: MediaQuery.textScalerOf(context).scale(20),
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: MediaQuery.textScalerOf(context).scale(3.0),
                      ),
                    )
                  : Container(
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
      },
    );
  }

  Widget buildPin({
    required BuildContext context,
    required String? title,
    required void Function()? onTap,
    String? tooltip,
    IconData? leadingIconData,
    Color? leadingIconColor,
  }) {
    Widget? text;

    if (leadingIconData != null) {
      text = Text.rich(
        TextSpan(
          style: TextTheme.of(context).labelMedium,
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
        style: TextTheme.of(context).labelMedium,
      );
    }

    final child = Material(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      color: (AppTheme.isDarkMode(context) ? Colors.white : Colors.black).withValues(alpha: 0.06),
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
