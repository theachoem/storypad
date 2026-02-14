import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:storypad/core/rich_text/rich_text_embed_builder.dart';

/// Adapter that bridges [RichTextEmbedBuilder] to [quill.EmbedBuilder].
///
/// This allows custom embed builders to be written against the abstract
/// RichTextEmbedBuilder interface while still working with flutter_quill.
class QuillEmbedBuilderAdapter extends quill.EmbedBuilder {
  final RichTextEmbedBuilder _embedBuilder;

  QuillEmbedBuilderAdapter(this._embedBuilder);

  @override
  String get key => _embedBuilder.key;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    // Convert Quill embed context to our abstract context
    final richTextContext = RichTextEmbedContext(
      controller: embedContext.controller,
      readOnly: embedContext.readOnly,
      node: _convertQuillEmbedNode(embedContext.node),
    );

    return _embedBuilder.build(context, richTextContext);
  }

  /// Converts Quill Embed node to our abstract RichTextEmbedNode
  RichTextEmbedNode _convertQuillEmbedNode(quill.Embed node) {
    // Extract embed type and data from node.value
    final nodeData = node.value.toJson();
    String? embedType;
    dynamic embedData;

    // Quill embeds have format: {"type": "data"}
    // Example: {"image": "path/to/image.jpg"}
    for (final entry in nodeData.entries) {
      if (entry.key != 'attributes') {
        embedType = entry.key;
        embedData = entry.value;
        break;
      }
    }

    return RichTextEmbedNode(
      type: embedType ?? 'unknown',
      data: embedData,
      documentOffset: node.documentOffset,
      length: node.length,
      attributes: _convertQuillAttributes(node.style.attributes),
    );
  }

  /// Converts Quill attributes to generic Map
  Map<String, dynamic> _convertQuillAttributes(Map<String, quill.Attribute> attributes) {
    final result = <String, dynamic>{};
    for (final entry in attributes.entries) {
      result[entry.key] = entry.value.value;
    }
    return result;
  }
}

/// Adapter for unknown embed builder
class QuillUnknownEmbedBuilderAdapter extends quill.EmbedBuilder {
  final RichTextUnknownEmbedBuilder _unknownBuilder;

  QuillUnknownEmbedBuilderAdapter(this._unknownBuilder);

  @override
  String get key => _unknownBuilder.key;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final richTextContext = RichTextEmbedContext(
      controller: embedContext.controller,
      readOnly: embedContext.readOnly,
      node: _convertQuillEmbedNode(embedContext.node),
    );

    return _unknownBuilder.build(context, richTextContext);
  }

  RichTextEmbedNode _convertQuillEmbedNode(quill.Embed node) {
    final nodeData = node.value.toJson();
    String? embedType;
    dynamic embedData;

    for (final entry in nodeData.entries) {
      if (entry.key != 'attributes') {
        embedType = entry.key;
        embedData = entry.value;
        break;
      }
    }

    return RichTextEmbedNode(
      type: embedType ?? 'unknown',
      data: embedData,
      documentOffset: node.documentOffset,
      length: node.length,
      attributes: _convertQuillAttributes(node.style.attributes),
    );
  }

  Map<String, dynamic> _convertQuillAttributes(Map<String, quill.Attribute> attributes) {
    final result = <String, dynamic>{};
    for (final entry in attributes.entries) {
      result[entry.key] = entry.value.value;
    }
    return result;
  }
}
