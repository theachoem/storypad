import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart' show OkCancelResult, showOkCancelAlertDialog;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' show BuildContext, ChangeNotifier;
import 'package:storypad/core/databases/models/collection_db_model.dart' show CollectionDbModel;
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_category_db_model.dart' show TagCategoryDbModel;
import 'package:storypad/core/databases/models/tag_db_model.dart' show $TagDbModelCopyWith, TagDbModel;
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart' show AnalyticsService;
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/tags/edit/edit_tag_view.dart' show EditTagResult, EditTagRoute;
import 'package:storypad/views/tags/show/show_tag_view.dart' show ShowTagRoute;

class TagsProvider extends ChangeNotifier with DebounchedCallback {
  TagsProvider() {
    TagDbModel.db.addGlobalListener(_dbListener);
    BackupProvider.repoInstance.restoreService.addListener(_dbListener);
    setAllTags(TagDbModel.db.getInitialTagsAndClear());
    _reindex(notifyUi: null);
  }

  CollectionDbModel<TagDbModel>? _tags;
  CollectionDbModel<TagDbModel>? _peopleTags;
  CollectionDbModel<TagDbModel>? _emojiTags;

  CollectionDbModel<TagDbModel>? get tags => _tags;
  CollectionDbModel<TagDbModel>? get peopleTags => _peopleTags;
  CollectionDbModel<TagDbModel>? get emojiTags => _emojiTags;
  CollectionDbModel<TagDbModel>? get allTags =>
      CollectionDbModel(items: [...?tags?.items, ...?peopleTags?.items, ...?emojiTags?.items]);

  // Returns the editable (non-emoji) collection for the given category: topics when
  // [categoryId] is null, people when it is [TagCategoryDbModel.peopleId].
  CollectionDbModel<TagDbModel>? tagsOf(int? categoryId) =>
      categoryId == TagCategoryDbModel.peopleId ? _peopleTags : _tags;

  Map<int, String> _emojiById = {};
  Map<int, String> get emojiById => _emojiById;

  Map<int, String> _feelingEmojiById = {};
  Map<int, String> get feelingEmojiById => _feelingEmojiById;

  Map<int, TagDbModel> _peopleById = {};
  String? getEmojiTag(int tagId) => _emojiById[tagId];
  TagDbModel? getPersonTag(int tagId) => _peopleById[tagId];

  void setAllTags(CollectionDbModel<TagDbModel>? allTags) {
    final items = allTags?.items ?? <TagDbModel>[];

    // Emoji tags are identified by emoji presence so that text-based categories (People)
    // are not swept into the emoji bucket.
    _emojiTags = CollectionDbModel(items: items.where((tag) => tag.emoji != null).toList());
    _peopleTags = CollectionDbModel(items: items.where((tag) => tag.emoji == null && tag.isPerson).toList());
    _tags = CollectionDbModel(items: items.where((tag) => tag.emoji == null && tag.categoryId == null).toList());

    _emojiById = {for (var tag in _emojiTags?.items ?? <TagDbModel>[]) tag.id: ?tag.emoji};
    _feelingEmojiById = {
      for (var tag in _emojiTags?.items.where((tag) => tag.feeling) ?? <TagDbModel>[]) tag.id: ?tag.emoji,
    };
    _peopleById = {for (var tag in _peopleTags?.items ?? <TagDbModel>[]) tag.id: tag};
  }

  // pass null to allow reindex to notify only when needed.
  // Topics and people keep independent 0-based index sequences since they are filtered separately.
  Future<void> _reindex({
    bool? notifyUi,
  }) async {
    bool? shouldNotify = notifyUi;

    Future<void> reindexBucket(
      CollectionDbModel<TagDbModel>? bucket,
      void Function(TagDbModel updated) replace,
    ) async {
      if (bucket == null) return;
      for (int i = 0; i < bucket.items.length; i++) {
        TagDbModel tag = bucket.items[i];

        if (tag.index != i) {
          tag =
              await TagDbModel.db.set(
                tag.copyWith(index: i, updatedAt: DateTime.now()),
                debugSource: '$runtimeType#setup',

                // This is consider silent update, so no need to alert listeners for now.
                runCallbacks: false,
              ) ??
              tag;
          replace(tag);
          shouldNotify ??= true;
        }
      }
    }

    await reindexBucket(_tags, (updated) => _tags = _tags!.replaceElement(updated));
    await reindexBucket(_peopleTags, (updated) => _peopleTags = _peopleTags!.replaceElement(updated));

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

  Future<void> reorder(int oldIndex, int newIndex, {int? categoryId}) async {
    final bucket = tagsOf(categoryId);
    if (bucket == null) return;

    final reordered = bucket.reorder(oldIndex: oldIndex, newIndex: newIndex);
    if (reordered == null) return;
    _setBucket(categoryId, reordered);
    notifyListeners();

    AnalyticsService.instance.logReorderTags(
      tags: reordered,
    );

    // Avoid running callback for each update since it will trigger reload and reindex again.
    // Only call once after all updates are done.
    int length = reordered.items.length;
    for (int i = 0; i < length; i++) {
      final item = reordered.items[i];
      if (item.index != i) {
        await TagDbModel.db.set(
          item.copyWith(index: i, updatedAt: DateTime.now()),
          debugSource: '$runtimeType#reorder',
          runCallbacks: false,
        );
      }
    }

    await TagDbModel.db.afterCommit();
  }

  void _setBucket(int? categoryId, CollectionDbModel<TagDbModel>? value) {
    if (categoryId == TagCategoryDbModel.peopleId) {
      _peopleTags = value;
    } else {
      _tags = value;
    }
  }

  List<String> tagTitles({int? categoryId}) => tagsOf(categoryId)?.items.map((e) => e.title).toList() ?? [];

  bool isTagExist(String title, {int? categoryId}) {
    return tagTitles(categoryId: categoryId).map((e) => e.toLowerCase()).contains(title.trim().toLowerCase());
  }

  Future<void> addTag(BuildContext context, {int? categoryId}) async {
    final result = await EditTagRoute(
      tag: null,
      tags: tagsOf(categoryId)?.items ?? [],
      categoryId: categoryId,
    ).push(context);

    if (result is EditTagResult) {
      TagDbModel newTag = TagDbModel.fromNow(categoryId: result.categoryId).copyWith(title: result.title);
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
      final bucket = tagsOf(tag.categoryId);
      _setBucket(tag.categoryId, bucket?.removeElement(tag));
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
    final result = await EditTagRoute(
      tag: tag,
      tags: tagsOf(tag.categoryId)?.items ?? [],
      categoryId: tag.categoryId,
    ).push(context);

    if (result is EditTagResult) {
      // Use the field-level proxy for categoryId so moving a tag back to "Tag" (null) is applied.
      TagDbModel newTag = tag
          .copyWith(title: result.title, updatedAt: DateTime.now())
          .copyWith
          .categoryId(result.categoryId);
      await TagDbModel.db.set(newTag, debugSource: '$runtimeType#editTag');
      await reload();

      // Clear search index for related stories so it get picked up to reindex when open search view.
      StoryDbModel.db.clearSearchIndex(filters: {"tag": tag.id});

      AnalyticsService.instance.logEditTag(
        tag: newTag,
      );
    }
  }

  Future<TagDbModel?> createTag(String title, {int? categoryId}) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;
    if (tagsOf(categoryId)?.items.any((tag) => tag.title.toLowerCase() == trimmed.toLowerCase()) == true) {
      return null;
    }

    final newTag = TagDbModel.fromNow(categoryId: categoryId).copyWith(title: trimmed, index: -1);

    _setBucket(categoryId, (tagsOf(categoryId) ?? CollectionDbModel(items: [])).addElement(newTag, 0));
    notifyListeners();

    final tag = await TagDbModel.db.set(newTag, debugSource: '$runtimeType#createTag');

    if (tag != null) {
      AnalyticsService.instance.logAddTag(tag: tag);
      return tag;
    } else {
      _setBucket(categoryId, tagsOf(categoryId)?.removeElement(newTag));
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
