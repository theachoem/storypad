import 'dart:math';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/base/base_view_model.dart';
import 'package:storypad/core/databases/legacy/storypad_legacy_database.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/analytics_service.dart';
import 'package:storypad/core/services/in_app_review_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/services/restore_backup_service.dart';
import 'package:storypad/core/storages/new_stories_count_storage.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/home/local_widgets/nickname_bottom_sheet.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/views/stories/show/show_story_view.dart';

part './local_widgets/home_scroll_info.dart';

class HomeViewModel extends BaseViewModel {
  late final scrollInfo = _HomeScrollInfo(viewModel: () => this);

  HomeViewModel(BuildContext context) {
    AnalyticsService.instance.logViewHome(year: year);

    _construct(context);
  }

  Future<void> _construct(BuildContext context) async {
    nickname = PreferenceDbModel.db.nickname.get();
    await loadFromLegacyStorypadIfShould(context);
    if (!context.mounted) return;

    await load(debugSource: '$runtimeType#_construct');
    if (nickname == null && context.mounted) showInputNameSheet(context);

    RestoreBackupService.instance.addListener(() async {
      load(debugSource: '$runtimeType#_listenToRestoreService');
    });
  }

  String? nickname;
  int year = DateTime.now().year;
  CollectionDbModel<StoryDbModel>? stories;

  List<int> get months {
    List<int> months = stories?.items.map((e) => e.month).toSet().toList() ?? [];
    if (months.isEmpty) months.add(DateTime.now().month);
    return months;
  }

  Future<void> showInputNameSheet(BuildContext context) async {
    await Future.delayed(Durations.long3);
    if (context.mounted) changeName(context);
  }

  Future<void> load({
    required String debugSource,
  }) async {
    debugPrint('🚧 Reload home from $debugSource 🏠');

    nickname = PreferenceDbModel.db.nickname.get();
    stories = await StoryDbModel.db.where(filters: {
      'year': year,
      'types': [PathType.docs.name],
    });

    scrollInfo.setupStoryKeys(stories?.items ?? []);
    notifyListeners();
  }

  Future<void> refresh(BuildContext context) async {
    await load(debugSource: '$runtimeType#refresh');
    if (context.mounted) await context.read<BackupProvider>().recheck();
  }

  Future<void> loadFromLegacyStorypadIfShould(BuildContext context) async {
    (bool, String) result = await StorypadLegacyDatabase.instance.transferToObjectBoxIfNotYet();

    bool success = result.$1;
    String message = result.$2;

    if (success) {
      if (!context.mounted) return;
      // if (kDebugMode) MessengerService.of(context).showSnackBar(message);
    } else {
      if (!context.mounted) return;

      OkCancelResult userAction = await showOkAlertDialog(
        context: context,
        title: 'Error importing data from previous version!',
        message: "Please contact developer for support & avoid data loss.",
      );

      if (userAction == OkCancelResult.ok && context.mounted) {
        Clipboard.setData(ClipboardData(text: message));
        MessengerService.of(context).showSnackBar("Error code copied to your clipboard");
      }
    }
  }

  Future<void> changeYear(int newYear) async {
    if (year == newYear) return;

    year = newYear;
    stories = null;
    notifyListeners();

    await load(debugSource: '$runtimeType#changeYear $newYear');
    AnalyticsService.instance.logViewHome(year: year);
  }

  Future<void> goToViewPage(BuildContext context, StoryDbModel story) async {
    await ShowStoryRoute(id: story.id, story: story).push(context);
  }

  Future<void> goToNewPage(BuildContext context) async {
    await EditStoryRoute(id: null, initialYear: year).push(context);
    await load(debugSource: '$runtimeType#goToNewPage');

    // https://developer.android.com/guide/playcore/in-app-review#when-to-request
    // https://developer.apple.com/app-store/ratings-and-reviews/
    int newCount = await NewStoriesCountStorage().increase();
    if (newCount % 10 == 0) InAppReviewService.request();
  }

  void changeName(BuildContext context) async {
    dynamic result = await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      sheetAnimationStyle: AnimationStyle(curve: Curves.fastEaseInToSlowEaseOut, duration: Durations.long4),
      isScrollControlled: true,
      builder: (context) {
        return NicknameBottomSheet(nickname: nickname);
      },
    );

    if (result is String) {
      PreferenceDbModel.db.nickname.set(result);
      nickname = PreferenceDbModel.db.nickname.get();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    scrollInfo.dispose();
    super.dispose();
  }
}
