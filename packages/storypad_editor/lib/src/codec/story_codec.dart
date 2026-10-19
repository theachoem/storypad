import 'package:collection/collection.dart';
import 'package:super_editor/super_editor.dart';

import '../embed/story_embed_codec.dart';
import '../embed/story_embed_node.dart';
import '../embed/story_embed_registry.dart';
import '../embed/unknown_embed_codec.dart';
import '../markdown/markdown_format.dart';
import '../markdown/markdown_reader.dart';
import '../markdown/markdown_writer.dart';
import '../quill/quill_canonical.dart';
import '../quill/quill_exporter.dart';
import '../quill/quill_import_loss.dart';
import '../quill/quill_import_loss_finder.dart';
import '../quill/quill_importer.dart';
import 'page_title.dart';
import 'quill_page_check.dart';
import '../document/heading.dart';

export 'page_title.dart';
export 'quill_page_check.dart';

/// Converts documents to and from Markdown (the storage format), with a given set of embeds -- and from and to Quill
/// Delta: from it for pages stored as Quill before Markdown, to it for readers built on Quill.
/// Headless: no editor or widgets involved, so it's usable anywhere (services, tests, isolates).
///
/// ```dart
/// final codec = StoryCodec(embeds: [MediaEmbed(), AudioEmbed()]);
/// final nodes = codec.decodeNodes(markdown);
/// final markdown = codec.encode(nodes);
/// ```
///
/// `encode(decodeNodes(markdown))` is the canonical form of `markdown`, and encoding is a fixed point:
/// `encode(decodeNodes(encode(nodes))) == encode(nodes)`. Compare canonical Markdown (not the original text) to
/// decide whether a document changed.
final class StoryCodec {
  /// A codec for [embeds]. Throws an [ArgumentError] if the embeds conflict (see [StoryEmbedRegistry]).
  StoryCodec({
    List<StoryEmbedCodec> embeds = const [],
    UnknownEmbedCodec unknown = const UnknownEmbedCodec(),
    bool dropQuillSpacingLines = false,
  }) : this.fromRegistry(StoryEmbedRegistry(embeds, unknown: unknown), dropQuillSpacingLines: dropQuillSpacingLines);

  StoryCodec.fromRegistry(this.registry, {this.dropQuillSpacingLines = false})
    : _reader = MarkdownReader(registry),
      _writer = MarkdownWriter(registry),
      _quill = QuillImporter(registry),
      _quillWriter = QuillExporter(registry, MarkdownWriter(registry));

  final StoryEmbedRegistry registry;

  /// Whether converting a Quill page ([quillPageToMarkdown]) drops the empty lines writers added only to space embeds
  /// out: at most one plain empty line directly above, and one directly below, each embed (see
  /// [dropSpacingLinesAroundEmbeds]). For an editor whose embeds get space of their own (`StoryEditorSpacing`), where
  /// those lines would double it. Off by default: the conversion keeps every line.
  final bool dropQuillSpacingLines;
  final MarkdownReader _reader;
  final MarkdownWriter _writer;
  final QuillImporter _quill;
  final QuillExporter _quillWriter;

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

  /// Writes [nodes] as Quill Delta ops (JSON-ready maps) in the shapes StoryPad's Quill editor wrote: the reverse of
  /// [decodeQuill], for readers built on Quill and [checkQuillPage]'s round trip. Embeds are written through their
  /// `toQuill`. `decodeQuill(encodeQuill(nodes))` is equivalent to [nodes].
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
  static String? pageTitleOf(Iterable<DocumentNode> nodes) => PageTitle.locate(nodes.toList()).title;

  /// A page's body: [nodes] after the title heading, or all of them when the page has no title. An empty leading
  /// heading is an empty title, so it isn't part of the body either.
  static List<DocumentNode> pageBodyOf(Iterable<DocumentNode> nodes) {
    final list = nodes.toList();
    return list.sublist(PageTitle.locate(list).bodyStart);
  }

  /// Converts a page stored as Quill -- a separate [title] plus body [ops] -- to one Markdown page: the title as a
  /// leading [PageTitle.level] heading (see [PageTitle.node]; omitted when the title is empty), then the body.
  String quillPageToMarkdown(List<Object?> ops, {String? title}) {
    final heading = PageTitle.normalize(title);
    // Quill always ends with a line break: an empty page reads as one empty line, which isn't a blank line of content.
    final imported = decodeQuill(ops);
    final blank = imported.length == 1 && MarkdownFormat.isEmptyParagraph(imported.single);
    final body = dropQuillSpacingLines ? dropSpacingLinesAroundEmbeds(imported) : imported;
    return encode([if (heading != null) PageTitle.node(heading), if (!blank) ...body]);
  }

  /// [nodes] without the empty lines that only space embeds out: at most one plain empty line
  /// ([MarkdownFormat.isEmptyParagraph]: no text, style, alignment or indent) directly above each embed, and one
  /// directly below. A line between two embeds spaces both, and goes once; a second empty line stays (more room, on
  /// purpose).
  static List<DocumentNode> dropSpacingLinesAroundEmbeds(List<DocumentNode> nodes) {
    final dropped = <int>{};
    for (var i = 0; i < nodes.length; i++) {
      if (nodes[i] is! StoryEmbedNode) continue;
      if (i > 0 && MarkdownFormat.isEmptyParagraph(nodes[i - 1])) dropped.add(i - 1);
      if (i + 1 < nodes.length && MarkdownFormat.isEmptyParagraph(nodes[i + 1])) dropped.add(i + 1);
    }
    return [
      for (var i = 0; i < nodes.length; i++)
        if (!dropped.contains(i)) nodes[i],
    ];
  }

  /// Whether converting a Quill page ([title] + [ops]) to Markdown keeps everything, for deciding whether the
  /// Markdown may replace the stored Quill. [markdown] is the conversion to check (default: [quillPageToMarkdown]).
  ///
  /// Checks three things: nothing is dropped ([quillImportLosses]); the title reads back as the same title; and the
  /// body written back as Quill is equivalent to [ops] (see [QuillCanonical]). The round trip catches converter bugs
  /// the loss report can't see (wrong nesting, reordering, a broken embed).
  ///
  /// Nothing is lost, but one thing can read differently afterwards, by design: a page with no title whose body
  /// starts with a heading. After conversion that heading is the page's first block, so it reads as its title
  /// ([pageTitleOf]), and no longer as the start of its body ([pageBodyOf]).
  ///
  /// With [dropQuillSpacingLines], the round trip is checked on the conversion that keeps every line, and [markdown]
  /// must then be exactly that conversion without the spacing lines -- so dropping them can't hide a converter bug,
  /// and nothing but those lines goes.
  QuillPageCheck checkQuillPage(List<Object?> ops, {String? title, String? markdown}) {
    final losses = quillImportLosses(ops);
    final expectedTitle = PageTitle.normalize(title);
    final converted = markdown ?? quillPageToMarkdown(ops, title: title);
    final nodes = dropQuillSpacingLines ? decodeNodes(_keepingEveryLine(ops, title)) : decodeNodes(converted);
    final droppedOnlySpacing =
        !dropQuillSpacingLines ||
        // A title is a heading, never an empty line: dropping over the whole page drops the body's lines.
        canonicalize(converted) == encode(dropSpacingLinesAroundEmbeds(nodes));

    var body = nodes;
    var titleRoundTrips = true;
    if (expectedTitle != null) {
      final first = nodes.firstOrNull;
      titleRoundTrips =
          first is ParagraphNode &&
          Heading.levelOf(first.getMetadataValue(NodeMetadata.blockType)) == PageTitle.level &&
          first.text.toPlainText() == expectedTitle &&
          first.text.spans.markers.isEmpty;
      if (titleRoundTrips) body = nodes.sublist(1);
    }

    final bodyRoundTrips =
        titleRoundTrips &&
        droppedOnlySpacing &&
        const DeepCollectionEquality().equals(QuillCanonical(this).of(encodeQuill(body)), QuillCanonical(this).of(ops));
    return QuillPageCheck(losses: losses, titleRoundTrips: titleRoundTrips, bodyRoundTrips: bodyRoundTrips);
  }

  /// [quillPageToMarkdown] keeping every line.
  String _keepingEveryLine(List<Object?> ops, String? title) =>
      StoryCodec.fromRegistry(registry).quillPageToMarkdown(ops, title: title);

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
