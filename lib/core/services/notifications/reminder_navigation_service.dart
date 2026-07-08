import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/objects/gallery_template_object.dart';
import 'package:storypad/core/objects/reminder_object.dart';
import 'package:storypad/core/objects/calendar_segment_id.dart';
import 'package:storypad/core/services/gallery_template_service.dart';
import 'package:storypad/core/services/markdown_to_quill_delta_service.dart';
import 'package:storypad/core/services/notifications/reminder_notification_copy_service.dart';
import 'package:storypad/core/types/reminder_type.dart';
import 'package:storypad/providers/root_provider.dart';
import 'package:storypad/views/calendar/calendar_view.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/views/throwback/throwback_view.dart';

/// Turns a tapped reminder into a navigation action, and provides the
/// notification title/body for each reminder type (varied English copy for
/// built-ins via [ReminderNotificationCopyService]; the user's own message for
/// custom reminders).
class ReminderNavigationService {
  ReminderNavigationService._();
  static final ReminderNavigationService instance = ReminderNavigationService._();

  /// Returns the notification title+body together — always as one pair, so a
  /// randomly-picked title never ends up mismatched with an unrelated body.
  static Future<(String title, String body)> copyFor(ReminderObject reminder) async {
    switch (reminder.type) {
      case ReminderType.daily:
        return ReminderNotificationCopyService.dailyCopy();
      case ReminderType.onThisDay:
        return ReminderNotificationCopyService.onThisDayCopy();
      case ReminderType.period:
        return ReminderNotificationCopyService.periodCopy();
      case ReminderType.custom:
        // The message *is* the title (matches how it's shown in the reminders
        // list) — EditCustomReminderViewModel requires a non-empty message
        // before a custom reminder can be saved at all.
        return (reminder.message!.trim(), tr('reminder.custom.notification_body'));
    }
  }

  bool _isHandling = false;

  Future<void> handleTap(ReminderObject reminder, GlobalKey<NavigatorState>? navigatorKey) async {
    if (_isHandling) return;
    _isHandling = true;

    try {
      final context = await _waitForNavigatorContext(navigatorKey);
      if (context == null || !context.mounted) return;

      switch (reminder.type) {
        case ReminderType.daily:
          await _openNewStory(context);
          break;
        case ReminderType.onThisDay:
          final now = DateTime.now();
          await ThrowbackRoute(month: now.month, day: now.day).push(context);
          break;
        case ReminderType.period:
          final now = DateTime.now();
          await CalendarRoute(
            initialYear: now.year,
            initialMonth: now.month,
            initialSegment: CalendarSegmentId.period,
          ).push(context);
          break;
        case ReminderType.custom:
          await _openCustom(reminder, context);
          break;
      }

      await Future.delayed(const Duration(seconds: 1));
    } finally {
      _isHandling = false;
    }
  }

  Future<void> _openNewStory(BuildContext context) async {
    context.read<RootProvider>().navigate(const HomeRoute());
    await EditStoryRoute(id: null, initialYear: DateTime.now().year).push(context);
    await HomeView.reload(debugSource: '$runtimeType#_openNewStory');
  }

  Future<void> _openCustom(ReminderObject reminder, BuildContext context) async {
    final hasPrefill =
        reminder.templateId != null || reminder.galleryTemplateId != null || (reminder.tagIds?.isNotEmpty ?? false);

    // No prefill configured -> just bring the app to the foreground on Home.
    if (!hasPrefill) {
      context.read<RootProvider>().navigate(const HomeRoute());
      return;
    }

    TemplateDbModel? template;
    if (reminder.templateId != null) {
      template = await TemplateDbModel.db.find(reminder.templateId!);
      if (!context.mounted) return;
    }

    GalleryTemplateObject? galleryTemplate;
    if (reminder.galleryTemplateId != null) {
      galleryTemplate = await _findGalleryTemplate(reminder.galleryTemplateId!);
      if (!context.mounted) return;
    }

    context.read<RootProvider>().navigate(const HomeRoute());
    await EditStoryRoute(
      id: null,
      initialYear: DateTime.now().year,
      template: template,
      galleryTemplate: galleryTemplate,
      initialTagIds: reminder.tagIds,
    ).push(context);
    await HomeView.reload(debugSource: '$runtimeType#_openCustom');
  }

  Future<GalleryTemplateObject?> _findGalleryTemplate(String templateId) async {
    final templatesByCategory = await GalleryTemplateService.loadTemplates();
    for (final templates in templatesByCategory.values) {
      for (final template in templates) {
        if (template.id != templateId) continue;

        final richPages = [
          for (int i = 0; i < template.pages.length; i++)
            StoryPageDbModel(
              id: i,
              title: template.pages[i].title,
              body: MarkdownToQuillDeltaService.call(template.pages[i].content),
            ),
        ];
        final draftContent = StoryContentDbModel.create().copyWith(richPages: richPages);
        return template.copyWith(lazyDraftContent: draftContent);
      }
    }
    return null;
  }

  Future<BuildContext?> _waitForNavigatorContext(GlobalKey<NavigatorState>? navigatorKey) async {
    // Longer window than quick actions: a notification can cold-start the app, so
    // we may need to wait for RootProvider to build and register the navigator key.
    for (int attempt = 0; attempt < 60; attempt++) {
      final context = navigatorKey?.currentContext;
      if (context?.mounted == true) return context;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return null;
  }
}
