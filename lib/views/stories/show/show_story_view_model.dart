import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/initializers/database_initializer.dart';
import 'package:storypad/core/objects/story_page_objects_map.dart';
import 'package:storypad/core/services/stories/story_content_embed_extractor.dart';
import 'package:storypad/core/types/page_layout_type.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/views/stories/local_widgets/base_story_view_model.dart';
import 'show_story_view.dart';

class ShowStoryViewModel extends BaseStoryViewModel {
  final ShowStoryRoute params;

  @override
  bool get readOnly => true;

  ShowStoryViewModel({
    required this.params,
  }) {
    load(initialStory: params.story);
  }

  Future<void> load({
    StoryDbModel? initialStory,
  }) async {
    story = initialStory ?? await StoryDbModel.db.find(params.id);
    story = await _migrateEmbedAssetsToRelativeFilePathIfExists(story);
    if (story?.draftContent != null) lastSavedAtNotifier.value = story?.updatedAt;

    StoryContentDbModel content = story!.generateDraftContent();
    bool alreadyHasPage = content.richPages?.isNotEmpty == true;
    if (!alreadyHasPage) content = content.addRichPage();

    pagesManager.pagesMap = await StoryPageObjectsMap.fromContent(
      content: content,
      readOnly: readOnly,
    );

    // Copy with richPages from pagesManager instead, since DB-loaded pages have null plainText.
    // plainText is needed when saving back to draft content for homepage display & search.
    draftContent = content.copyWith(
      richPages: content.richPages?.map((e) => pagesManager.pagesMap[e.id]?.page ?? e).toList(),
    );

    // Save if detect data is invalid mostly from previous version before 2.12.3 (plainText), 2.23.0 (count)
    // No need to do following in edit story view.
    if (draftContent?.plainText != content.plainText ||
        draftContent?.characterCount != content.characterCount ||
        draftContent?.wordCount != content.wordCount) {
      // Keep updatedAt same as before since this is just a silent fix. User didn't explicitly make change.
      story = buildStory(draft: story?.draftStory == true, updatedAt: story?.updatedAt);
      StoryDbModel.db.set(story!, runCallbacks: false);
    }

    notifyListeners();
  }

  Future<void> goToEditPage(BuildContext context) async {
    if (draftContent == null || draftContent?.richPages == null) return;

    int? nearestPageIndex;
    double? initialPageScrollOffet;

    switch (story?.preferences.layoutType) {
      case PageLayoutType.grid:
      case PageLayoutType.list:
        initialPageScrollOffet = pagesManager.pageScrollController.offset;

        for (int index = 0; index < (draftContent?.richPages?.length ?? 0); index++) {
          int pageId = draftContent!.richPages![index].id;
          if (pagesManager.pagesMap[pageId]?.titleVisibleFraction == 1) {
            nearestPageIndex = index;
            break;
          }
        }

        // if no title visible on page, it most likely an last page.
        nearestPageIndex ??= draftContent!.richPages!.length - 1;
        break;
      case PageLayoutType.pages:
        nearestPageIndex = pagesManager.pageController.page?.toInt();
        break;
      case null:
        break;
    }

    await EditStoryRoute(
      id: story!.id,
      story: story,
      initialPageIndex: nearestPageIndex,
      initialPageScrollOffet: initialPageScrollOffet ?? 0,
      pagesMap: pagesManager.pagesMap,
    ).push(context);

    await load();
  }

  Future<void> done(BuildContext context) async {
    story = buildStory(draft: false);
    await StoryDbModel.db.set(story!);
    lastSavedAtNotifier.value = story?.updatedAt;
    notifyListeners();
  }

  @override
  Future<void> onPageChanged(StoryPageDbModel richPage) async {
    // unlike edit view, we can notify UI on each change, and won't need to use debounce callback here.

    draftContent = draftContent!.replacePage(richPage);
    pagesManager.pagesMap[richPage.id]?.page = richPage;

    await saveDraft(debugSource: '$runtimeType#onPageChanged');
    notifyListeners();
  }

  Future<void> onPopInvokedWithResult(bool didPop, Object? result, BuildContext context) async {
    if (pagesManager.managingPage) return pagesManager.toggleManagingPage();
  }

  void handleKeyEvent(KeyEvent event, BuildContext context) {
    if (event is KeyDownEvent) {
      final isE = event.logicalKey == LogicalKeyboardKey.enter;

      if (isE) {
        goToEditPage(context);
      }
    }
  }

  // Migrate legacy embed asset paths (storypad://assets/xxx) to the new relative file paths if they still exist.
  //
  // This migration was originally performed in database_initializer.dart#migrateEmbedAssetsToUseRelativeFilePaths.
  // However, some edge cases may leave certain stories with the old embed
  // asset paths (for example, stories that were missed during the initial migration).
  //
  // This function acts as a safety net to ensure those remaining stories
  // are migrated properly when they are accessed.
  Future<StoryDbModel?> _migrateEmbedAssetsToRelativeFilePathIfExists(StoryDbModel? story) async {
    if (story == null) return null;

    List<String>? assetPaths = story.draftContent != null || story.latestContent != null
        ? StoryContentEmbedExtractor.images(story.draftContent ?? story.latestContent)
        : null;

    const String legacyPrefix = 'storypad://assets/';
    Set<int>? needMigrationAssetIds = assetPaths
        ?.where((a) => a.contains(legacyPrefix))
        .map((a) => int.tryParse(a.replaceAll(legacyPrefix, '')))
        .whereType<int>()
        .toSet();

    if (needMigrationAssetIds != null && needMigrationAssetIds.isNotEmpty) {
      await DatabaseInitializer.migrateEmbedAssetsToUseRelativeFilePaths(assetIds: needMigrationAssetIds.toList());
      debugPrint('Migrated ${needMigrationAssetIds.length} to latest for story: ${story.id}');
      return StoryDbModel.db.find(params.id);
    }

    return story;
  }
}
