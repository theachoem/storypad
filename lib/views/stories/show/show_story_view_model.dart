import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/objects/story_page_objects_map.dart';
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
    if (story?.draftContent != null) lastSavedAtNotifier.value = story?.updatedAt;

    StoryContentDbModel content = story!.generateDraftContent();

    bool alreadyHasPage = content.richPages?.isNotEmpty == true;
    if (!alreadyHasPage) content = content.addRichPage(crossAxisCount: 2, mainAxisCount: 1);

    pagesManager.pagesMap = await StoryPageObjectsMap.fromContent(
      content: content,
      readOnly: readOnly,
    );

    // Copy with richPages from pagesManager instead, since DB-loaded pages have null plainText.
    // plainText is needed when saving back to draft content for homepage display & search.
    draftContent = content.copyWith(
      richPages: content.richPages?.map((e) => pagesManager.pagesMap[e.id]?.page ?? e).toList(),
    );

    // Save if detect data is invalid mostly from previous version before 2.12.3
    // No need to do following in edit story view.
    if (draftContent?.plainText != StoryContentDbModel.generatePlainText(draftContent?.richPages)) {
      draftContent = draftContent?.copyWith(plainText: StoryContentDbModel.generatePlainText(draftContent?.richPages));
      story = buildStory(draft: false);
      StoryDbModel.db.set(story!);
    }

    notifyListeners();
  }

  Future<void> goToEditPage(BuildContext context) async {
    if (draftContent == null || draftContent?.richPages == null) return;

    int? nearestPageIndex;
    double? initialPageScrollOffet;

    switch (story?.preferences.layoutType) {
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
      default:
        nearestPageIndex = pagesManager.pageController.page?.toInt();
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
}
