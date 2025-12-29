import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/quill/quill_delta_to_plain_text_service.dart';
import 'package:storypad/core/services/markdown_content_filter_service.dart';

/// Result object for generateBodyPlainText operation
class GenerateBodyPlainTextResult {
  final String plainText;
  final List<StoryPageDbModel> richPagesWithCounts;

  const GenerateBodyPlainTextResult({
    required this.plainText,
    required this.richPagesWithCounts,
  });
}

/// Service to generate plain text and character/word counts from story pages
class GenerateBodyPlainTextService {
  /// Generates plain text and counts from a list of story pages
  ///
  /// [newRichPages] - List of story pages to process
  ///
  /// Returns [GenerateBodyPlainTextResult] containing:
  /// - plainText: Combined plain text from all pages
  /// - richPagesWithCounts: Pages with updated character and word counts
  /// - characterCount: Total character count across all pages
  ///
  /// Returns null if [newRichPages] is null or empty
  static GenerateBodyPlainTextResult? call(List<StoryPageDbModel>? newRichPages) {
    if (newRichPages == null || newRichPages.isEmpty) return null;

    // Compute text once per page and reuse results
    final pageTexts = newRichPages.map((page) {
      return QuillDeltaToPlainTextService.call(page.body ?? [], markdown: true, includeMarkdownEmbeds: false);
    }).toList();

    // Build plainText from computed texts
    final String plainText = [
      pageTexts.first,
      if (newRichPages.length > 1)
        for (int i = 1; i < newRichPages.length; i++) ...[
          newRichPages[i].title ?? '',
          pageTexts[i],
        ],
    ].join('\n').trim();

    // Build richPagesWithCounts using cached texts
    final richPagesWithCounts = [
      for (int i = 0; i < newRichPages.length; i++)
        () {
          // Filter out markdown formatting to count only actual written content
          final filteredTitle = MarkdownContentFilterService.call(newRichPages[i].title ?? '');
          final filteredBody = MarkdownContentFilterService.call(pageTexts[i]);
          final filteredCombined = '$filteredTitle $filteredBody';

          return newRichPages[i].copyWith(
            characterCount: filteredTitle.length + filteredBody.length,
            wordCount: filteredCombined.split(RegExp(r'\s+')).where((element) => element.isNotEmpty).length,
          );
        }(),
    ];

    return GenerateBodyPlainTextResult(
      plainText: plainText,
      richPagesWithCounts: richPagesWithCounts,
    );
  }
}
