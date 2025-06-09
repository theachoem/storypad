import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/mixins/comparable.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/mixins/list_reorderable.dart';
import 'package:storypad/core/services/markdown_body_shortener_service.dart';

part 'story_content_db_model.g.dart';

List<StoryPageDbModel>? _richPagesFromJson(dynamic richPages) {
  if (richPages == null) return null;
  if (richPages is List) {
    int now = DateTime.now().millisecondsSinceEpoch;
    return List.generate(richPages.length, (index) {
      Map<String, dynamic> page = richPages[index];

      // generate default ID for previous record if not exist.
      if (page['id'] == null) {
        debugPrint('StoryContentDbModel._richPagesFromJson generating page ID 🚧🚧🚧🚧🚧');
        page['id'] = now + index;
      }

      return StoryPageDbModel.fromJson(page);
    });
  }

  return null;
}

@CopyWith()
@JsonSerializable()
class StoryContentDbModel extends BaseDbModel with Comparable {
  @override
  final int id;
  final String? title;
  final String? plainText;
  final DateTime createdAt;

  @override
  List<String>? get includeCompareKeys => ['title', 'rich_pages'];

  @override
  DateTime get updatedAt => createdAt;

  // @Deprecated('use richPages instead')
  // List: Returns JSON-serializable version of quill delta.
  final List<List<dynamic>>? pages;

  @JsonKey(fromJson: _richPagesFromJson)
  final List<StoryPageDbModel>? richPages;

  StoryContentDbModel({
    required this.id,
    required this.title,
    required this.plainText,
    required this.createdAt,
    required this.pages,
    required this.richPages,
  });

  String? generatePlainText(List<StoryPageDbModel>? newRichPages) {
    if (newRichPages == null || newRichPages.isEmpty) return null;
    return [
      newRichPages.first.plainText ?? '',
      if (newRichPages.length > 1)
        for (final p in newRichPages.getRange(1, newRichPages.length)) ...[
          p.title ?? '',
          p.plainText ?? '',
        ],
    ].join('\n').trim();
  }

  StoryContentDbModel reorder({
    required int oldIndex,
    required int newIndex,
  }) {
    List<StoryPageDbModel> newRichPages = [
      ...richPages ?? <StoryPageDbModel>[],
    ].reorder(oldIndex: oldIndex, newIndex: newIndex);

    return copyWith(
      title: newRichPages.first.title,
      plainText: generatePlainText(newRichPages),
      richPages: newRichPages,
    );
  }

  StoryContentDbModel addRichPage({
    int? crossAxisCount,
    int? mainAxisCount,
  }) {
    return copyWith(
      richPages: [
        ...richPages ?? [],
        StoryPageDbModel(
          id: DateTime.now().millisecondsSinceEpoch,
          title: null,
          plainText: null,
          body: null,
          crossAxisCount: crossAxisCount,
          mainAxisCount: mainAxisCount,
        ),
      ],
    );
  }

  StoryContentDbModel removeRichPage(int pageId) {
    List<StoryPageDbModel> newRichPages = [
      ...richPages ?? [],
    ]..removeWhere((e) => e.id == pageId);

    return copyWith(
      title: richPages?.first.title,
      plainText: generatePlainText(newRichPages),
      richPages: [
        ...richPages ?? [],
      ]..removeWhere((e) => e.id == pageId),
    );
  }

  StoryContentDbModel replacePage(StoryPageDbModel newPage) {
    List<StoryPageDbModel> richPages = [...this.richPages ?? []];
    int index = richPages.indexWhere((e) => e.id == newPage.id);
    richPages[index] = newPage;

    return copyWith(
      title: index == 0 ? newPage.title : title,
      plainText: generatePlainText(richPages),
      richPages: richPages,
    );
  }

  String? get displayShortBody {
    return plainText != null ? MarkdownBodyShortenerService.call(plainText!) : null;
  }

  factory StoryContentDbModel.dublicate(StoryContentDbModel oldContent) {
    DateTime now = DateTime.now();
    return oldContent.copyWith(
      id: now.millisecondsSinceEpoch,
      createdAt: now,
      plainText: oldContent.plainText,
    );
  }

  factory StoryContentDbModel.create({
    DateTime? createdAt,
  }) {
    return StoryContentDbModel(
      id: createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      title: null,
      plainText: null,
      createdAt: createdAt ?? DateTime.now(),
      pages: null,
      richPages: null,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$StoryContentDbModelToJson(this);
  factory StoryContentDbModel.fromJson(Map<String, dynamic> json) => _$StoryContentDbModelFromJson(json);

  @override
  List<String> get excludeCompareKeys {
    return [
      'id',
      'plain_text',
      'created_at',
      'metadata',
    ];
  }
}
