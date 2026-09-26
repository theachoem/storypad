import 'package:super_editor/super_editor.dart';

import '../embed/story_embed_codec.dart';
import '../embed/story_embed_registry.dart';
import '../embed/unknown_embed.dart';
import '../markdown/markdown_reader.dart';
import '../markdown/markdown_writer.dart';

/// Converts documents to and from Markdown (the only format this package writes), with a given set of embeds.
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

  StoryCodec.fromRegistry(this.registry) : _reader = MarkdownReader(registry), _writer = MarkdownWriter(registry);

  final StoryEmbedRegistry registry;
  final MarkdownReader _reader;
  final MarkdownWriter _writer;

  /// Reads [markdown] into a new document (at least one node). The caller owns and disposes it.
  MutableDocument decode(String markdown) => MutableDocument(nodes: decodeNodes(markdown));

  /// Reads [markdown] into document nodes (at least one).
  List<DocumentNode> decodeNodes(String markdown) => _reader.read(markdown);

  /// Writes [nodes] (e.g. a [Document]) as canonical Markdown.
  String encode(Iterable<DocumentNode> nodes) => _writer.write(nodes);

  /// The canonical form of [markdown]: what it reads as, written back.
  String canonicalize(String markdown) => encode(decodeNodes(markdown));
}
