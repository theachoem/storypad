import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart' show OkCancelResult, showOkCancelAlertDialog;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' show BuildContext, ChangeNotifier;
import 'package:storypad/core/databases/models/collection_db_model.dart' show CollectionDbModel;
import 'package:storypad/core/databases/models/tag_db_model.dart' show $TagDbModelCopyWith, TagDbModel;
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart' show AnalyticsService;
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/tags/edit/edit_tag_view.dart' show EditTagRoute;
import 'package:storypad/views/tags/show/show_tag_view.dart' show ShowTagRoute;

class TagsProvider extends ChangeNotifier with DebounchedCallback {
  TagsProvider() {
    TagDbModel.db.addGlobalListener(_dbListener);
    BackupProvider.repoInstance.restoreService.addListener(_dbListener);
    setAllTags(TagDbModel.db.getInitialTagsAndClear());
    _reindex(notifyUi: null);
  }

  CollectionDbModel<TagDbModel>? _tags;
  CollectionDbModel<TagDbModel>? _emojiTags;

  CollectionDbModel<TagDbModel>? get tags => _tags;
  CollectionDbModel<TagDbModel>? get emojiTags => _emojiTags;
  CollectionDbModel<TagDbModel>? get allTags => CollectionDbModel(items: [...?tags?.items, ...?emojiTags?.items]);

  Map<int, String> _emojiById = {};
  Map<int, String> get emojiById => _emojiById;

  String? getEmojiTag(int tagId) => _emojiById[tagId];

  void setAllTags(CollectionDbModel<TagDbModel>? allTags) {
    _tags = CollectionDbModel(items: allTags?.items.where((tag) => tag.categoryId == null).toList() ?? []);
    _emojiTags = CollectionDbModel(items: allTags?.items.where((tag) => tag.categoryId != null).toList() ?? []);
    _emojiById = {for (var tag in _emojiTags?.items ?? <TagDbModel>[]) tag.id: ?tag.emoji};
  }

  // pass null to allow reindex to notify only when needed.
  Future<void> _reindex({
    bool? notifyUi,
  }) async {
    bool? shouldNotify = notifyUi;

    if (tags != null) {
      for (int i = 0; i < tags!.items.length; i++) {
        TagDbModel tag = tags!.items[i];

        if (tag.index != i + 1) {
          tag =
              await TagDbModel.db.set(
                tag.copyWith(index: i + 1, updatedAt: DateTime.now()),
                debugSource: '$runtimeType#setup',

                // This is consider silent update, so no need to alert listeners for now.
                runCallbacks: false,
              ) ??
              tag;
          _tags = _tags!.replaceElement(tag);
          shouldNotify ??= true;
        }
      }
    }

    if (shouldNotify == true) notifyListeners();
  }

  Completer<void>? _dbListenerCompleter;
  Future<void> _dbListener() async {
    if (_dbListenerCompleter == null || _dbListenerCompleter!.isCompleted) {
      _dbListenerCompleter = Completer<void>();
    }

    debouncedCallback(() async {
      await reload();
      _dbListenerCompleter?.complete();
    });

    return _dbListenerCompleter!.future;
  }

  Future<void> reload() async {
    final allTags = await TagDbModel.db.where();
    setAllTags(allTags);
    await _reindex(notifyUi: true);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (tags == null) return;

    _tags = tags!.reorder(oldIndex: oldIndex, newIndex: newIndex);
    notifyListeners();

    AnalyticsService.instance.logReorderTags(
      tags: tags!,
    );

    int length = tags!.items.length;
    for (int i = 0; i < length; i++) {
      final item = tags!.items[i];
      if (item.index != i) {
        await TagDbModel.db.set(
          item.copyWith(index: i, updatedAt: DateTime.now()),
          debugSource: '$runtimeType#reorder',
        );
      }
    }
  }

  List<String> get tagTitles => tags?.items.map((e) => e.title).toList() ?? [];

  bool isTagExist(String title) {
    return tagTitles.map((e) => e.toLowerCase()).contains(title.trim().toLowerCase());
  }

  Future<void> addTag(BuildContext context) async {
    final result = await EditTagRoute(tag: null, tags: tags?.items ?? []).push(context);

    if (result is List<String> && result.isNotEmpty) {
      TagDbModel newTag = TagDbModel.fromNow().copyWith(title: result.first);
      TagDbModel? tag = await TagDbModel.db.set(newTag);
      await reload();

      if (tag == null) return;
      AnalyticsService.instance.logAddTag(
        tag: tag,
      );
    }
  }

  Future<bool> deleteTag(BuildContext context, TagDbModel tag) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: tr('dialog.are_you_sure_to_delete_tag.title'),
      message: tr('dialog.are_you_sure_to_delete_tag.message'),
      isDestructiveAction: true,
    );

    if (result == OkCancelResult.ok) {
      _tags = tags?.removeElement(tag);
      notifyListeners();

      await TagDbModel.db.delete(tag.id);
      AnalyticsService.instance.logDeleteTag(
        tag: tag,
      );

      return true;
    }

    return false;
  }

  Future<void> editTag(BuildContext context, TagDbModel tag) async {
    final result = await EditTagRoute(tag: tag, tags: tags?.items ?? []).push(context);

    if (result is List<String> && result.isNotEmpty) {
      TagDbModel newTag = tag.copyWith(title: result.first, updatedAt: DateTime.now());
      await TagDbModel.db.set(newTag, debugSource: '$runtimeType#editTag');
      AnalyticsService.instance.logEditTag(
        tag: tag,
      );
    }
  }

  Future<TagDbModel?> createTag(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;
    if (tags?.items.any((tag) => tag.title.toLowerCase() == trimmed.toLowerCase()) == true) return null;

    // We already set index to start from 1 in provider.
    // So new tag will be added to 0 to make it appear at the top, and then reindex will update it to 1.
    final newTag = TagDbModel.fromNow().copyWith(title: trimmed, index: 0);

    _tags ??= CollectionDbModel(items: []);
    _tags = _tags?.addElement(newTag, 0);
    notifyListeners();

    final tag = await TagDbModel.db.set(newTag, debugSource: '$runtimeType#createTag');

    if (tag != null) {
      AnalyticsService.instance.logAddTag(tag: tag);
      return tag;
    } else {
      _tags = _tags?.removeElement(newTag);
      notifyListeners();
      return null;
    }
  }

  void viewTag({
    required BuildContext context,
    required TagDbModel tag,
    required bool storyViewOnly,
  }) async {
    ShowTagRoute(
      storyViewOnly: storyViewOnly,
      tag: tag,
    ).push(context);
  }

  @override
  void dispose() {
    TagDbModel.db.removeGlobalListener(_dbListener);
    BackupProvider.repoInstance.restoreService.removeListener(_dbListener);
    super.dispose();
  }
}
