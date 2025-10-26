import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/gallery_template_object.dart';
import 'package:storypad/core/objects/story_page_objects_map.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/markdown_to_quill_delta_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/services/gallery_template_usage_service.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/views/stories/local_widgets/base_story_view_model.dart';
import 'package:storypad/views/templates/stories/template_stories_view.dart';

import 'show_template_gallery_view.dart';

class ShowTemplateGalleryViewModel extends ChangeNotifier with DisposeAwareMixin, DebounchedCallback {
  final ShowTemplateGalleryRoute params;

  ShowTemplateGalleryViewModel({required this.params}) {
    pagesManager = StoryPagesManagerInfo(
      initialPageIndex: 0,
      initialScrollOffset: 0.0,
      draftContent: () => draftContent,
      notifyListeners: notifyListeners,
    );

    load();
  }

  late GalleryTemplateObject galleryTemplate = params.galleryTemplate;
  StoryContentDbModel? draftContent;

  final ValueNotifier<DateTime?> lastSavedAtNotifier = ValueNotifier(null);
  late final StoryPagesManagerInfo pagesManager;
  final DateTime openedOn = DateTime.now();

  Future<void> load() async {
    StoryContentDbModel content = getDraftContent();

    pagesManager.pagesMap = await StoryPageObjectsMap.fromContent(
      content: content,
      readOnly: true,
      initialPagesMap: null,
    );

    draftContent = content.copyWith(
      richPages: content.richPages?.map((e) => pagesManager.pagesMap[e.id]?.page ?? e).toList(),
    );

    galleryTemplate = galleryTemplate.copyWith(lazyDraftContent: draftContent);
    notifyListeners();
  }

  StoryContentDbModel getDraftContent() {
    final richPages = galleryTemplate.pages.map((e) {
      return StoryPageDbModel(
        id: galleryTemplate.pages.indexOf(e),
        title: e.title,
        body: MarkdownToQuillDeltaService.call(e.content),
      );
    }).toList();
    return StoryContentDbModel.create().copyWith(richPages: richPages);
  }

  void goToPreviousStories(BuildContext context) async {
    TemplateStoriesRoute(
      template: null,
      galleryTemplate: galleryTemplate,
    ).push(context);
  }

  void saveTemplate(BuildContext context) async {
    final result = await TemplateDbModel.db.where(
      filters: {'gallery_template_id': galleryTemplate.id},
    );

    if (!context.mounted) return;
    if (result?.items.isNotEmpty == true) {
      OkCancelResult userAction = await showOkCancelAlertDialog(
        context: context,
        title: tr('dialog.template_already_save.tite'),
        message: tr('dialog.template_already_save.message'),
      );

      if (userAction == OkCancelResult.cancel) return;
    }

    final now = DateTime.now();
    final newTemplate = TemplateDbModel(
      id: now.millisecondsSinceEpoch,
      tags: null,
      name: galleryTemplate.name,
      content: draftContent,
      galleryTemplateId: galleryTemplate.id,
      note: null,
      createdAt: now,
      updatedAt: now,
      archivedAt: null,
      lastSavedDeviceId: null,
      permanentlyDeletedAt: null,
    );

    await TemplateDbModel.db.set(newTemplate);
    if (!context.mounted) return;

    MessengerService.of(context).showSuccess();
  }

  void useTemplate(BuildContext context) async {
    AnalyticsService.instance.logUseGalleryTemplate(templateId: galleryTemplate.id, source: 'gallery');
    GalleryTemplateUsageService.instance.recordTemplateUsage(templateId: galleryTemplate.id);

    final result = await EditStoryRoute(
      galleryTemplate: galleryTemplate,
    ).push(context, rootNavigator: true);

    if (context.mounted && result is StoryDbModel) {
      Future.delayed(const Duration(seconds: 1)).then((_) {
        HomeView.reload(debugSource: '$runtimeType#useTemplate');
      });
      Navigator.maybePop(context, result);
    }
  }

  @override
  void dispose() {
    pagesManager.dispose();
    super.dispose();
  }
}
