import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/mixins/list_reorderable.dart';
import 'package:storypad/core/objects/story_page_objects_map.dart';
import 'package:storypad/core/services/stories/story_has_data_written_service.dart';
import 'package:storypad/core/types/editing_flow_type.dart';
import 'package:storypad/views/stories/local_widgets/base_story_view_model.dart';

import 'edit_template_view.dart';

class EditTemplateViewModel extends ChangeNotifier with DisposeAwareMixin, DebounchedCallback {
  final EditTemplateRoute params;

  EditTemplateViewModel({
    required this.params,
  }) {
    template = params.initialTemplate;
    flowType = template == null ? EditingFlowType.create : EditingFlowType.update;

    template ??= TemplateDbModel(
      id: openedOn.millisecondsSinceEpoch,
      tags: [],
      content: null,
      createdAt: openedOn,
      updatedAt: openedOn,
      archivedAt: null,
      lastSavedDeviceId: null,
      permanentlyDeletedAt: null,
    );

    latestContent = template?.content ?? StoryContentDbModel.create(createdAt: openedOn);
    draftContent = template?.content ?? StoryContentDbModel.create(createdAt: openedOn);

    bool alreadyHasPage = draftContent!.richPages?.isNotEmpty == true;
    if (!alreadyHasPage) draftContent = draftContent!.addRichPage(crossAxisCount: 2, mainAxisCount: 1);

    pagesManager = StoryPagesManagerInfo(
      initialPageIndex: 0,
      initialScrollOffset: 0.0,
      draftContent: () => draftContent,
      notifyListeners: notifyListeners,
    );

    load();
  }

  TemplateDbModel? template;
  StoryContentDbModel? draftContent;
  StoryContentDbModel? latestContent;

  final ValueNotifier<DateTime?> lastSavedAtNotifier = ValueNotifier(null);
  late final StoryPagesManagerInfo pagesManager;
  late EditingFlowType flowType;
  final DateTime openedOn = DateTime.now();

  Future<void> load() async {
    pagesManager.pagesMap = await StoryPageObjectsMap.fromContent(
      content: draftContent!,
      readOnly: false,
      initialPagesMap: null,
    );
    notifyListeners();
  }

  void addNewPage() {
    HapticFeedback.selectionClick();

    draftContent = draftContent!.addRichPage(crossAxisCount: 2, mainAxisCount: 1);
    pagesManager.pagesMap.add(richPage: draftContent!.richPages!.last, readOnly: false);

    if (hasDataWritten) {
      template = template!.copyWith(content: draftContent, updatedAt: DateTime.now());
      lastSavedAtNotifier.value = DateTime.now();
      TemplateDbModel.db.set(template!);
    }

    notifyListeners();

    if (pagesManager.pageScrollController.hasClients) {
      pagesManager.scrollToPage(draftContent!.richPages!.last.id);
    } else if (pagesManager.pageController.hasClients) {
      pagesManager.pageController.animateToPage(
        draftContent!.richPages!.length - 1,
        duration: Durations.long4,
        curve: Curves.fastLinearToSlowEaseIn,
      );
    }
  }

  Future<void> swapPages({
    required int oldIndex,
    required int newIndex,
  }) async {
    List<StoryPageDbModel> pages = [
      ...draftContent?.richPages ?? <StoryPageDbModel>[],
    ].swap(oldIndex: oldIndex, newIndex: newIndex);

    draftContent = draftContent!.copyWith(
      title: pages.first.title,
      plainText: pages.first.plainText,
      richPages: pages,
    );

    if (hasDataWritten) {
      template = template!.copyWith(content: draftContent, updatedAt: DateTime.now());
      lastSavedAtNotifier.value = DateTime.now();
      TemplateDbModel.db.set(template!);
    }

    notifyListeners();

    if (!pagesManager.managingPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pagesManager.pageScrollController.hasClients) {
          pagesManager.scrollToPage(pages[newIndex].id);
        }
      });
    }
  }

  Future<void> deleteAPage(BuildContext context, StoryPageDbModel richPage) async {
    if (!pagesManager.canDeletePage) return;

    final result = await showOkCancelAlertDialog(
      title: tr("dialog.are_you_sure_to_delete_this_page.title"),
      context: context,
      okLabel: tr("button.delete"),
      isDestructiveAction: true,
    );

    if (result == OkCancelResult.ok) {
      draftContent = draftContent!.removeRichPage(richPage.id);
      pagesManager.pagesMap.remove(richPage.id);

      if (hasDataWritten) {
        template = template!.copyWith(content: draftContent, updatedAt: DateTime.now());
        lastSavedAtNotifier.value = DateTime.now();
        TemplateDbModel.db.set(template!);
      }

      notifyListeners();
    }
  }

  Future<void> onPageChanged(StoryPageDbModel richPage) async {
    draftContent = draftContent!.replacePage(richPage);
    pagesManager.pagesMap[richPage.id]?.page = richPage;

    return debouncedCallback(() async {
      if (hasChange) {
        template = template!.copyWith(content: draftContent, updatedAt: DateTime.now());
        lastSavedAtNotifier.value = DateTime.now();
        await TemplateDbModel.db.set(template!);
      }
    });
  }

  Future<bool> setTags(List<int> tags) async {
    template = template!.copyWith(tags: tags, updatedAt: DateTime.now());
    notifyListeners();

    if (hasDataWritten) {
      lastSavedAtNotifier.value = DateTime.now();
      TemplateDbModel.db.set(template!);
    }

    return true;
  }

  Future<void> changePreferences(StoryPreferencesDbModel preferences) async {
    if (preferences.layoutType != template?.preferences.layoutType) {
      pagesManager.currentPageIndexNotifier.value = null;

      if (pagesManager.pageController.hasClients) pagesManager.pageController.jumpToPage(0);
      if (pagesManager.pageScrollController.hasClients) pagesManager.pageScrollController.jumpTo(0);
    }

    template = template!.copyWith(updatedAt: DateTime.now(), preferences: preferences);
    notifyListeners();

    if (hasDataWritten) {
      await TemplateDbModel.db.set(template!);
      lastSavedAtNotifier.value = DateTime.now();
    }
  }

  void done(BuildContext context) {
    Navigator.maybePop(context, template);
  }

  bool get hasDataWritten =>
      flowType == EditingFlowType.update || StoryHasDataWrittenService.callByContent(draftContent!);

  bool get hasChange {
    if (draftContent == null) return false;
    if (latestContent == null) return false;

    // when not ignore empty & no data written, consider not changed.
    if (flowType == EditingFlowType.create && !StoryHasDataWrittenService.callByContent(draftContent!)) return false;
    return draftContent!.hasChanges(latestContent!);
  }

  @override
  void dispose() {
    pagesManager.dispose();
    super.dispose();
  }
}
