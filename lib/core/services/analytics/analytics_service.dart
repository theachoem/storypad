import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/analytics/base_analytics_service.dart';
import 'package:storypad/routes/base_route.dart';

// Logging analytics events without user-identifiable information.
class AnalyticsService extends BaseAnalyticsService {
  AnalyticsService._();
  static AnalyticsService get instance => AnalyticsService._();

  Future<void> logViewRoute({
    required BaseRoute routeObject,
    Map<String, String?>? analyticsParameters,
  }) {
    String screenName = routeObject.analyticScreenName;
    String screenClass = routeObject.analyticScreenClass;
    Map<String, Object>? parameters = sanitizeParameters(analyticsParameters ?? {});

    debug(
      'logViewRoute',
      {'screen_name': screenName, 'screen_class': screenClass, ...parameters ?? {}},
    );

    return FirebaseAnalytics.instance.logScreenView(
      screenClass: screenClass,
      screenName: screenName,
      parameters: parameters,
    );
  }

  Future<void> logViewHome({
    required int year,
  }) {
    final parameters = sanitizeParameters({'year': year.toString()});
    debug('logViewHome', parameters);

    return FirebaseAnalytics.instance.logScreenView(
      screenClass: 'HomeView',
      screenName: 'Home',
      parameters: parameters,
    );
  }

  Future<void> logOpenHomeEndDrawer({
    required int year,
  }) {
    final parameters = sanitizeParameters({'year': year.toString()});
    debug('logOpenHomeEndDrawer', parameters);

    return FirebaseAnalytics.instance.logScreenView(
      screenClass: 'HomeEndDrawer',
      screenName: 'HomeEndDrawer',
      parameters: parameters,
    );
  }

  Future<void> logLicenseView() {
    debug('logLicenseView');

    return FirebaseAnalytics.instance.logScreenView(
      screenClass: 'LicensePage',
      screenName: 'License',
      parameters: null,
    );
  }

  Future<void> logSearch({
    required String searchTerm,
  }) {
    debug('logSearch', {
      'searchTerm': searchTerm,
    });

    return FirebaseAnalytics.instance.logSearch(
      searchTerm: searchTerm,
    );
  }

  Future<void> logSyncBackup() {
    debug('logSyncBackup');

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('sync_backup'),
    );
  }

  Future<void> logImportOfflineBackup() {
    debug('logImportOfflineBackup');

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('import_offline_backup'),
    );
  }

  Future<void> logExportOfflineBackup() {
    debug('logExportOfflineBackup');

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('export_offline_backup'),
    );
  }

  Future<void> logSignOut() {
    debug('logSignOut');
    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('sign_out'),
    );
  }

  Future<void> logSignInWithGoogle() {
    debug('logSignInWithGoogle');
    return FirebaseAnalytics.instance.logLogin(
      loginMethod: 'google',
    );
  }

  Future<void> logOpenLinkInCustomTab({
    required String url,
  }) {
    final parameters = sanitizeParameters({'url': url});
    debug('logOpenLinkInCustomTab', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('open_custom_tab'),
      parameters: parameters,
    );
  }

  Future<void> logLaunchUrl({
    required String url,
  }) {
    final parameters = sanitizeParameters({'url': url});
    debug('logLaunchUrl', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('launch_url'),
      parameters: parameters,
    );
  }

  Future<void> logDeleteCloudFile({
    required CloudFileObject cloudFile,
  }) {
    final parameters = sanitizeParameters({'version': cloudFile.getFileInfo()?.version});
    debug('logDeleteCloudFile', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('delete_cloud_file'),
      parameters: parameters,
    );
  }

  Future<void> logForceRestoreBackup({
    required BackupFileObject backupFileInfo,
  }) {
    final parameters = sanitizeParameters({'version': backupFileInfo.version});
    debug('logForceRestoreBackup', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('force_restore_backup'),
      parameters: parameters,
    );
  }

  Future<void> logHardDeleteStory({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logHardDeleteStory', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('hard_delete_story'),
      parameters: parameters,
    );
  }

  Future<void> logUndoHardDeleteStory({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logUndoHardDeleteStory', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('undo_hard_delete_story'),
      parameters: parameters,
    );
  }

  Future<void> logImportIndividualStory({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logImportIndividualStory', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('import_story_individually'),
      parameters: parameters,
    );
  }

  Future<void> logMoveStoryToBin({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logMoveStoryToBin', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('move_story_to_bin'),
      parameters: parameters,
    );
  }

  Future<void> logUndoMoveStoryToBin({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logUndoMoveStoryToBin', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('undo_move_story_to_bin'),
      parameters: parameters,
    );
  }

  Future<void> logUndoPutBack({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logUndoPutBack', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('undo_put_back'),
      parameters: parameters,
    );
  }

  Future<void> logArchiveStory({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logArchiveStory', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('archive_story'),
      parameters: parameters,
    );
  }

  Future<void> logUndoArchiveStory({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logUndoArchiveStory', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('undo_archive_story'),
      parameters: parameters,
    );
  }

  Future<void> logChangeStoryDate({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logChangeStoryDate', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('change_story_date'),
      parameters: parameters,
    );
  }

  Future<void> logToggleStoryStarred({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logToggleStoryStarred', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('toggle_story_starred'),
      parameters: parameters,
    );
  }

  Future<void> logUpdateStarIcon({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logUpdateStarIcon', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('update_star_icon'),
      parameters: parameters,
    );
  }

  Future<void> logToggleShowDayCount({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logToggleShowDayCount', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('toggle_show_day_count'),
      parameters: parameters,
    );
  }

  Future<void> logPutStoryBack({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logPutStoryBack', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('put_story_back'),
      parameters: parameters,
    );
  }

  Future<void> logSetStoryFeeling({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logSetStoryFeeling', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('set_story_feeling'),
      parameters: parameters,
    );
  }

  Future<void> logRestoreStoryChange({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logRestoreStoryChange', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('set_story_feeling'),
      parameters: parameters,
    );
  }

  Future<void> logRemoveStoryChanges({
    required StoryDbModel story,
  }) {
    final parameters = storyAnalyticParameters(story);
    debug('logRemoveStoryChanges', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('remove_story_changes'),
      parameters: parameters,
    );
  }

  Future<void> logDeleteTag({
    required TagDbModel tag,
  }) {
    final parameters = tagAnalyticParameters(tag);
    debug('logDeleteTag', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('delete_tag'),
      parameters: parameters,
    );
  }

  Future<void> logEditTag({
    required TagDbModel tag,
  }) {
    final parameters = tagAnalyticParameters(tag);
    debug('logEditTag', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('edit_tag'),
      parameters: parameters,
    );
  }

  Future<void> logAddTag({
    required TagDbModel tag,
  }) {
    final parameters = tagAnalyticParameters(tag);
    debug('logAddTag', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('add_tag'),
      parameters: parameters,
    );
  }

  Future<void> logReorderTags({
    required CollectionDbModel<TagDbModel> tags,
  }) {
    debug('logReorderTags');
    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('reorder_tags'),
    );
  }

  Future<void> logInsertNewPhoto() {
    debug('logInsertNewPhoto');
    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('insert_new_photo'),
    );
  }

  Future<void> logViewImages({
    required int imagesCount,
  }) {
    final parameters = sanitizeParameters({'images_count': imagesCount.toString()});
    debug('logViewImages', parameters);

    return FirebaseAnalytics.instance.logEvent(
      name: sanitizeEventName('view_images'),
      parameters: parameters,
    );
  }

  Map<String, Object>? storyAnalyticParameters(StoryDbModel story) {
    return sanitizeParameters({
      'type': story.type.name,
      'starred': story.starred.toString(),
      'year': story.year.toString(),
      'month': story.month.toString(),
      'day': story.day.toString(),
      'feeling': story.feeling,
      'total_changes': story.rawChanges?.length.toString(),
      'preferred_star_icon': story.preferences?.starIcon,
      'preferred_show_day_count': story.preferences?.showDayCount?.toString(),
    });
  }

  // No tags data is needed for analytics.
  Map<String, Object>? tagAnalyticParameters(TagDbModel tag) {
    return sanitizeParameters({});
  }

  /// The [name] of the event. Should contain 1 to 40 alphanumeric characters or underscores.
  /// The name must start with an alphabetic character. Some event names are reserved.
  /// See FirebaseAnalytics.Event for the list of reserved event names.
  /// The "firebase_", "google_" and "ga_" prefixes are reserved and should not be used.
  /// Note that event names are case-sensitive and that logging two events whose names differ only in case will result in two distinct events.
  String sanitizeEventName(String name) {
    assert(name.length <= 40);

    assert(!name.startsWith('firebase_'));
    assert(!name.startsWith('google_'));
    assert(!name.startsWith('ga_'));

    return name;
  }

  Map<String, Object>? sanitizeParameters(Map<String, String?> parameters) {
    final Map<String, Object> filtered = <String, Object>{};

    parameters.forEach((String key, String? value) {
      if (value != null) {
        filtered[key] = num.tryParse(value) ?? value;
      }
    });

    if (filtered.isEmpty) return null;
    return filtered;
  }
}
