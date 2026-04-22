import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';
import 'package:storypad/widgets/sp_text_inputs_page.dart';

// ignore: constant_identifier_names
const _PADDING = 16.0;

class SpFloatingTagPicker extends StatefulWidget {
  final List<int> initialTags;
  final Future<bool> Function(List<int> tags) onUpdated;
  final FutureOr<void> Function() close;

  const SpFloatingTagPicker({
    super.key,
    required this.initialTags,
    required this.onUpdated,
    required this.close,
  });

  @override
  State<SpFloatingTagPicker> createState() => _SpFloatingTagPickerState();
}

class _SpFloatingTagPickerState extends State<SpFloatingTagPicker> {
  late Set<int> selectedTags = widget.initialTags.toSet();
  final _searchController = TextEditingController();

  String _query = '';
  bool _creating = false;

  late final TagsProvider tagsProvider = context.read<TagsProvider>();
  late Map<int, int> storiesCountByTagId = StoryDbModel.db.getStoryCountByTags(
    tagIds: tagsProvider.tags?.items.map((e) => e.id).toList() ?? [],
  );

  int getStoriesCount(TagDbModel tag) => storiesCountByTagId[tag.id] ?? 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggle(TagDbModel tag) async {
    final isSelected = selectedTags.contains(tag.id);
    final newTags = isSelected ? ({...selectedTags}..remove(tag.id)).toList() : ({...selectedTags, tag.id}).toList();

    setState(() => selectedTags = newTags.toSet());
    final success = await widget.onUpdated(newTags);
    if (!success) setState(() => selectedTags = widget.initialTags.toSet());
  }

  Future<void> _create(TagsProvider provider) async {
    if (_creating) return;

    setState(() => _creating = true);
    final tag = await provider.createTag(_query);

    if (tag != null && mounted) {
      await _toggle(tag);
      setState(() {
        _query = '';
        _searchController.clear();
      });
    }

    if (mounted) setState(() => _creating = false);
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      removeTop: true,
      removeLeft: true,
      removeBottom: true,
      removeRight: true,
      context: context,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 288, maxHeight: 320),
        child: Material(
          clipBehavior: .hardEdge,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SpNestedNavigation(
            initialScreen: Builder(
              builder: (context) {
                return buildPage(context: context);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPage({required BuildContext context}) {
    final provider = Provider.of<TagsProvider>(context);
    final tags = provider.tags?.items ?? <TagDbModel>[];

    final filtered = _query.isEmpty
        ? tags
        : () {
            final fuzzy = Fuzzy<TagDbModel>(
              tags,
              options: FuzzyOptions(
                isCaseSensitive: false,
                keys: [WeightedKey(name: 'title', getter: (t) => t.title, weight: 1)],
              ),
            );

            final results = fuzzy.search(_query);
            results.sort((a, b) => a.score.compareTo(b.score));
            return results.map((r) => r.item).toList();
          }();

    final allowCreate =
        _query.isNotEmpty && (tags.isEmpty || !tags.any((t) => t.title.toLowerCase() == _query.toLowerCase()));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: _PADDING),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _PADDING),
          child: TextField(
            controller: _searchController,
            onChanged: (text) => setState(() => _query = text),
            decoration: InputDecoration(
              isDense: true,
              hintText: tr('input.tag.hint'),
              hintStyle: TextStyle(color: ColorScheme.of(context).onSurface.withValues(alpha: 0.4)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: ColorScheme.of(context).outline),
              ),
              suffixIconConstraints: const BoxConstraints(maxWidth: 32.0),
              suffixIcon: _query.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: Icon(SpIcons.add),
                    )
                  : null,
            ),
            style: TextTheme.of(context).bodyMedium,
          ),
        ),
        const SizedBox(height: _PADDING),
        const Divider(height: 1),

        if (!allowCreate && tags.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12.0,
              children: [
                const Icon(SpIcons.tag, size: 24.0),
                Text(
                  tr("page.tags.empty_message"),
                  textAlign: TextAlign.center,
                  style: TextTheme.of(context).bodyMedium,
                ),
              ],
            ),
          ),
        ] else ...[
          Flexible(
            child: Scrollbar(
              thumbVisibility: true,
              interactive: true,
              child: ReorderableListView(
                shrinkWrap: true,
                buildDefaultDragHandles: true,
                padding: EdgeInsets.zero,
                onReorder: (oldIndex, newIndex) {
                  if (allowCreate) {
                    oldIndex -= 1;
                    newIndex -= 1;
                  }
                  if (oldIndex < 0 || newIndex < 0) return;
                  provider.reorder(oldIndex, newIndex);
                },
                children: [
                  if (allowCreate)
                    ListTile(
                      key: const ValueKey('create'),
                      dense: true,
                      horizontalTitleGap: 4.0,
                      onTap: () => _create(provider),
                      leading: _creating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator.adaptive(),
                            )
                          : const Icon(SpIcons.add, size: 16),
                      title: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${tr("page.new_tag.title")}: '),
                            TextSpan(
                              text: _query,
                              style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: .bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ...filtered.map(
                    (tag) => Slidable(
                      closeOnScroll: true,
                      key: ValueKey(tag.id),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) => provider.deleteTag(context, tag),
                            backgroundColor: ColorScheme.of(context).error,
                            foregroundColor: ColorScheme.of(context).onError,
                            icon: SpIcons.delete,
                            label: tr("button.delete"),
                          ),
                          SlidableAction(
                            onPressed: (context) async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => _EditTagView(tag: tag)),
                              );

                              if (result is List<String> && result.isNotEmpty) {
                                TagDbModel newTag = tag.copyWith(title: result.first, updatedAt: DateTime.now());
                                await TagDbModel.db.set(newTag, debugSource: '$runtimeType#editTag');
                                AnalyticsService.instance.logEditTag(tag: newTag);
                              }
                            },
                            backgroundColor: ColorScheme.of(context).secondary,
                            foregroundColor: ColorScheme.of(context).onSecondary,
                            icon: SpIcons.edit,
                            label: tr("button.edit"),
                          ),
                        ],
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Checkbox.adaptive(
                          value: selectedTags.contains(tag.id),
                          onChanged: (_) => _toggle(tag),
                        ),
                        horizontalTitleGap: 12.0,
                        contentPadding: const EdgeInsets.only(left: 4.0, right: 12.0),
                        trailing:
                            [
                              TargetPlatform.linux,
                              TargetPlatform.windows,
                              TargetPlatform.macOS,
                            ].contains(Theme.of(context).platform)
                            ? null
                            : const Icon(SpIcons.dragIndicator),
                        title: Text(tag.title),
                        subtitle: Text(plural("plural.story", getStoriesCount(tag))),
                        onTap: () => _toggle(tag),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EditTagView extends StatelessWidget {
  const _EditTagView({
    required this.tag,
  });

  final TagDbModel tag;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorScheme.of(context).surface,
      child: buildContent(context),
    );
  }

  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
          child: BackButton(),
        ),
        Expanded(
          child: SpTextInputsPage(
            contentOnly: true,
            fields: [
              SpTextInputField(
                initialText: tag.title,
                hintText: tr("input.tag.hint"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty == true) {
                    return tr("input.message.required");
                  }

                  if (context.read<TagsProvider>().isTagExist(value) == true) {
                    return tr("input.message.already_exist");
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
