import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/story_page_objects_map.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/services/gallery_template_usage_service.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/views/stories/local_widgets/base_story_view_model.dart';
import 'package:storypad/views/templates/edit/edit_template_view.dart';
import 'package:storypad/views/templates/stories/template_stories_view.dart';
import 'package:storypad/widgets/bottom_sheets/sp_template_info_sheet.dart';

import 'show_template_view.dart';

class ShowTemplateViewModel extends ChangeNotifier with DisposeAwareMixin, DebounchedCallback {
  final ShowTemplateRoute params;

  ShowTemplateViewModel({required this.params}) {
    _setTemplate(params.template);

    pagesManager = StoryPagesManagerInfo(
      initialPageIndex: 0,
      initialScrollOffset: 0.0,
      draftContent: () => draftContent,
      notifyListeners: notifyListeners,
    );

    load();
  }

  late TemplateDbModel template;
  StoryContentDbModel? draftContent;

  final ValueNotifier<DateTime?> lastSavedAtNotifier = ValueNotifier(null);
  late final StoryPagesManagerInfo pagesManager;
  final DateTime openedOn = DateTime.now();

  Future<void> load() async {
    pagesManager.pagesMap = await StoryPageObjectsMap.fromContent(
      content: draftContent!,
      readOnly: true,
      initialPagesMap: null,
    );

    notifyListeners();
  }

  void useTemplate(BuildContext context) async {
    AnalyticsService.instance.logUseGalleryTemplate(templateId: template.id.toString(), source: 'my_templates');
    GalleryTemplateUsageService.instance.recordTemplateUsage(templateId: template.id.toString());

    final result = await EditStoryRoute(
      initialYear: params.initialYear,
      initialMonth: params.initialMonth,
      initialDay: params.initialDay,
      template: template,
    ).push(context, rootNavigator: true);

    if (context.mounted && result is StoryDbModel) {
      Future.delayed(const Duration(seconds: 1)).then((_) {
        HomeView.reload(debugSource: '$runtimeType#useTemplate');
      });
      Navigator.maybePop(context, result);
    }
  }

  void goToPreviousStories(BuildContext context) async {
    TemplateStoriesRoute(
      template: template,
      galleryTemplate: null,
    ).push(context);
  }

  Future<void> goToEditPage(BuildContext context) async {
    await EditTemplateRoute(initialTemplate: template).push(context);
    template = await TemplateDbModel.db.find(template.id) ?? template;
    _setTemplate(template);
    await load();
  }

  void _setTemplate(TemplateDbModel template) {
    this.template = template;
    draftContent = template.content ?? StoryContentDbModel.create(createdAt: openedOn);

    bool alreadyHasPage = draftContent?.richPages?.isNotEmpty == true;
    if (!alreadyHasPage) draftContent = draftContent?.addRichPage(crossAxisCount: 2, mainAxisCount: 1);
  }

  @override
  void dispose() {
    pagesManager.dispose();
    super.dispose();
  }

  void archive(BuildContext context) async {
    TemplateDbModel archivedTemplate = template.copyWith(archivedAt: DateTime.now(), updatedAt: DateTime.now());
    await TemplateDbModel.db.set(archivedTemplate);

    if (context.mounted) {
      MessengerService.of(context).showSnackBar(tr('snack_bar.archive_success'), success: true);
      Navigator.maybePop(context);
    }
  }

  void putBack(BuildContext context) async {
    TemplateDbModel putBackTemplate = template.copyWith(archivedAt: null, updatedAt: DateTime.now());
    await TemplateDbModel.db.set(putBackTemplate);

    if (context.mounted) {
      Navigator.maybePop(context);
    }
  }

  void delete(BuildContext context) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: tr('dialog.are_you_sure.title'),
      message: tr('dialog.are_you_sure.you_cant_undo_message'),
      isDestructiveAction: true,
    );

    if (result == OkCancelResult.ok) {
      await TemplateDbModel.db.delete(template.id);
      if (context.mounted) Navigator.maybePop(context);
    }
  }

  void showInfo(BuildContext context) {
    SpTemplateInfoSheet(
      template: template,
      persisted: true,
    ).show(context: context);
  }
}
