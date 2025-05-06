import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/services/date_picker_service.dart';
import 'package:storypad/widgets/custom_embed/sp_date_block_embed.dart';
import 'package:storypad/widgets/feeling_picker/sp_feeling_button.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_story_labels.dart';

part 'story_header_title_field.dart';
part 'story_header_date_selector.dart';

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
                  child: _StoryHeaderDateSelector(
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
            const SizedBox(height: 4.0),
            _StoryHeaderTitleField(
              focusNode: focusNode,
              titleController: titleController,
              draftContent: draftContent,
              readOnly: readOnly,
              story: story,
            )
          ] else ...[
            const SizedBox(height: 12.0),
          ]
        ],
      ),
    );
  }
}
