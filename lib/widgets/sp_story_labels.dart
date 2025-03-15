import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/widgets/bottom_sheets/days_count_bottom_sheet.dart';

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
    this.draftActions,
    this.margin = EdgeInsets.zero,
    this.fromStoryTile = false,
  });

  final StoryDbModel story;
  final EdgeInsets margin;
  final bool fromStoryTile;
  final SpStoryLabelsDraftActions? draftActions;
  final Future<void> Function()? onToggleShowDayCount;
  final Future<void> Function()? onToggleShowTime;
  final Future<void> Function(DateTime dateTime)? onChangeDate;

  Future<void> showDraftActionSheet(BuildContext context) async {
    final action = await showModalActionSheet(
      context: context,
      actions: [
        SheetAction(
          label: tr("button.continue_editing"),
          icon: Icons.edit,
          key: "continue_editing",
          isDefaultAction: true,
        ),
        SheetAction(
          label: tr("button.view_previous"),
          icon: Icons.compare,
          key: "view_previous",
        ),
        SheetAction(
          label: tr("button.discard_draft"),
          icon: Icons.clear,
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

  Future<void> showTimePickerDialog(BuildContext context) async {
    final newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(story.displayPathDate),
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child!,
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(backgroundColor: ColorScheme.of(context).surface),
              icon: Icon(story.preferredShowTime ? MdiIcons.pinOff : MdiIcons.pin,
                  color: ColorScheme.of(context).primary),
              label: Text(story.preferredShowTime ? tr("button.unpin_from_home") : tr("button.pin_to_home")),
              onPressed: onToggleShowTime == null
                  ? null
                  : () async {
                      onToggleShowTime!();
                      if (context.mounted) Navigator.maybePop(context);
                    },
            ),
          ],
        );
      },
    );

    if (newTime != null) {
      await onChangeDate?.call(story.copyWith(hour: newTime.hour, minute: newTime.minute).displayPathDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    TagsProvider tagProvider = Provider.of<TagsProvider>(context);
    List<Widget> children = buildTags(tagProvider, context);

    bool shouldShowDayCount = story.preferredShowDayCount || !fromStoryTile;
    if (shouldShowDayCount && story.dateDifferentCount.inDays > 0) {
      children.add(
        buildPin(
          context: context,
          title: "📌 ${plural("plural.day_ago", story.dateDifferentCount.inDays)}",
          onTap: () => DaysCountBottomSheet(
            story: story,
            onToggleShowDayCount: onToggleShowDayCount,
          ).show(context: context),
        ),
      );
    }

    bool showTime = story.preferredShowTime || !fromStoryTile;
    if (showTime) {
      children.add(
        buildPin(
          context: context,
          title: DateFormatHelper.jm(story.displayPathDate, context.locale),
          onTap: () => showTimePickerDialog(context),
        ),
      );
    }

    bool showDraft = false;
    if (story.draftContent != null) showDraft = fromStoryTile || draftActions != null;
    if (showDraft) {
      children.add(
        buildPin(
          leadingIconData: Icons.edit_note,
          context: context,
          title: tr("general.draft"),
          onTap: draftActions != null ? () => showDraftActionSheet(context) : null,
        ),
      );
    }

    if (children.isEmpty) return SizedBox.shrink();
    return Container(
      padding: margin,
      child: Wrap(
        spacing: MediaQuery.textScalerOf(context).scale(4),
        runSpacing: MediaQuery.textScalerOf(context).scale(4),
        children: children,
      ),
    );
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

  Material buildPin({
    required BuildContext context,
    required String title,
    required void Function()? onTap,
    IconData? leadingIconData,
  }) {
    Widget text;

    if (leadingIconData != null) {
      text = RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          style: TextTheme.of(context).labelMedium,
          children: [
            WidgetSpan(child: Icon(leadingIconData, size: 16.0), alignment: PlaceholderAlignment.middle),
            TextSpan(text: " $title"),
          ],
        ),
      );
    } else {
      text = Text(
        title,
        style: TextTheme.of(context).labelMedium,
      );
    }

    return Material(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      color: ColorScheme.of(context).readOnly.surface2,
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
  }
}
