import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/mixins/comparable.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
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

  // metadata should be title + plain text
  // better if with all pages.
  final String? metadata;
  String? get safeMetadata {
    return metadata ?? [title ?? "", plainText ?? ""].join("\n");
  }

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
    required this.metadata,
  });

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
    return copyWith(
        title: richPages?.first.title,
        plainText: richPages?.first.plainText,
        richPages: [
          ...richPages ?? [],
        ]..removeWhere((e) => e.id == pageId));
  }

  StoryContentDbModel replacePage(StoryPageDbModel newPage) {
    List<StoryPageDbModel> richPages = [...this.richPages ?? []];
    int index = richPages.indexWhere((e) => e.id == newPage.id);
    richPages[index] = newPage;

    return copyWith(
      title: index == 0 ? newPage.title : title,
      plainText: index == 0 ? newPage.plainText : plainText,
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
      metadata: null,
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
