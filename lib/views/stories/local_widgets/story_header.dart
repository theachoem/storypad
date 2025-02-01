import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/services/date_format_service.dart';
import 'package:storypad/widgets/custom_embed/date_block_embed.dart';
import 'package:storypad/widgets/feeling_picker/sp_feeling_button.dart';
import 'package:storypad/widgets/sp_story_labels.dart';

class StoryHeader extends StatelessWidget {
  const StoryHeader({
    super.key,
    required this.paddingTop,
    required this.story,
    required this.setFeeling,
    required this.draftContent,
    required this.readOnly,
    required this.onToggleShowDayCount,
    required this.onSetDate,
    this.titleController,
  });

  final double paddingTop;
  final StoryDbModel story;
  final StoryContentDbModel draftContent;
  final TextEditingController? titleController;
  final Future<void> Function(String? feeling) setFeeling;
  final Future<void> Function() onToggleShowDayCount;
  final Future<void> Function(DateTime)? onSetDate;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  onSetDate: onSetDate,
                ),
              ),
              SpFeelingButton(
                feeling: story.feeling,
                onPicked: setFeeling,
              ),
            ],
          ),
        ),
        SpStoryLabels(
          onToggleShowDayCount: onToggleShowDayCount,
          story: story,
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        ),
        if (draftContent.title?.trim().isNotEmpty == true || !readOnly) ...[
          _TitleField(
            titleController: titleController,
            draftContent: draftContent,
            readOnly: readOnly,
          )
        ] else ...[
          SizedBox(height: 8.0),
        ]
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.story,
    required this.readOnly,
    required this.onSetDate,
  });

  final StoryDbModel story;
  final bool readOnly;
  final Future<void> Function(DateTime)? onSetDate;

  Future<void> changeDate(BuildContext context) async {
    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 100 * 365)),
      currentDate: story.displayPathDate,
    );

    if (date != null) {
      onSetDate?.call(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      InkWell(
        onTap: onSetDate == null ? null : () => changeDate(context),
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
              const Icon(Icons.arrow_drop_down),
            ]
          ],
        ),
      ),
    ]);
  }

  Widget buildMonthYear(BuildContext context) {
    return Text(
      DateFormatService.yM(story.displayPathDate),
      style: TextTheme.of(context).labelMedium,
    );
  }

  Widget buildDaySuffix(BuildContext context) {
    return Text(
      DateBlockEmbed.getDayOfMonthSuffix(story.day).toLowerCase(),
      style: TextTheme.of(context).labelSmall,
    );
  }

  Widget buildDay(BuildContext context) {
    return Text(
      story.day.toString().padLeft(2, '0'),
      style: TextTheme.of(context)
          .headlineLarge
          ?.copyWith(color: ColorFromDayService(context: context).get(story.displayPathDate.weekday)),
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({
    required this.titleController,
    required this.draftContent,
    required this.readOnly,
  });

  final TextEditingController? titleController;
  final StoryContentDbModel draftContent;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: titleController == null ? draftContent.title : null,
      key: titleController == null ? ValueKey(draftContent.title) : null,
      controller: titleController,
      readOnly: readOnly,
      style: Theme.of(context).textTheme.titleLarge,
      maxLines: null,
      maxLength: null,
      autofocus: !readOnly,
      decoration: InputDecoration(
        hintText: "Title...",
        border: InputBorder.none,
        isCollapsed: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
    );
  }
}
