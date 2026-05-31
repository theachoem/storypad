import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/objects/app_quick_action_object.dart';
import 'package:storypad/core/objects/gallery_template_object.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/assets/app_file_picker_service.dart';
import 'package:storypad/core/services/assets/insert_file_to_db_service.dart';
import 'package:storypad/core/services/gallery_template_service.dart';
import 'package:storypad/core/services/voice_recorder_service.dart';
import 'package:storypad/core/storages/device_preferences_storage.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/root_provider.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/home/home_view_model.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/views/tags/show/show_tag_view.dart';
import 'package:storypad/widgets/bottom_sheets/sp_voice_recording_sheet.dart';
import 'package:storypad/widgets/sp_app_lock_wrapper.dart';

typedef AppQuickActionLaunchHandler = FutureOr<void> Function(String actionId);

class AppQuickActionsService with DebounchedCallback {
  AppQuickActionsService({QuickActions quickActions = const QuickActions()}) : _quickActions = quickActions;

  static AppQuickActionsService instance = AppQuickActionsService();

  static const int iosMaxActionCount = 4;
  static const int androidMaxActionCount = 4;

  final QuickActions _quickActions;

  bool get supported => Platform.isIOS || Platform.isAndroid;
  int get maxActionCount => Platform.isIOS
      ? iosMaxActionCount
      : Platform.isAndroid
      ? androidMaxActionCount
      : 0;

  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (!supported) return;

    await _ignoreMissingPlugin(
      () => _quickActions.initialize((actionId) {
        debouncedCallback(() {
          _handleLaunch(actionId, navigatorKey);
        });
      }),
    );
  }

  Future<void> setActions(List<AppQuickActionObject>? actions) async {
    if (!supported) return;

    await _ignoreMissingPlugin(
      () => _quickActions.setShortcutItems(
        [
          for (final action in (actions ?? const <AppQuickActionObject>[]).take(maxActionCount))
            ShortcutItem(
              type: action.id,
              localizedTitle: action.label,
              icon: action.nativeIcon ?? AppQuickActionObject.nativeIconFor(type: action.type, id: action.id),
            ),
        ],
      ),
    );
  }

  Future<void> clearActions() => setActions(const []);

  Future<void> _handleLaunch(String actionId, GlobalKey<NavigatorState> navigatorKey) async {
    final action = DevicePreferencesStorage.appInstance.preferences.homeQuickActions
        ?.where((action) => action.id == actionId)
        .firstOrNull;
    if (action == null) return;

    final context = await _waitForNavigatorContext(navigatorKey);
    if (context == null || !context.mounted) return;

    switch (action.type) {
      case AppQuickActionType.defaultAction:
        await _handleDefaultAction(action, context);
      case AppQuickActionType.template:
        await _handleTemplateAction(action, context);
      case AppQuickActionType.tag:
        await _handleTagAction(action, context);
    }
  }

  Future<void> _handleDefaultAction(AppQuickActionObject action, BuildContext context) async {
    final defaultAction = AppDefaultQuickActionType.fromId(action.id);
    if (defaultAction == null) return;

    context.read<RootProvider>().navigate(const HomeRoute());

    switch (defaultAction) {
      case AppDefaultQuickActionType.newStory:
        await _openNewStory(context);
      case AppDefaultQuickActionType.takePhoto:
        await _takePhoto(context);
      case AppDefaultQuickActionType.recordVoice:
        await _recordVoice(context);
    }
  }

  Future<void> _handleTemplateAction(AppQuickActionObject action, BuildContext context) async {
    final reference = action.templateReference;
    if (reference == null) return;

    switch (reference.type) {
      case AppQuickActionTemplateType.custom:
        final templateId = int.tryParse(reference.id);
        if (templateId == null) return;

        final template = await TemplateDbModel.db.find(templateId);
        if (template == null || !context.mounted) return;

        final result = await EditStoryRoute(
          id: null,
          initialYear: DateTime.now().year,
          template: template,
        ).push(context);
        await _reloadHomeIfStoryCreated(result);
      case AppQuickActionTemplateType.gallery:
        final galleryTemplate = await _findGalleryTemplate(reference.id);
        if (galleryTemplate == null || !context.mounted) return;

        final result = await EditStoryRoute(
          id: null,
          initialYear: DateTime.now().year,
          galleryTemplate: galleryTemplate,
        ).push(context);
        await _reloadHomeIfStoryCreated(result);
    }
  }

  Future<void> _handleTagAction(AppQuickActionObject action, BuildContext context) async {
    final tagId = action.tagId;
    if (tagId == null) return;

    final tag = await TagDbModel.db.find(tagId);
    if (tag == null || !context.mounted) return;

    await ShowTagRoute(tag: tag, storyViewOnly: false).push(context);
  }

  Future<void> _openNewStory(BuildContext context) async {
    final homeContext = HomeView.homeContext;
    if (homeContext?.mounted == true) {
      await homeContext!.read<HomeViewModel>().goToNewPage(homeContext);
      return;
    }

    final result = await EditStoryRoute(id: null, initialYear: DateTime.now().year).push(context);
    await _reloadHomeIfStoryCreated(result);
  }

  Future<void> _takePhoto(BuildContext context) async {
    final homeContext = HomeView.homeContext;
    if (homeContext?.mounted == true) {
      homeContext!.read<HomeViewModel>().takePhoto(homeContext);
      return;
    }

    await SpAppLockWrapper.disableAppLockIfHas(
      context,
      callback: () async {
        final compression = context.read<DevicePreferencesProvider>().preferences.assetCompression;
        final photo = await AppFilePickerService.pickImage(source: ImageSource.camera, compression: compression);
        if (photo == null) return;

        final asset = await InsertFileToDbService.insertImage(photo, await photo.readAsBytes());
        if (asset == null || !context.mounted) return;

        AnalyticsService.instance.logTakePhoto();
        await _openStoryWithAsset(context, asset);
      },
    );
  }

  Future<void> _recordVoice(BuildContext context) async {
    final homeContext = HomeView.homeContext;
    if (homeContext?.mounted == true) {
      await homeContext!.read<HomeViewModel>().goToNewPageWithVoice(homeContext);
      return;
    }

    await SpAppLockWrapper.disableAppLockIfHas(
      context,
      callback: () async {
        final result = await const SpVoiceRecordingSheet().show(context: context);
        if (result is! VoiceRecordingResult) return;

        final asset = await InsertFileToDbService.insertAudio(
          result.filePath,
          await File(result.filePath).readAsBytes(),
          durationInMs: result.durationInMs,
        );
        if (asset == null || !context.mounted) return;

        await _openStoryWithAsset(context, asset);
      },
    );
  }

  Future<void> _openStoryWithAsset(BuildContext context, AssetDbModel asset) async {
    final result = await EditStoryRoute(
      id: null,
      initialYear: DateTime.now().year,
      initialAsset: asset,
    ).push(context);
    await _reloadHomeIfStoryCreated(result);
  }

  Future<void> _reloadHomeIfStoryCreated(Object? result) async {
    if (result is StoryDbModel) {
      await HomeView.reload(debugSource: '$runtimeType#_reloadHomeIfStoryCreated');
    }
  }

  Future<GalleryTemplateObject?> _findGalleryTemplate(String templateId) async {
    final templatesByCategory = await GalleryTemplateService.loadTemplates();
    for (final templates in templatesByCategory.values) {
      for (final template in templates) {
        if (template.id == templateId) return template;
      }
    }

    return null;
  }

  Future<BuildContext?> _waitForNavigatorContext(GlobalKey<NavigatorState> navigatorKey) async {
    for (int attempt = 0; attempt < 10; attempt++) {
      final context = navigatorKey.currentContext;
      if (context?.mounted == true) return context;

      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    return null;
  }

  Future<void> _ignoreMissingPlugin(Future<void> Function() callback) async {
    try {
      await callback();
    } on MissingPluginException {
      return;
    }
  }
}
