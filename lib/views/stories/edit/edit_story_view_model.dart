import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/objects/default_story_preferences_object.dart';
import 'package:storypad/core/objects/story_page_objects_map.dart';
import 'package:storypad/core/services/stories/story_convert_legacy_pages_service.dart';
import 'package:storypad/core/services/stories/story_should_revert_change_service.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/core/types/editing_flow_type.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/views/stories/local_widgets/base_story_view_model.dart';
import 'edit_story_view.dart';

class EditStoryViewModel extends BaseStoryViewModel {
  final EditStoryRoute params;

  @override
  bool get readOnly => false;

  EditStoryViewModel({
    required this.params,
    required BuildContext context,
  }) : super(
         initialPageScrollOffet: params.initialPageScrollOffet,
         initialPageIndex: params.initialPageIndex,
       ) {
    init(
      initialStory: params.story,
      initialPagesMap: params.pagesMap,
      defaultStoryPreferences: context.read<DevicePreferencesProvider>().preferences.defaultStoryPreferences,
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
    DefaultStoryPreferencesObject? defaultStoryPreferences,
  }) async {
    story = this.initialStory = initialStory;

    if (params.id != null) story = this.initialStory = initialStory ?? await StoryDbModel.db.find(params.id!);

    // Set before any further await: the view (e.g. the Done button) reads it on the next frame.
    flowType = story == null ? EditingFlowType.create : EditingFlowType.update;

    if (story != null) story = this.initialStory = await StoryConvertLegacyPagesService.call(story);
    if (story?.draftContent != null) lastSavedAtNotifier.value = story?.updatedAt;
    story ??= StoryDbModel.fromDate(
      openedOn,
      initialYear: params.initialYear,
      initialMonth: params.initialMonth,
      initialDay: params.initialDay,
      initialTagIds: params.initialTagIds,
      galleryTemplate: params.galleryTemplate,
      template: params.template,
      defaultStoryPreferences: defaultStoryPreferences,
    );

    StoryContentDbModel content = story!.generateDraftContent();
    bool alreadyHasPage = content.richPages?.isNotEmpty == true;
    if (!alreadyHasPage) content = content.addRichPage();

    final pagesMap = await StoryPageObjectsMap.fromContent(
      content: content,
      readOnly: readOnly,
      initialPagesMap: initialPagesMap,
    );
    // Left while the pages were being built (e.g. back right after starting a story from a photo): nothing to edit or
    // save, not even the photo.
    if (disposed) {
      pagesMap.dispose();
      return;
    }
    pagesManager.pagesMap = pagesMap;
    // Every edit starts a save, also one to a page whose editor is off screen.
    pagesManager.pagesMap.onEdited = onPageChanged;

    // The pages as the editors hold them (their counts computed), and the title worked out from them: a content built
    // elsewhere may lack it (e.g. a story made from a template before titles were set there).
    final pages = [
      for (final page in content.richPages ?? <StoryPageDbModel>[]) pagesManager.pagesMap[page.id]?.page ?? page,
    ];
    draftContent = content.copyWith(title: pages.firstOrNull?.title, richPages: pages);

    if (params.initialAsset?.relativeLocalFilePath != null) {
      final asset = params.initialAsset!;
      final controller = pagesManager.pagesMap.first.bodyController;
      // At the caret: the page's start for a new story.
      controller.selection = TextSelection.collapsed(offset: controller.selection.baseOffset);
      final path = asset.relativeLocalFilePath;
      asset.type == AssetType.audio ? controller.insertAudio(path) : controller.insertMedia([path]);
    }

    notifyListeners();

    if (params.autoRequestLocation) {
      await addCurrentLocation();
    }
  }

  Future<void> done(BuildContext context) async {
    // Still opening (Cmd+S before the pages are built): there's nothing to save yet.
    if (draftContent == null) return;
    // Saved right here, with every edit -- a debounced save still pending would only repeat it.
    cancelTimer(null);
    // A new story with nothing written and nothing saved yet has no Done button; Cmd+S there just leaves, as back does,
    // rather than saving an empty story.
    if (flowType == EditingFlowType.create && lastSavedAtNotifier.value == null && !hasDataWritten) {
      if (context.mounted) Navigator.pop(context, null);
      return;
    }
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

  void handleKeyEvent(KeyEvent event, BuildContext context) {
    if (event is KeyDownEvent) {
      final isCtrlOrCmd =
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlLeft) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlRight) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.metaLeft) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.metaRight);

      final isS = event.logicalKey == LogicalKeyboardKey.keyS;

      if (isCtrlOrCmd && isS) {
        done(context);
      }
    }
  }

  Future<void> onPopInvokedWithResult(bool didPop, Object? _, BuildContext context) async {
    if (pagesManager.managingPage) return pagesManager.toggleManagingPage();
    if (didPop) return;

    // Edits from the last moment count as saved changes: asked about like any other.
    await flushPendingSave(debugSource: '$runtimeType#onPopInvokedWithResult');
    if (!context.mounted) return;

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
          await StoryDbModel.db.delete(story!.id, softDelete: false);
          story = null;
          if (context.mounted && ModalRoute.of(context)?.isCurrent == true) return Navigator.of(context).pop(null);
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
          if (context.mounted && ModalRoute.of(context)?.isCurrent == true) return Navigator.of(context).pop(null);
        }
      } else {
        if (context.mounted) Navigator.of(context).pop(null);
      }
    }
  }
}
