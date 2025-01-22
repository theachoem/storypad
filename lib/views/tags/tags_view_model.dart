import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/base/base_view_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';
import 'package:storypad/widgets/sp_text_inputs_page.dart';
import 'package:storypad/widgets/story_list/story_list.dart';
import 'tags_view.dart';

class TagsViewModel extends BaseViewModel {
  final TagsRoute params;

  TagsViewModel({
    required this.params,
  }) {
    load();
  }

  CollectionDbModel<TagDbModel>? tags;
  Map<int, int> storiesCountByTagId = {};
  int getStoriesCount(TagDbModel tag) => storiesCountByTagId[tag.id]!;

  Future<void> load() async {
    tags = await TagDbModel.db.where();
    storiesCountByTagId.clear();

    if (tags != null) {
      for (TagDbModel tag in tags?.items ?? []) {
        storiesCountByTagId[tag.id] = await StoryDbModel.db.count(filters: {
          'tag': tag.id,
          'types': [
            PathType.archives.name,
            PathType.docs.name,
          ]
        });
      }
    }

    notifyListeners();
  }

  void viewTag(BuildContext context, TagDbModel tag) async {
    SpNestedNavigation.maybeOf(context)?.push(Scaffold(
      appBar: AppBar(title: Text(tag.title)),
      body: StoryList.withQuery(
        tagId: tag.id,
        viewOnly: params.storyViewOnly,
        types: const [
          PathType.archives,
          PathType.docs,
        ],
      ),
    ));
  }

  Future<void> deleteTag(BuildContext context, TagDbModel tag) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: "Are you sure to delete?",
      message: "You can't undo this action. Related stories will still remain",
    );

    if (result == OkCancelResult.ok) {
      await TagDbModel.db.delete(tag.id);
      await load();
    }
  }

  Future<void> editTag(BuildContext context, TagDbModel tag) async {
    dynamic result = await SpNestedNavigation.maybeOf(context)?.push(buildTagForm(initialTag: tag));

    if (result is List<String> && result.isNotEmpty) {
      TagDbModel newTag = tag.copyWith(title: result.first);
      await TagDbModel.db.set(newTag);
      await load();
    }
  }

  Future<void> addTag(BuildContext context) async {
    dynamic result = await SpNestedNavigation.maybeOf(context)?.push(buildTagForm());

    if (result is List<String> && result.isNotEmpty) {
      TagDbModel newTag = TagDbModel.fromNow().copyWith(title: result.first);
      await TagDbModel.db.set(newTag);
      await load();
    }
  }

  Widget buildTagForm({
    TagDbModel? initialTag,
  }) {
    List<String> tagTitles = tags?.items.map((e) => e.title).toList() ?? [];

    bool isTagExist(String title) {
      return tagTitles.map((e) => e.toLowerCase()).contains(title.trim().toLowerCase());
    }

    return SpTextInputsPage(
      appBar: AppBar(title: initialTag != null ? const Text("Edit Tag") : const Text("Add Tag")),
      fields: [
        SpTextInputField(
          initialText: initialTag?.title,
          hintText: 'eg. Personal',
          validator: (value) {
            if (value == null || value.trim().isEmpty == true) return "Required";
            if (isTagExist(value) == true) return 'Tag already Exist';
            return null;
          },
        ),
      ],
    );
  }
}
