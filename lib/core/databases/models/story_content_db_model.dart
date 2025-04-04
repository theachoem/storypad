import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/databases/models/mixins/comparable.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/markdown_body_shortener_service.dart';

part 'story_content_db_model.g.dart';

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

  StoryContentDbModel addRichPage() {
    return copyWith(
      richPages: [
        ...richPages ?? [],
        StoryPageDbModel(title: null, plainText: null, body: null, feeling: null),
      ],
    );
  }

  StoryContentDbModel copyWithNewFeeling(int pageIndex, String? feeling) {
    List<StoryPageDbModel> cloneRichPages = [...richPages!];
    cloneRichPages[pageIndex] = cloneRichPages[pageIndex].copyWith(feeling: feeling);
    return copyWith(richPages: cloneRichPages);
  }

  StoryContentDbModel removeRichPageAt(int index) {
    return copyWith(
      richPages: [
        ...richPages ?? [],
      ]..removeAt(index),
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
