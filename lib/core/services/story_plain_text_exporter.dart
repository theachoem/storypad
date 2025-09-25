import 'dart:ui';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/story_page_object.dart';
import 'package:storypad/core/services/quill/quill_root_to_plain_text_service.dart';
import 'package:storypad/core/types/time_format_option.dart';

class StoryPlainTextExporter {
  final DateTime displayPathDate;
  final List<StoryPageObject> pages;
  final Locale locale;
  final TimeFormatOption timeFormat;
  final List<TagDbModel> tags;
  final String? feeling;
  final bool markdown;

  StoryPlainTextExporter({
    required this.displayPathDate,
    required this.pages,
    required this.tags,
    required this.feeling,
    required this.timeFormat,
    required this.locale,
    required this.markdown,
  });

  String export() {
    final headerParts = <String>[];
    headerParts.add(timeFormat.formatDateTime(displayPathDate, locale));

    if (tags.isNotEmpty) {
      final tagNames = tags.map((t) => t.title).join(', ');
      headerParts.add(tagNames);
    }

    if (feeling != null) {
      headerParts.add(feeling!);
    }

    final header = headerParts.isNotEmpty ? "${headerParts.join('\n')}\n\n" : '';
    final pagesText = pages.map(_pageContent).where((content) => content.isNotEmpty).join('\n\n---\n\n').trim();

    return "$header$pagesText\n\n#StoryPad";
  }

  String _pageContent(StoryPageObject page) {
    final parts = <String>[];

    final title = page.titleController.text.trim().trim();
    if (title.isNotEmpty) parts.add(title);

    String plainTexts = QuillRootToPlainTextService.call(
      page.bodyController.document.root,
      markdown: markdown,
    );

    if (plainTexts.isNotEmpty) parts.add(plainTexts);

    return parts.join('\n');
  }
}
