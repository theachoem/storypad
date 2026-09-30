import 'package:collection/collection.dart';
import 'package:super_editor/super_editor.dart';

import '../embed/story_embed_codec.dart';
import '../embed/story_embed_node.dart';
import '../embed/story_embed_registry.dart';
import '../embed/unknown_embed.dart';
import '../markdown/markdown_format.dart';
import '../markdown/markdown_reader.dart';
import '../markdown/markdown_writer.dart';
import '../quill/quill_canonical.dart';
import '../quill/quill_exporter.dart';
import '../quill/quill_import_losses.dart';
import '../quill/quill_importer.dart';
import 'page_title.dart';

export 'page_title.dart' show normalizePageTitle, pageTitleLevel, pageTitleNode;

/// Converts documents to and from Markdown (the storage format), with a given set of embeds -- and from and to Quill
/// Delta, for stories stored in Quill.
/// Headless: no editor or widgets involved, so it's usable anywhere (services, tests, isolates).
///
/// ```dart
/// final codec = StoryCodec(embeds: [MediaEmbed(), AudioEmbed()]);
/// final document = codec.decode(markdown);
/// final markdown = codec.encode(document);
/// ```
///
/// `encode(decode(markdown))` is the canonical form of `markdown`, and encoding is a fixed point:
/// `encode(decode(encode(document))) == encode(document)`. Compare canonical Markdown (not the original text) to
/// decide whether a document changed.
final class StoryCodec {
  /// A codec for [embeds]. Throws an [ArgumentError] if the embeds conflict (see [StoryEmbedRegistry]).
  StoryCodec({List<StoryEmbedCodec> embeds = const [], UnknownEmbedCodec unknown = const UnknownEmbedCodec()})
    : this.fromRegistry(StoryEmbedRegistry(embeds, unknown: unknown));

  StoryCodec.fromRegistry(this.registry)
    : _reader = MarkdownReader(registry),
      _writer = MarkdownWriter(registry),
      _quill = QuillImporter(registry),
      _quillWriter = QuillExporter(registry, MarkdownWriter(registry));

  final StoryEmbedRegistry registry;
  final MarkdownReader _reader;
  final MarkdownWriter _writer;
  final QuillImporter _quill;
  final QuillExporter _quillWriter;

  /// Reads [markdown] into a new document (at least one node). The caller owns and disposes it.
  MutableDocument decode(String markdown) => MutableDocument(nodes: decodeNodes(markdown));

  /// Reads [markdown] into document nodes (at least one).
  List<DocumentNode> decodeNodes(String markdown) => _reader.read(markdown);

  /// Writes [nodes] (e.g. a [Document]) as canonical Markdown.
  String encode(Iterable<DocumentNode> nodes) => _writer.write(nodes);

  /// Converts Quill Delta ops (a stored story's JSON `ops` list) to canonical Markdown. Embeds convert through the
  /// embeds' `fromQuill`; anything unclaimed or rejected is preserved by the unknown embed. Never throws on malformed
  /// ops (they're skipped).
  String quillToMarkdown(List<Object?> ops) => encode(decodeQuill(ops));

  /// Imports Quill Delta ops as document nodes, exactly as [quillToMarkdown] sees them. Formatting Markdown can't
  /// store (e.g. font size) is dropped when the nodes are encoded.
  List<DocumentNode> decodeQuill(List<Object?> ops) => _quill.import(ops);

  /// The formatting in Quill ops that converting them ([quillToMarkdown], [decodeQuill]) would drop -- empty when the
  /// conversion is lossless. Text and embeds are never dropped (unknown embeds are preserved); only formatting is.
  List<QuillImportLoss> quillImportLosses(List<Object?> ops) => const QuillImportLossFinder().find(ops);

  /// Writes [nodes] as Quill Delta ops (JSON-ready maps) in the shapes StoryPad's Quill editor writes: the reverse of
  /// [decodeQuill], for storing a document edited here as Quill. Embeds are written through their `toQuill`.
  /// `decodeQuill(encodeQuill(nodes))` is equivalent to [nodes].
  List<Map<String, Object?>> encodeQuill(Iterable<DocumentNode> nodes) => _quillWriter.export(nodes);

  /// Converts Markdown to Quill Delta ops: [encodeQuill] of what [markdown] reads as. With canonical Markdown,
  /// `quillToMarkdown(markdownToQuill(markdown)) == markdown`.
  List<Map<String, Object?>> markdownToQuill(String markdown) => encodeQuill(decodeNodes(markdown));

  /// The canonical form of [markdown]: what it reads as, written back.
  String canonicalize(String markdown) => encode(decodeNodes(markdown));

  /// The title of the page [markdown] holds: its first block, if that's a heading, as plain text (see [pageTitleOf]).
  String? pageTitle(String markdown) => pageTitleOf(decodeNodes(markdown));

  /// A page's title: its first block, if that block is a heading (any level), as plain text -- formatting dropped,
  /// trimmed, `null` when empty. A heading further down (even after blank lines) is content, not a title.
  static String? pageTitleOf(Iterable<DocumentNode> nodes) => locatePageTitle(nodes.toList()).title;

  /// A page's body: [nodes] after the title heading, or all of them when the page has no title. An empty leading heading is an empty title, so it isn't part of the body either.
  static List<DocumentNode> pageBodyOf(Iterable<DocumentNode> nodes) {
    final list = nodes.toList();
    return list.sublist(locatePageTitle(list).bodyStart);
  }

  /// Converts a page stored as Quill -- a separate [title] plus body [ops] -- to one Markdown page: the title as a
  /// leading [pageTitleLevel] heading (see [pageTitleNode]; omitted when the title is empty), then the body.
  String quillPageToMarkdown(List<Object?> ops, {String? title}) {
    final heading = normalizePageTitle(title);
    return encode([if (heading != null) pageTitleNode(heading), ...decodeQuill(ops)]);
  }

  /// Whether converting a Quill page ([title] + [ops]) to Markdown keeps everything, for deciding whether the
  /// Markdown may replace the stored Quill. [markdown] is the conversion to check (default: [quillPageToMarkdown]).
  ///
  /// Checks three things: nothing is dropped ([quillImportLosses]); the title reads back as the same title; and the
  /// body written back as Quill is equivalent to [ops] (see [canonicalQuill]). The round trip catches converter bugs
  /// the loss report can't see (wrong nesting, reordering, a broken embed).
  QuillPageCheck checkQuillPage(List<Object?> ops, {String? title, String? markdown}) {
    final losses = quillImportLosses(ops);
    final expectedTitle = normalizePageTitle(title);
    final nodes = decodeNodes(markdown ?? quillPageToMarkdown(ops, title: title));

    var body = nodes;
    var titleRoundTrips = true;
    if (expectedTitle != null) {
      final first = nodes.firstOrNull;
      titleRoundTrips =
          first is ParagraphNode &&
          headerLevel(first.getMetadataValue(NodeMetadata.blockType)) == pageTitleLevel &&
          first.text.toPlainText() == expectedTitle &&
          first.text.spans.markers.isEmpty;
      if (titleRoundTrips) body = nodes.sublist(1);
    }

    final bodyRoundTrips =
        titleRoundTrips &&
        const DeepCollectionEquality().equals(canonicalQuill(encodeQuill(body), this), canonicalQuill(ops, this));
    return QuillPageCheck(losses: losses, titleRoundTrips: titleRoundTrips, bodyRoundTrips: bodyRoundTrips);
  }

  /// [markdown] as plain text (for search and word counts): one line per block, formatting removed, embeds as their
  /// `toPlainText`.
  String toPlainText(String markdown) => plainTextOf(decodeNodes(markdown));

  /// [nodes] as plain text: one line per block, formatting removed, embeds as their `toPlainText`.
  static String plainTextOf(Iterable<DocumentNode> nodes) {
    return nodes
        .map(
          (node) => switch (node) {
            TextNode() => node.text.toPlainText(includePlaceholders: false),
            StoryEmbedNode() => node.plainText,
            ImageNode() => node.altText,
            _ => '',
          },
        )
        .join('\n');
  }
}

/// The result of [StoryCodec.checkQuillPage]: whether a Quill page converts to Markdown without losing anything.
final class QuillPageCheck {
  const QuillPageCheck({required this.losses, required this.titleRoundTrips, required this.bodyRoundTrips});

  /// Formatting the conversion drops (see [StoryCodec.quillImportLosses]).
  final List<QuillImportLoss> losses;

  /// Whether the Markdown's leading heading reads back as exactly the page's title (always true without a title).
  final bool titleRoundTrips;

  /// Whether the Markdown's body, written back as Quill, is equivalent to the original ops. `false` when the title
  /// didn't round-trip (the body can't be told apart then).
  final bool bodyRoundTrips;

  /// Whether the Markdown may replace the stored Quill: no losses, and both title and body round-trip.
  bool get isLossless => losses.isEmpty && titleRoundTrips && bodyRoundTrips;

  @override
  String toString() =>
      'QuillPageCheck(losses: ${losses.length}, titleRoundTrips: $titleRoundTrips, bodyRoundTrips: $bodyRoundTrips)';
}
