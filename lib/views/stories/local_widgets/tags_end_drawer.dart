import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/views/tags/tags_view.dart';
import 'package:storypad/widgets/sp_end_drawer_theme.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

class TagsEndDrawer extends StatefulWidget {
  const TagsEndDrawer({
    super.key,
    required this.initialTags,
    required this.onUpdated,
  });

  final List<int> initialTags;
  final Future<bool> Function(List<int> tags) onUpdated;

  @override
  State<TagsEndDrawer> createState() => _TagsEndDrawerState();
}

class _TagsEndDrawerState extends State<TagsEndDrawer> {
  late List<int> selectedTags = widget.initialTags;

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

    setState(() {});
  }

  @override
  void didUpdateWidget(covariant TagsEndDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialTags.length != oldWidget.initialTags.length) {
      setState(() {
        selectedTags = widget.initialTags;
      });
    }
  }

  @override
  void initState() {
    load();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SpEndDrawerTheme(
        child: SpNestedNavigation(
          initialScreen: buildDrawer(context),
        ),
      ),
    );
  }

  Widget buildDrawer(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        actions: [
          Builder(builder: (context) {
            return IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await TagsRoute(storyViewOnly: true).push(context);
                load();
              },
            );
          })
        ],
      ),
      body: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    if (tags == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return ListView.builder(
      itemCount: tags?.items.length ?? 0,
      itemBuilder: (context, index) {
        final tag = tags!.items[index];
        final storyCount = getStoriesCount(tag);

        return CheckboxListTile(
          title: Text(tag.title),
          subtitle: Text(storyCount > 1 ? "$storyCount stories" : "$storyCount story"),
          value: selectedTags.contains(tag.id) == true,
          onChanged: (bool? value) async {
            if (value == true) {
              selectedTags = {...selectedTags, tag.id}.toList();
              setState(() {});

              bool success = await widget.onUpdated(selectedTags);
              if (!success) setState(() => selectedTags = widget.initialTags);

              load();
            } else if (value == false) {
              selectedTags = selectedTags.toList()..removeWhere((id) => id == tag.id);
              setState(() {});

              bool success = await widget.onUpdated(selectedTags);
              if (!success) setState(() => selectedTags = widget.initialTags);

              load();
            }
          },
        );
      },
    );
  }
}
