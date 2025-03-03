import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/providers/tags_provider.dart';

class SpStoryLabels extends StatelessWidget {
  const SpStoryLabels({
    super.key,
    required this.story,
    required this.onToggleShowDayCount,
    required this.onToggleShowTime,
    required this.onChangeDate,
    this.margin = EdgeInsets.zero,
    this.fromStoryTile = false,
  });

  final StoryDbModel story;
  final EdgeInsets margin;
  final bool fromStoryTile;
  final Future<void> Function()? onToggleShowDayCount;
  final Future<void> Function()? onToggleShowTime;
  final Future<void> Function(DateTime dateTime)? onChangeDate;

  Future<void> showDayCountSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useRootNavigator: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16.0),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr("dialog.lookings_back.title"),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                plural("dialog.lookings_back.subtitle", story.dateDifferentCount.inDays),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: ColorScheme.of(context).primary),
              ),
              SizedBox(height: 16.0),
              OutlinedButton.icon(
                icon: Icon(story.preferredShowDayCount ? MdiIcons.pinOff : MdiIcons.pin,
                    color: ColorScheme.of(context).primary),
                label: Text(story.preferredShowDayCount ? tr("button.unpin_from_home") : tr("button.pin_to_home")),
                onPressed: onToggleShowDayCount == null
                    ? null
                    : () async {
                        onToggleShowDayCount!();
                        if (context.mounted) Navigator.maybePop(context);
                      },
              ),
            ],
          ),
        );
      },
    );
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
      children.add(buildPin(
        context: context,
        title: "📌 ${plural("plural.day_ago", story.dateDifferentCount.inDays)}",
        onTap: () => showDayCountSheet(context),
      ));
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
  }) {
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
          child: Text(
            title,
            style: TextTheme.of(context).labelMedium,
          ),
        ),
      ),
    );
  }
}
