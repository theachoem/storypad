import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/mixins/comparable.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/mixins/list_reorderable.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/services/markdown_body_shortener_service.dart';
import 'package:storypad/core/services/generate_body_plain_text_service.dart';

part 'story_content_db_model.g.dart';

List<StoryPageDbModel>? _richPagesFromJson(dynamic richPages) {
  if (richPages == null) return null;
  if (richPages is List) {
    int now = DateTime.now().millisecondsSinceEpoch;
    return List.generate(richPages.length, (index) {
      Map<String, dynamic> page = richPages[index];

      // generate default ID for previous record if not exist.
      if (page['id'] == null) {
        AppLogger.d('StoryContentDbModel._richPagesFromJson generating page ID 🚧🚧🚧🚧🚧');
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
  // The title is worked out from the pages (see StoryPageDbModel.title), so comparing the pages covers it.
  List<String>? get includeCompareKeys => ['rich_pages'];

  @override
  List<String> get excludeCompareKeys {
    return [
      'id',
      'plain_text',
      'created_at',
      'metadata',
    ];
  }

  @override
  DateTime get updatedAt => createdAt;

  // @Deprecated('use richPages instead')
  // List: Returns JSON-serializable version of quill delta.
  final List<List<dynamic>>? pages;

  @JsonKey(fromJson: _richPagesFromJson)
  final List<StoryPageDbModel>? richPages;

  int get wordCount =>
      richPages?.fold<int>(0, (previousValue, element) => previousValue + (element.wordCount ?? 0)) ?? 0;

  int get characterCount =>
      richPages?.fold<int>(0, (previousValue, element) => previousValue + (element.characterCount ?? 0)) ?? 0;

  StoryContentDbModel({
    required this.id,
    required this.title,
    required this.plainText,
    required this.createdAt,
    required this.richPages,
    this.pages,
  });

  StoryContentDbModel reorder({
    required int oldIndex,
    required int newIndex,
  }) {
    List<StoryPageDbModel> newRichPages = [
      ...richPages ?? <StoryPageDbModel>[],
    ].reorder(oldIndex: oldIndex, newIndex: newIndex);

    final plainTextResult = GenerateBodyPlainTextService.call(newRichPages);

    return copyWith(
      title: newRichPages.first.title,
      plainText: plainTextResult?.plainText,
      richPages: plainTextResult?.richPagesWithCounts,
    );
  }

  StoryContentDbModel addRichPage() {
    return copyWith(
      richPages: [
        ...richPages ?? [],
        StoryPageDbModel.create(id: DateTime.now().millisecondsSinceEpoch),
      ],
    );
  }

  StoryContentDbModel removeRichPage(int pageId) {
    List<StoryPageDbModel> newRichPages = [
      ...richPages ?? [],
    ]..removeWhere((e) => e.id == pageId);

    final plainTextResult = GenerateBodyPlainTextService.call(newRichPages);

    return copyWith(
      title: newRichPages.firstOrNull?.title,
      plainText: plainTextResult?.plainText,
      richPages: plainTextResult?.richPagesWithCounts,
    );
  }

  StoryContentDbModel replacePage(StoryPageDbModel newPage) {
    List<StoryPageDbModel> richPages = [...this.richPages ?? []];
    int index = richPages.indexWhere((e) => e.id == newPage.id);
    richPages[index] = newPage;

    final plainTextResult = GenerateBodyPlainTextService.call(richPages);

    return copyWith(
      title: index == 0 ? newPage.title : title,
      plainText: plainTextResult?.plainText,
      richPages: plainTextResult?.richPagesWithCounts,
    );
  }

  /// Whether a page is stored in a format this app version doesn't know (from a newer version): the story is shown
  /// read-only and never saved.
  bool get hasUnsupportedPages => richPages?.any((page) => page.isUnsupported) == true;

  /// Whether a page is still stored in the legacy shape (a separate title and a Quill body).
  bool get hasLegacyPages => richPages?.any((page) => page.isLegacy) == true;

  /// This content with its legacy pages converted to Markdown ([StoryPageDbModel.toMarkdownPage]), title and plain
  /// text recomputed -- or `null` when there's nothing to convert, or when any page wouldn't convert losslessly (see
  /// [StoryPageDbModel.checkConversion]); the content then stays as stored, and the failure is logged.
  StoryContentDbModel? convertLegacyPages() {
    final pages = richPages;
    if (pages == null || !hasLegacyPages || hasUnsupportedPages) return null;

    for (final page in pages) {
      if (!page.isLegacy) continue;
      final check = page.checkConversion();
      if (!check.isLossless) {
        AppLogger.error(
          'StoryContentDbModel#convertLegacyPages: page $id/${page.id} kept as Quill: $check '
          '${check.losses.map((loss) => '${loss.kind.name}:${loss.key}').toSet()}',
          tag: 'StoryContentDbModel',
        );
        return null;
      }
    }

    final converted = [for (final page in pages) page.toMarkdownPage()];
    final plainTextResult = GenerateBodyPlainTextService.call(converted);
    return copyWith(
      title: converted.first.title,
      plainText: plainTextResult?.plainText,
      richPages: plainTextResult?.richPagesWithCounts,
    );
  }

  String? displayShortBody({int maxCharacterCount = 200}) {
    return plainText != null
        ? MarkdownBodyShortenerService.call(plainText!, maxCharacterCount: maxCharacterCount)
        : null;
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
}
