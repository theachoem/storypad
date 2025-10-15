import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/objects/story_page_objects_map.dart';
import 'package:storypad/core/services/stories/story_should_revert_change_service.dart';
import 'package:storypad/core/types/editing_flow_type.dart';
import 'package:storypad/views/stories/local_widgets/base_story_view_model.dart';
import 'edit_story_view.dart';

class EditStoryViewModel extends BaseStoryViewModel {
  final EditStoryRoute params;

  EditStoryViewModel({
    required this.params,
  }) : super(
         initialPageScrollOffet: params.initialPageScrollOffet,
         initialPageIndex: params.initialPageIndex,
       ) {
    init(
      initialStory: params.story,
      initialPagesMap: params.pagesMap,
    ).then((_) => requestFocus());
  }

  @override
  late final EditingFlowType flowType;

  // for for compare if after user edit end up same paragraph,
  // we need to revert back.
  StoryDbModel? initialStory;

  Future<void> init({
    StoryDbModel? initialStory,
    StoryPageObjectsMap? initialPagesMap,
  }) async {
    if (params.id != null) story = this.initialStory = initialStory ?? await StoryDbModel.db.find(params.id!);
    if (story?.draftContent != null) lastSavedAtNotifier.value = story?.updatedAt;

    flowType = story == null ? EditingFlowType.create : EditingFlowType.update;
    story ??= StoryDbModel.fromDate(
      openedOn,
      initialYear: params.initialYear,
      initialMonth: params.initialMonth,
      initialDay: params.initialDay,
      initialTagIds: params.initialTagIds,
      initialEventId: params.initialEventId,
      template: params.template,
    );

    StoryContentDbModel content = story!.generateDraftContent();
    bool alreadyHasPage = content.richPages?.isNotEmpty == true;
    if (!alreadyHasPage) content = content.addRichPage(crossAxisCount: 2, mainAxisCount: 1);

    pagesManager.pagesMap = await StoryPageObjectsMap.fromContent(
      content: content,
      readOnly: false,
      initialPagesMap: initialPagesMap,
    );

    // Copy with richPages from pagesManager instead, since DB-loaded pages have null plainText.
    // plainText is needed when saving back to draft content for homepage display & search.
    draftContent = content.copyWith(
      richPages: content.richPages?.map((e) => pagesManager.pagesMap[e.id]?.page ?? e).toList(),
    );

    if (params.initialAsset?.link != null) {
      final index = pagesManager.pagesMap.first.bodyController.selection.baseOffset;
      final length = pagesManager.pagesMap.first.bodyController.selection.extentOffset - index;
      pagesManager.pagesMap.first.bodyController.replaceText(
        index,
        length,
        BlockEmbed.image(params.initialAsset!.link),
        null,
      );
    }

    notifyListeners();
  }

  Future<void> done(BuildContext context) async {
    // Re-save without check to make sure draft content is removed. We will revert back if no change anyway.
    await _saveWithoutCheck();
    await _revertIfNoChange();

    // call pop instead of maybePop to skip pop scope
    if (context.mounted) Navigator.pop(context, story);
  }

  Future<void> _saveWithoutCheck() async {
    story ??= StoryDbModel.fromDate(
      openedOn,
      initialYear: params.initialYear,
      initialMonth: params.initialMonth,
      initialDay: params.initialDay,
      initialTagIds: params.initialTagIds,
    );

    story = buildStory(draft: false);
    await StoryDbModel.db.set(story!);
    lastSavedAtNotifier.value = story?.updatedAt;
  }

  Future<void> _revertIfNoChange() async {
    bool shouldRevert = await StoryShouldRevertChangeService.call(currentStory: story, initialStory: initialStory);
    if (shouldRevert) {
      debugPrint("Reverting story back... ${initialStory?.id}");

      story = initialStory;
      await StoryDbModel.db.set(initialStory!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }
  }

  void requestFocus() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool requested = false;

      for (StoryPageDbModel richPage in draftContent!.richPages!) {
        final page = pagesManager.pagesMap[richPage.id];

        // only focus when it is a selection (no tap)
        if (page != null &&
            (page.titleController.selection.baseOffset != page.titleController.selection.extentOffset)) {
          page.titleFocusNode.requestFocus();
          requested = true;
        }

        // only focus when it is a selection (no tap)
        if (page != null && (page.bodyController.selection.baseOffset != page.bodyController.selection.extentOffset)) {
          page.bodyFocusNode.requestFocus();
          requested = true;
        }
      }

      if (!requested && params.initialPageIndex != null) {
        final page = draftContent?.richPages?.elementAtOrNull(params.initialPageIndex ?? -1);
        if (page != null) {
          pagesManager.pagesMap[page.id]?.bodyFocusNode.requestFocus();
          requested = true;
        }
      }

      if (!requested) {
        pagesManager.pagesMap[draftContent!.richPages!.first.id]?.bodyFocusNode.requestFocus();
        requested = true;
      }
    });
  }

  Future<void> onPopInvokedWithResult(bool didPop, Object? _, BuildContext context) async {
    if (pagesManager.managingPage) return pagesManager.toggleManagingPage();
    if (didPop) return;

    Future<OkCancelResult> showDiscardConfirmation(BuildContext context) async {
      return showOkCancelAlertDialog(
        context: context,
        isDestructiveAction: true,
        title: tr("dialog.are_you_sure_to_discard_these_changes.title"),
        okLabel: tr("button.discard"),
      );
    }

    if (flowType == EditingFlowType.create) {
      if (lastSavedAtNotifier.value != null && story?.id != null) {
        OkCancelResult userAction = await showDiscardConfirmation(context);
        if (userAction == OkCancelResult.ok) {
          await StoryDbModel.db.delete(story!.id);
          story = null;
          if (context.mounted) return Navigator.of(context).pop(null);
        } else {
          return;
        }
      } else {
        if (context.mounted) Navigator.of(context).pop(null);
      }
    } else if (flowType == EditingFlowType.update) {
      if (story?.updatedAt != initialStory?.updatedAt) {
        OkCancelResult userAction = await showDiscardConfirmation(context);
        if (userAction == OkCancelResult.ok) {
          await StoryDbModel.db.set(initialStory!);
          story = initialStory;
          if (context.mounted) return Navigator.of(context).pop(null);
        }
      } else {
        if (context.mounted) Navigator.of(context).pop(null);
      }
    }
  }
}
