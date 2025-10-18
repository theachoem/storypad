import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/story_time_picker_service.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_days_count_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpStoryLabelsDraftActions {
  final Future<void> Function() onContinueEditing;
  final Future<void> Function() onDiscardDraft;
  final Future<void> Function() onViewPrevious;

  SpStoryLabelsDraftActions({
    required this.onContinueEditing,
    required this.onDiscardDraft,
    required this.onViewPrevious,
  });
}

class SpStoryLabels extends StatelessWidget {
  const SpStoryLabels({
    super.key,
    required this.story,
    required this.onToggleShowDayCount,
    required this.onToggleShowTime,
    required this.onChangeDate,
    required this.onToggleManagingPage,
    this.currentPagesCount,
    this.draftActions,
    this.margin = EdgeInsets.zero,
    this.fromStoryTile = false,
  });

  final StoryDbModel story;

  // sometime current pages count from current state & story is different.
  // example in edit view, there pages are store in seperated state.
  // in that case, we use this var instead.
  final int? currentPagesCount;

  final EdgeInsets margin;
  final bool fromStoryTile;
  final SpStoryLabelsDraftActions? draftActions;
  final Future<void> Function()? onToggleShowDayCount;
  final Future<void> Function()? onToggleShowTime;
  final Future<void> Function(DateTime dateTime)? onChangeDate;
  final void Function()? onToggleManagingPage;

  Future<void> showDraftActionSheet(BuildContext context) async {
    final action = await showModalActionSheet(
      context: context,
      actions: [
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
    List<Widget> children = buildTags(tagProvider, context);

    int pageCount = currentPagesCount ?? (story.draftContent ?? story.latestContent)?.richPages?.length ?? 0;
    if (pageCount > 1) {
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

    bool showTime = story.preferredShowTime || !fromStoryTile;
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

    if (story.event?.period == true) {
      children.add(
        Icon(
          SpIcons.waterDrop,
          color: Theme.of(context).colorScheme.error,
          size: MediaQuery.textScalerOf(context).scale(16.0),
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
      onToggleShowTime: onToggleShowTime,
    ).showPicker();

    if (newTime != null) {
      await onChangeDate?.call(story.copyWith(hour: newTime.hour, minute: newTime.minute).displayPathDate);
    }
  }

  List<Widget> buildTags(TagsProvider tagProvider, BuildContext context) {
    final tags = tagProvider.tags?.items.where((e) => story.validTags?.contains(e.id) == true).toList() ?? [];
    final children = tags.map((tag) {
      return buildTag(context, tagProvider, tag);
    }).toList();
    return children;
  }

  Widget buildTag(BuildContext context, TagsProvider provider, TagDbModel tag) {
    return buildPin(
      context: context,
      title: "# ${tag.title}",
      onTap: () => provider.viewTag(context: context, tag: tag, storyViewOnly: false),
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
      text = RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
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
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.textScalerOf(context).scale(7),
            vertical: MediaQuery.textScalerOf(context).scale(1),
          ),
          child: text,
        ),
      ),
    );

    return Tooltip(
      message: tooltip ?? title,
      child: child,
    );
  }
}
