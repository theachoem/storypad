import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/services/date_picker_service.dart';
import 'package:storypad/widgets/custom_embed/sp_date_block_embed.dart';
import 'package:storypad/widgets/feeling_picker/sp_feeling_button.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_story_labels.dart';

class StoryHeader extends StatelessWidget {
  const StoryHeader({
    super.key,
    required this.paddingTop,
    required this.story,
    required this.draftContent,
    required this.readOnly,
    required this.draftActions,
    required this.setFeeling,
    required this.onToggleShowDayCount,
    required this.onToggleShowTime,
    required this.onChangeDate,
    required this.feeling,
    this.titleController,
    this.focusNode,
  });

  final double paddingTop;
  final String? feeling;
  final StoryDbModel story;
  final StoryContentDbModel draftContent;
  final TextEditingController? titleController;
  final FocusNode? focusNode;
  final SpStoryLabelsDraftActions? draftActions;
  final Future<void> Function(String? feeling) setFeeling;
  final Future<void> Function() onToggleShowDayCount;
  final Future<void> Function() onToggleShowTime;
  final Future<void> Function(DateTime) onChangeDate;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: MediaQuery.of(context).padding.left, right: MediaQuery.of(context).padding.right),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: paddingTop),
          Container(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: _DateSelector(
                    story: story,
                    readOnly: readOnly,
                    onChangeDate: onChangeDate,
                  ),
                ),
                SpFeelingButton(
                  feeling: feeling,
                  onPicked: setFeeling,
                ),
              ],
            ),
          ),
          SpStoryLabels(
            story: story,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            onToggleShowDayCount: onToggleShowDayCount,
            onToggleShowTime: onToggleShowTime,
            onChangeDate: onChangeDate,
            draftActions: draftActions,
          ),
          if (titleController?.text.trim().isNotEmpty == true || !readOnly) ...[
            _TitleField(
              focusNode: focusNode,
              titleController: titleController,
              draftContent: draftContent,
              readOnly: readOnly,
            )
          ] else ...[
            const SizedBox(height: 12.0),
          ]
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.story,
    required this.readOnly,
    required this.onChangeDate,
  });

  final StoryDbModel story;
  final bool readOnly;
  final Future<void> Function(DateTime)? onChangeDate;

  Future<void> changeDate(BuildContext context) async {
    DateTime? date = await DatePickerService(context: context, currentDate: story.displayPathDate).show();
    if (date != null) {
      onChangeDate?.call(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      InkWell(
        onTap: readOnly || onChangeDate == null ? null : () => changeDate(context),
        borderRadius: BorderRadius.circular(4.0),
        child: Row(
          children: [
            buildDay(context),
            const SizedBox(width: 4.0),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildDaySuffix(context),
                buildMonthYear(context),
              ],
            ),
            if (!readOnly) ...[
              const SizedBox(width: 4.0),
              const Icon(SpIcons.dropDown),
            ]
          ],
        ),
      ),
    ]);
  }

  Widget buildMonthYear(BuildContext context) {
    return Text(
      DateFormatHelper.yMMMM(story.displayPathDate, context.locale),
      style: TextTheme.of(context).labelMedium,
    );
  }

  Widget buildDaySuffix(BuildContext context) {
    return Text(
      SpDateBlockEmbed.getDayOfMonthSuffix(story.day).toLowerCase(),
      style: TextTheme.of(context).labelSmall,
    );
  }

  Widget buildDay(BuildContext context) {
    Color? color;

    if (story.preferences.colorSeedValue != null) {
      color = ColorScheme.of(context).primary;
    } else {
      color = ColorFromDayService(context: context).get(story.displayPathDate.weekday);
    }

    return Text(
      story.day.toString().padLeft(2, '0'),
      style: TextTheme.of(context).headlineLarge?.copyWith(color: color),
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({
    required this.focusNode,
    required this.titleController,
    required this.draftContent,
    required this.readOnly,
  });

  final FocusNode? focusNode;
  final TextEditingController? titleController;
  final StoryContentDbModel draftContent;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: focusNode,
      initialValue: titleController == null ? draftContent.title : null,
      key: titleController == null ? ValueKey(draftContent.title) : null,
      controller: titleController,
      readOnly: readOnly,
      style: Theme.of(context).textTheme.titleLarge,
      maxLines: null,
      maxLength: null,
      autofocus: false,
      decoration: InputDecoration(
        hintText: tr("input.title.hint"),
        border: InputBorder.none,
        isCollapsed: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(top: 12.0, bottom: 12.0),
      ),
    );
  }
}
