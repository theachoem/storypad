import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/analytics/adaptors/firebase_analytics_event_adaptor.dart';
import 'package:storypad/core/services/analytics/adaptors/none_analytics_event_adaptor.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';

abstract class BaseAnalyticsEventAdaptor {
  static BaseAnalyticsEventAdaptor create() {
    return (!kIsWeb && Platform.isLinux) ? NoneAnalyticsEventAdaptor() : FirebaseAnalyticsEventAdaptor();
  }

  // ---------------------------------------------------------------------------
  // Primitive methods — implement only these in subclasses
  // ---------------------------------------------------------------------------

  Future<void> logEvent(String name, {Map<String, Object>? parameters});

  Future<void> logScreenView({
    required String screenClass,
    required String screenName,
    Map<String, Object>? parameters,
  });

  Future<void> logLogin({required String loginMethod});

  Future<void> logSearchEvent({required String searchTerm});

  // ---------------------------------------------------------------------------
  // High-level methods — implemented once here, shared by all adaptors
  // ---------------------------------------------------------------------------

  Future<void> logViewRoute({
    required BaseRoute routeObject,
    Map<String, String?>? analyticsParameters,
  }) {
    return logScreenView(
      screenClass: routeObject.analyticScreenClass,
      screenName: routeObject.analyticScreenName,
      parameters: sanitizeParameters(analyticsParameters ?? {}),
    );
  }

  Future<void> logViewSheet({required BaseBottomSheet bottomSheet}) {
    return logScreenView(
      screenClass: bottomSheet.analyticScreenClass,
      screenName: bottomSheet.analyticScreenName,
    );
  }

  Future<void> logViewHome({required int year}) {
    return logScreenView(
      screenClass: 'HomeView',
      screenName: 'Home',
      parameters: sanitizeParameters({'year': year.toString()}),
    );
  }

  Future<void> logOpenHomeEndDrawer({required int year}) {
    return logScreenView(
      screenClass: 'HomeEndDrawer',
      screenName: 'HomeEndDrawer',
      parameters: sanitizeParameters({'year': year.toString()}),
    );
  }

  Future<void> logLicenseView() {
    return logScreenView(screenClass: 'LicensePage', screenName: 'License');
  }

  Future<void> logSearch({required String searchTerm}) {
    return logSearchEvent(searchTerm: searchTerm);
  }

  Future<void> logSyncBackup() => logEvent(sanitizeEventName('sync_backup'));

  Future<void> logImportOfflineBackup() => logEvent(sanitizeEventName('import_offline_backup'));

  Future<void> logExportOfflineBackup() => logEvent(sanitizeEventName('export_offline_backup'));

  Future<void> logRequestGoogleDriveScope() => logEvent(sanitizeEventName('request_google_drive_scope'));

  Future<void> logSignOut() => logEvent(sanitizeEventName('sign_out'));

  Future<void> logSignInWithGoogle() => logLogin(loginMethod: 'google');

  Future<void> logOpenLinkInCustomTab({required String url}) {
    return logEvent(sanitizeEventName('open_custom_tab'), parameters: sanitizeParameters({'url': url}));
  }

  Future<void> logLaunchUrl({required String url}) {
    return logEvent(sanitizeEventName('launch_url'), parameters: sanitizeParameters({'url': url}));
  }

  Future<void> logSubmitRedditPost({required String target}) {
    return logEvent(sanitizeEventName('submit_reddit_post'), parameters: sanitizeParameters({'target': target}));
  }

  Future<void> logDeleteCloudBackup({required CloudFileObject file}) {
    return logEvent(sanitizeEventName('delete_cloud_backup'));
  }

  Future<void> logDeleteAsset({required AssetDbModel asset}) {
    return logEvent(sanitizeEventName('delete_asset'));
  }

  Future<void> logForceRestoreBackup({required BackupFileObject backupFileInfo}) {
    return logEvent(
      sanitizeEventName('force_restore_backup'),
      parameters: sanitizeParameters({'version': backupFileInfo.version}),
    );
  }

  Future<void> logHardDeleteStory({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('hard_delete_story'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logUndoHardDeleteStory({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('undo_hard_delete_story'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logImportIndividualStory({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('import_story_individually'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logMoveStoryToBin({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('move_story_to_bin'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logUndoMoveStoryToBin({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('undo_move_story_to_bin'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logUndoPutBack({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('undo_put_back'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logArchiveStory({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('archive_story'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logUndoArchiveStory({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('undo_archive_story'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logChangeStoryDate({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('change_story_date'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logSaveStoryAsTemplate({
    required StoryDbModel story,
    required TemplateDbModel template,
  }) {
    return logEvent(sanitizeEventName('save_story_as_template'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logToggleStoryStarred({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('toggle_story_starred'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logToggleStoryPinned({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('toggle_story_pinned'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logReorderStoryPages({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('reorder_story_pages'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logAddStoryPage({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('add_story_page'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logDeleteStoryPage({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('delete_story_page'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logToggleShowDayCount({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('toggle_show_day_count'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logUpdateStoryPreferences({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('update_story_preferences'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logPutStoryBack({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('put_story_back'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logSetTagsToStory({
    required StoryDbModel story,
    int? topicTagsCount,
    int? peopleTagsCount,
    int? emojiTagsCount,
  }) {
    return logEvent(
      sanitizeEventName('set_tags_to_story'),
      parameters: storyAnalyticParameters(
        story,
        topicTagsCount: topicTagsCount,
        peopleTagsCount: peopleTagsCount,
        emojiTagsCount: emojiTagsCount,
      ),
    );
  }

  Future<void> logSetStoryFeeling({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('set_story_feeling'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logStorySaveDraft({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('story_save_draft'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logStoryContinueEdit({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('story_continue_edit'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logStoryViewPrevious({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('story_view_previous'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logStoryDiscardDraft({required StoryDbModel story}) {
    return logEvent(sanitizeEventName('story_discard_draft'), parameters: storyAnalyticParameters(story));
  }

  Future<void> logDeleteTag({required TagDbModel tag}) {
    return logEvent(sanitizeEventName('delete_tag'), parameters: tagAnalyticParameters(tag));
  }

  Future<void> logEditTag({required TagDbModel tag}) {
    return logEvent(sanitizeEventName('edit_tag'), parameters: tagAnalyticParameters(tag));
  }

  Future<void> logAddTag({required TagDbModel tag}) {
    return logEvent(sanitizeEventName('add_tag'), parameters: tagAnalyticParameters(tag));
  }

  // method: 'button' (tapped the Tags/People segment control).
  // Measures how often users switch into People mode in the picker.
  Future<void> logTagPickerPeopleModeEntered({required String method}) {
    return logEvent(
      sanitizeEventName('tag_picker_people_mode_entered'),
      parameters: sanitizeParameters({'method': method}),
    );
  }

  Future<void> logReorderTags({required CollectionDbModel<TagDbModel> tags}) {
    return logEvent(
      sanitizeEventName('reorder_tags'),
      parameters: sanitizeParameters({
        'count': tags.items.length.toString(),
        'category': tags.items.isEmpty ? null : tagCategoryLabel(tags.items.first),
      }),
    );
  }

  Future<void> logInsertNewPhoto() => logEvent(sanitizeEventName('insert_new_photo'));

  Future<void> logTakePhoto() => logEvent(sanitizeEventName('take_photo'));

  Future<void> logViewImages({required int imagesCount}) {
    return logEvent(
      sanitizeEventName('view_images'),
      parameters: sanitizeParameters({'images_count': imagesCount.toString()}),
    );
  }

  Future<void> logShareApp() => logEvent(sanitizeEventName('share_app'));

  Future<void> logShareStory({required String option}) {
    return logEvent(sanitizeEventName('share_story'), parameters: sanitizeParameters({'option': option}));
  }

  Future<void> logClearPIN() => logEvent(sanitizeEventName('clear_pin'));

  Future<void> logSetPIN() => logEvent(sanitizeEventName('set_pin'));

  Future<void> logUseGalleryTemplate({
    required String templateId,
    required String source,
  }) {
    return logEvent(
      'use_gallery_template',
      parameters: sanitizeParameters({'template_id': templateId, 'source': source}),
    );
  }

  Future<void> logPutBackAllStories({required int count}) {
    return logEvent(
      sanitizeEventName('put_back_all_stories'),
      parameters: sanitizeParameters({'count': count.toString()}),
    );
  }

  Future<void> logMoveAllStoriesToBin({required int count}) {
    return logEvent(
      sanitizeEventName('move_all_stories_to_bin'),
      parameters: sanitizeParameters({'count': count.toString()}),
    );
  }

  Future<void> logUnpinAllStories({required int count}) {
    return logEvent(
      sanitizeEventName('unpin_all_stories'),
      parameters: sanitizeParameters({'count': count.toString()}),
    );
  }

  Future<void> logPinAllStories({required int count}) {
    return logEvent(sanitizeEventName('pin_all_stories'), parameters: sanitizeParameters({'count': count.toString()}));
  }

  Future<void> logArchiveAllStories({required int count}) {
    return logEvent(
      sanitizeEventName('archive_all_stories'),
      parameters: sanitizeParameters({'count': count.toString()}),
    );
  }

  Future<void> logPermanentDeleteAllStories({required int count}) {
    return logEvent(
      sanitizeEventName('permanent_delete_all_stories'),
      parameters: sanitizeParameters({'count': count.toString()}),
    );
  }

  Future<void> logQuickActionLaunched({required String type, String? action}) {
    return logEvent(
      sanitizeEventName('quick_action_launched'),
      parameters: sanitizeParameters({'type': type, 'action': action}),
    );
  }

  Future<void> logQuickActionAdded({required String type}) {
    return logEvent(sanitizeEventName('quick_action_added'), parameters: sanitizeParameters({'type': type}));
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  Map<String, Object>? storyAnalyticParameters(
    StoryDbModel story, {
    int? topicTagsCount,
    int? peopleTagsCount,
    int? emojiTagsCount,
  }) {
    return sanitizeParameters({
      'version': story.version.toString(),
      'type': story.type.name,
      'starred': ?story.starred?.toString(),
      'year': story.year.toString(),
      'month': story.month.toString(),
      'day': story.day.toString(),
      'pinned': ?story.pinned?.toString(),
      'gallery_template_id': ?story.galleryTemplateId,
      'pages_count': (story.draftContent?.id != null ? story.draftContent : story.latestContent)?.richPages?.length
          .toString(),
      'draft_saved': story.draftContent?.id != null ? 'true' : 'false',
      'preferred_show_day_count': story.preferences.showDayCount?.toString(),
      'tags_count': ?story.tags?.length.toString(),
      'topic_tags_count': ?topicTagsCount?.toString(),
      'people_tags_count': ?peopleTagsCount?.toString(),
      'emoji_tags_count': ?emojiTagsCount?.toString(),
    });
  }

  // Categorical/numeric only — never the tag title (tag and person names are user PII).
  Map<String, Object>? tagAnalyticParameters(TagDbModel tag) => sanitizeParameters({
    'category': tagCategoryLabel(tag),
    'has_emoji': (tag.emoji != null).toString(),
  });

  // 'emoji' (Feeling/Activity/Weather), 'people', or 'topic' (regular tags).
  String tagCategoryLabel(TagDbModel tag) => tag.emoji != null ? 'emoji' : (tag.isPerson ? 'people' : 'topic');

  /// Validates and returns [name]. Firebase event names must be 1–40 alphanumeric/underscore
  /// characters, start with a letter, and not use reserved prefixes.
  String sanitizeEventName(String name) {
    assert(name.length <= 40);
    assert(!name.startsWith('firebase_'));
    assert(!name.startsWith('google_'));
    assert(!name.startsWith('ga_'));
    return name;
  }

  /// Filters out null values and coerces numeric strings to [num].
  Map<String, Object>? sanitizeParameters(Map<String, String?> parameters) {
    final filtered = <String, Object>{};
    parameters.forEach((key, value) {
      if (value != null) filtered[key] = num.tryParse(value) ?? value;
    });
    if (filtered.isEmpty) return null;
    return filtered;
  }

  void debug(String logMethod, [Map<String, Object>? printData]) {
    if (printData != null) {
      debugPrint('🎯 $runtimeType#$logMethod -> $printData');
    } else {
      debugPrint('🎯 $runtimeType#$logMethod');
    }
  }
}
