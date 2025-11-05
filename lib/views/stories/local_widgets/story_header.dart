import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/objects/story_page_object.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/services/date_picker_service.dart';
import 'package:storypad/core/types/page_layout_type.dart';
import 'package:storypad/views/stories/changes/show/show_change_view.dart';
import 'package:storypad/views/stories/edit/edit_story_view_model.dart';
import 'package:storypad/views/stories/show/show_story_view_model.dart';
import 'package:storypad/widgets/feeling_picker/sp_feeling_button.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_measure_size.dart';
import 'package:storypad/widgets/sp_story_labels.dart';

class StoryHeader extends StatelessWidget {
  const StoryHeader({
    super.key,
    required this.story,
    required this.draftContent,
    required this.readOnly,
    required this.dateReadOnly,
    required this.draftActions,
    required this.currentPageIndexNotifier,
    required this.setFeeling,
    required this.onToggleShowDayCount,
    required this.onToggleShowTime,
    required this.onToggleManagingPage,
    required this.onChangeDate,
    required this.onSizeChange,
    required this.page,
  });

  final StoryDbModel story;
  final StoryPageObject page;
  final StoryContentDbModel draftContent;
  final SpStoryLabelsDraftActions? draftActions;
  final ValueNotifier<int?>? currentPageIndexNotifier;
  final Future<void> Function(String? feeling) setFeeling;
  final Future<void> Function() onToggleShowDayCount;
  final Future<void> Function() onToggleShowTime;
  final Future<void> Function(DateTime) onChangeDate;
  final void Function() onToggleManagingPage;
  final void Function(Size size) onSizeChange;
  final bool readOnly;
  final bool dateReadOnly;

  factory StoryHeader.fromEditStory({
    required StoryPageObject page,
    required EditStoryViewModel viewModel,
    required BuildContext context,
  }) {
    return StoryHeader(
      currentPageIndexNotifier: viewModel.story?.preferences.layoutType == PageLayoutType.pages
          ? viewModel.pagesManager.currentPageIndexNotifier
          : null,
      onSizeChange: (size) =>
          viewModel.pagesManager.setHeaderHeight(size.height + MediaQuery.of(context).padding.top + kToolbarHeight),
      story: viewModel.story!,
      draftContent: viewModel.draftContent!,
      setFeeling: viewModel.setFeeling,
      onToggleShowDayCount: viewModel.toggleShowDayCount,
      onToggleShowTime: viewModel.toggleShowTime,
      readOnly: false,
      dateReadOnly: viewModel.story?.eventId != null,
      onChangeDate: viewModel.changeDate,
      onToggleManagingPage: viewModel.pagesManager.toggleManagingPage,
      draftActions: null,
      page: page,
    );
  }

  factory StoryHeader.fromShowStory({
    required StoryPageObject page,
    required ShowStoryViewModel viewModel,
    required BuildContext context,
  }) {
    return StoryHeader(
      page: page,
      currentPageIndexNotifier: viewModel.story?.preferences.layoutType == PageLayoutType.pages
          ? viewModel.pagesManager.currentPageIndexNotifier
          : null,
      onSizeChange: (size) =>
          viewModel.pagesManager.setHeaderHeight(size.height + MediaQuery.of(context).padding.top + kToolbarHeight),
      story: viewModel.story!,
      draftContent: viewModel.draftContent!,
      setFeeling: viewModel.setFeeling,
      onToggleShowDayCount: viewModel.toggleShowDayCount,
      onToggleShowTime: viewModel.toggleShowTime,
      readOnly: true,
      dateReadOnly: true,
      onChangeDate: viewModel.changeDate,
      onToggleManagingPage: viewModel.pagesManager.toggleManagingPage,
      draftActions: SpStoryLabelsDraftActions(
        onContinueEditing: () => viewModel.goToEditPage(context),
        onDiscardDraft: () async {
          OkCancelResult result = await showOkCancelAlertDialog(
            context: context,
            isDestructiveAction: true,
            title: tr("dialog.are_you_sure_to_discard_these_changes.title"),
            okLabel: tr("button.discard"),
          );

          if (result == OkCancelResult.ok) {
            await StoryDbModel.db.set(viewModel.story!.copyWith(draftContent: null));
            await viewModel.load();
          }
        },
        onViewPrevious: () async {
          await ShowChangeRoute(
            content: viewModel.story!.latestContent!,
            preferences: viewModel.story!.preferences,
          ).push(context);

          await viewModel.load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpMeasureSize(
      onChange: onSizeChange,
      child: buildContent(),
    );
  }

  Widget buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 16.0, right: 8.0),
          child: Row(
            children: [
              Expanded(
                child: _StoryHeaderDateSelector(
                  story: story,
                  dateReadOnly: dateReadOnly,
                  onChangeDate: onChangeDate,
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
          story: story,
          currentPagesCount: draftContent.richPages?.length,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          onToggleShowDayCount: onToggleShowDayCount,
          onToggleShowTime: onToggleShowTime,
          onChangeDate: onChangeDate,
          onToggleManagingPage: onToggleManagingPage,
          draftActions: draftActions,
        ),
      ],
    );
  }
}

class _StoryHeaderDateSelector extends StatelessWidget {
  const _StoryHeaderDateSelector({
    required this.story,
    required this.dateReadOnly,
    required this.onChangeDate,
  });

  final StoryDbModel story;
  final bool dateReadOnly;
  final Future<void> Function(DateTime)? onChangeDate;

  Future<void> changeDate(BuildContext context) async {
    DateTime? date = await DatePickerService(context: context, currentDate: story.displayPathDate).show();
    if (date != null) {
      onChangeDate?.call(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? daySuffix = DateFormatHelper.getDaySuffix(story.displayPathDate.day, context.locale);
    return Row(
      children: [
        InkWell(
          onTap: dateReadOnly || onChangeDate == null ? null : () => changeDate(context),
          borderRadius: BorderRadius.circular(4.0),
          child: Row(
            children: [
              buildDay(context),
              const SizedBox(width: 4.0),
              if (daySuffix != null) buildDaySuffixMonthYear(context, daySuffix) else buildMonthYear(context),
              if (!dateReadOnly) ...[
                const SizedBox(width: 4.0),
                const Icon(SpIcons.dropDown),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget buildDaySuffixMonthYear(BuildContext context, String daySuffix) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          daySuffix,
          style: TextTheme.of(context).labelSmall,
        ),
        Text(
          DateFormatHelper.yMMMM(story.displayPathDate, context.locale),
          style: TextTheme.of(context).labelMedium,
        ),
      ],
    );
  }

  Widget buildMonthYear(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormatHelper.MMM(story.displayPathDate, context.locale),
          style: TextTheme.of(context).labelSmall,
        ),
        Text(
          DateFormatHelper.y(story.displayPathDate, context.locale),
          style: TextTheme.of(context).labelSmall,
        ),
      ],
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
