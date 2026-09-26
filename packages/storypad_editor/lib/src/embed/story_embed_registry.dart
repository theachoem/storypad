import 'package:super_editor/super_editor.dart';

import 'story_embed_codec.dart';
import 'story_embed_node.dart';
import 'unknown_embed.dart';

/// The resolved set of embeds one codec/controller works with: the app's embeds in registration order, then the
/// built-in [UnknownEmbedCodec] last.
///
/// Validates everything up front and throws an [ArgumentError] naming the offending embeds, so a misconfiguration
/// fails at construction instead of as a silently misparsed document later.
final class StoryEmbedRegistry {
  StoryEmbedRegistry(Iterable<StoryEmbedCodec> embeds, {this.unknown = const UnknownEmbedCodec()})
    : embeds = List.unmodifiable([...embeds, unknown]) {
    for (final embed in this.embeds) {
      _register(embed);
    }
  }

  /// Block type names super_editor (or this package) already uses for its own nodes.
  static const reservedTypes = {
    'paragraph',
    'header1',
    'header2',
    'header3',
    'header4',
    'header5',
    'header6',
    'blockquote',
    'code',
    'listItem',
    'task',
    'horizontalRule',
    'image',
    'tableBlock',
  };

  /// Tags the Markdown codec uses for text formatting and structure, which an embed can't claim.
  static const reservedTags = {
    'a',
    'b',
    'br',
    'code',
    'del',
    'div',
    'em',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'hr',
    'i',
    'li',
    'mark',
    'ol',
    'p',
    'pre',
    's',
    'span',
    'strong',
    'sub',
    'sup',
    'u',
    'ul',
    'sp-embed',
  };

  static final _namePattern = RegExp(r'^[a-z][a-z0-9-]*$');

  /// Every embed, the app's first (in registration order), [unknown] last.
  final List<StoryEmbedCodec> embeds;

  /// The catch-all embed.
  final UnknownEmbedCodec unknown;

  final _byType = <String, StoryEmbedCodec>{};
  final _byQuillKey = <String, StoryEmbedCodec>{};
  final _byHtmlTag = <String, StoryEmbedCodec>{};

  /// Every HTML tag claimed by a registered embed (including `sp-unknown`).
  Iterable<String> get htmlTags => _byHtmlTag.keys;

  void _register(StoryEmbedCodec embed) {
    final isUnknown = identical(embed, unknown);

    final type = embed.type;
    if (!_namePattern.hasMatch(type)) {
      throw ArgumentError('Embed $embed has invalid type "$type": use lowercase [a-z][a-z0-9-]*.');
    }
    if (reservedTypes.contains(type) || (!isUnknown && type == UnknownEmbedCodec.embedType)) {
      throw ArgumentError('Embed $embed uses the reserved type "$type".');
    }
    final existingType = _byType[type];
    if (existingType != null) {
      throw ArgumentError('Embeds $existingType and $embed both use the type "$type".');
    }
    _byType[type] = embed;

    for (final key in embed.quillKeys) {
      final existing = _byQuillKey[key];
      if (existing != null) {
        throw ArgumentError('Embeds $existing and $embed both import the Quill key "$key".');
      }
      _byQuillKey[key] = embed;
    }

    for (final tag in embed.htmlTags) {
      if (!_namePattern.hasMatch(tag)) {
        throw ArgumentError('Embed $embed claims invalid HTML tag "$tag": use lowercase [a-z][a-z0-9-]*.');
      }
      if (reservedTags.contains(tag) || (!isUnknown && tag == UnknownEmbedCodec.htmlTag)) {
        throw ArgumentError('Embed $embed claims the reserved HTML tag "<$tag>".');
      }
      final existing = _byHtmlTag[tag];
      if (existing != null) {
        throw ArgumentError('Embeds $existing and $embed both claim the HTML tag "<$tag>".');
      }
      _byHtmlTag[tag] = embed;
    }
  }

  /// The embed with [type], if registered.
  StoryEmbedCodec? byType(String type) => _byType[type];

  /// The embed importing the Quill key [key], if any. Unregistered keys go to [unknown].
  StoryEmbedCodec? byQuillKey(String key) => _byQuillKey[key];

  /// The embed claiming the HTML tag [tag] (lowercase), if any.
  StoryEmbedCodec? byHtmlTag(String tag) => _byHtmlTag[tag];

  /// The embed owning [node], if it's a [StoryEmbedNode] of a registered type.
  StoryEmbedCodec? forNode(DocumentNode node) => node is StoryEmbedNode ? _byType[node.type] : null;
}
