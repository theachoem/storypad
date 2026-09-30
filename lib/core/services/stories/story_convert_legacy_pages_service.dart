import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';

/// Converts a story's (or template's) legacy pages -- a separate title and a Quill body -- to Markdown when it's
/// opened, and saves the result quietly: same `updatedAt`, no listeners, so it's neither an edit nor a sync trigger.
/// Every device converts the same way, so a story left unedited reads the same everywhere.
///
/// Nothing is saved unless every page, in both the latest and the draft content, converts losslessly (see
/// [StoryContentDbModel.convertLegacyPages]); the story then opens as stored and is converted in memory only.
///
/// Only records in the database are converted: one that isn't there (e.g. shown from a backup), or that changed since
/// it was loaded, is returned as given.
class StoryConvertLegacyPagesService {
  static Future<StoryDbModel?> call(StoryDbModel? story) async {
    if (story == null || !story.editable) return story;

    final contents = convertContents(latest: story.latestContent, draft: story.draftContent);
    if (contents == null) return story;

    final stored = await StoryDbModel.db.find(story.id, returnDeleted: true);
    if (stored == null || stored.updatedAt != story.updatedAt) return story;

    final converted = stored.copyWith(latestContent: contents.latest, draftContent: contents.draft);
    // A format change only: no callbacks (not an edit, not a sync trigger), and the assets' tags can't have changed.
    await StoryDbModel.db.set(
      converted,
      runCallbacks: false,
      retagAssets: false,
      debugSource: 'StoryConvertLegacyPagesService',
    );
    return converted;
  }

  static Future<TemplateDbModel> template(TemplateDbModel template) async {
    final contents = convertContents(latest: template.content, draft: null);
    if (contents == null) return template;

    final stored = await TemplateDbModel.db.find(template.id, returnDeleted: true);
    if (stored == null || stored.updatedAt != template.updatedAt) return template;

    final converted = stored.copyWith(content: contents.latest);
    await TemplateDbModel.db.set(converted, runCallbacks: false, debugSource: 'StoryConvertLegacyPagesService');
    return converted;
  }

  /// Both contents converted, or `null` when there's nothing to convert or either would lose something -- they're
  /// converted together or not at all, so a draft still compares with its latest content.
  @visibleForTesting
  static ({StoryContentDbModel? latest, StoryContentDbModel? draft})? convertContents({
    required StoryContentDbModel? latest,
    required StoryContentDbModel? draft,
  }) {
    final latestHasLegacy = latest?.hasLegacyPages == true;
    final draftHasLegacy = draft?.hasLegacyPages == true;
    if (!latestHasLegacy && !draftHasLegacy) return null;

    final convertedLatest = latestHasLegacy ? latest!.convertLegacyPages() : latest;
    final convertedDraft = draftHasLegacy ? draft!.convertLegacyPages() : draft;
    if (latestHasLegacy && convertedLatest == null) return null;
    if (draftHasLegacy && convertedDraft == null) return null;

    return (latest: convertedLatest, draft: convertedDraft);
  }
}
