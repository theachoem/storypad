import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
import 'package:storypad/core/rich_text/rich_text_serializer.dart';
import 'package:storypad/core/services/quill/quill_delta_to_plain_text_service.dart';

/// Adapter implementation of [RichTextSerializer] using Quill Delta format.
///
/// This adapter wraps existing Delta JSON processing logic and provides
/// a format-agnostic interface for the rest of the application.
class QuillSerializer implements RichTextSerializer {
  const QuillSerializer();

  @override
  List<dynamic> serialize(dynamic content) {
    if (content is quill.Document) {
      return content.toDelta().toJson();
    } else if (content is Delta) {
      return content.toJson();
    } else if (content is List<dynamic>) {
      return content;
    }
    throw ArgumentError('Cannot serialize content of type ${content.runtimeType}');
  }

  @override
  quill.Document deserialize(List<dynamic> json) {
    return quill.Document.fromJson(json);
  }

  @override
  String toPlainText(
    List<dynamic> deltaOps, {
    bool includeEmbeds = false,
  }) {
    return QuillDeltaToPlainTextService.call(
      deltaOps,
      markdown: false,
      includeMarkdownEmbeds: includeEmbeds,
    );
  }

  @override
  String toMarkdown(
    List<dynamic> deltaOps, {
    bool includeEmbeds = false,
  }) {
    return QuillDeltaToPlainTextService.call(
      deltaOps,
      markdown: true,
      includeMarkdownEmbeds: includeEmbeds,
    );
  }

  @override
  List<dynamic> fromMarkdown(String markdown) {
    // TODO: Implement markdown to Delta conversion
    // This will use MarkdownToQuillDeltaService when implemented
    throw UnimplementedError('Markdown to Delta conversion not yet implemented');
  }

  @override
  List<String> extractEmbeds(
    List<dynamic> deltaOps, {
    String? embedType,
  }) {
    final embeds = <String>[];

    for (final op in deltaOps) {
      if (op is! Map<String, dynamic>) continue;

      final insert = op['insert'];
      if (insert is! Map<String, dynamic>) continue;

      // Check each key in insert map for embed types
      for (final key in insert.keys) {
        // If embedType filter is specified, only include matching types
        if (embedType == null || key == embedType) {
          final value = insert[key];
          if (value is String) {
            embeds.add(value);
          }
        }
      }
    }

    return embeds;
  }
}
