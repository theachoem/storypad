import 'package:flutter/foundation.dart';
import 'package:super_editor/super_editor.dart';

import 'quill_embed_op.dart';
import 'story_embed_node.dart';
import 'story_html_element.dart';

/// Everything the package needs to know about one kind of embed, except how it looks: its Quill form, its
/// Markdown (HTML) form, and its plain text. Headless -- usable from converters, tests and isolates.
///
/// `StoryEmbed` extends this with a `build` method for rendering; pass `StoryEmbed`s to the editor controller, and
/// codec-only instances wherever no editor is involved (e.g. a one-off Quill → Markdown conversion, or an export codec
/// configured differently from the editor's).
///
/// [T] is the embed's value type. It must be immutable and have value equality (`==`/`hashCode`), since that's how
/// edits are detected and documents compared -- a record of primitives, or a class with `==`.
///
/// ```dart
/// class DateEmbedCodec extends StoryEmbedCodec<DateTime> {
///   const DateEmbedCodec();
///
///   @override String get type => 'date';
///   @override Set<String> get quillKeys => const {'date'};
///   @override Set<String> get htmlTags => const {'time'};
///
///   @override
///   DateTime? fromQuill(QuillEmbedOp op) => DateTime.tryParse('${op.value}');
///
///   @override
///   QuillEmbedOp toQuill(DateTime value) => QuillEmbedOp.of('date', value.toIso8601String());
///
///   @override
///   DateTime? fromHtml(StoryHtmlElement element) => DateTime.tryParse(element['datetime'] ?? '');
///
///   @override
///   StoryHtmlElement toHtml(DateTime value) =>
///       StoryHtmlElement('time', attributes: {'datetime': value.toIso8601String()}, text: value.toIso8601String());
/// }
/// ```
abstract class StoryEmbedCodec<T extends Object> {
  const StoryEmbedCodec();

  /// Unique embed type, e.g. `media`. Also the node's block type (see [StoryEmbedNode]). Lowercase
  /// (`[a-z][a-z0-9-]*`), and not one of the reserved names super_editor uses for its own blocks.
  String get type;

  /// Quill embed insert keys this embed imports, e.g. `{'media', 'image'}` (a current and a legacy key). Empty if the
  /// embed has no Quill form.
  Set<String> get quillKeys => const {};

  /// Block-level HTML tags this embed claims in Markdown, e.g. `{'img', 'video', 'sp-album'}`. Every tag [toHtml] can
  /// produce at the top level must be listed here, or the embed won't read back. Prefer an `sp-` prefix for custom
  /// elements.
  Set<String> get htmlTags;

  /// Builds a value from a Quill op matched on one of [quillKeys], or returns `null` if the op is malformed -- the
  /// unknown embed then preserves it losslessly instead.
  T? fromQuill(QuillEmbedOp op) => null;

  /// The Quill op for [value] -- the mirror of [fromQuill], used when a document is written back as Quill Delta
  /// (`StoryCodec.encodeQuill`). `fromQuill(toQuill(value))` must equal [value]; `expectEmbedRoundTrip` checks it.
  ///
  /// `null` (the default) for an embed with no Quill form: it's then written as a line of its Markdown under the
  /// package's `sp-markdown` key, which reads back losslessly but that a plain Quill editor shows as an unknown embed.
  QuillEmbedOp? toQuill(T value) => null;

  /// Builds a value from a Markdown HTML line whose tag is one of [htmlTags], or returns `null` if it's malformed --
  /// the unknown embed then preserves the line verbatim instead.
  T? fromHtml(StoryHtmlElement element);

  /// The Markdown form of [value]: one HTML element, rendered as a single escaped line by the package.
  ///
  /// Special case: an `img` element with only a `src` (and optionally `alt`) is written as Markdown's own
  /// `![alt](src)`, and a bare `![alt](src)` in Markdown is read back through the embed claiming `img`.
  StoryHtmlElement toHtml(T value);

  /// [value] as plain text, for search, word counts, and copying to the clipboard. Empty by default.
  String toPlainText(T value) => '';

  /// Creates a document node holding [value]. Use this rather than constructing [StoryEmbedNode] directly, so the
  /// node's plain text stays in sync with its value.
  StoryEmbedNode createNode(T value, {String? id}) {
    return StoryEmbedNode(id: id ?? Editor.createNodeId(), type: type, value: value, plainText: _plainTextOf(value));
  }

  /// A copy of [node] holding [value] instead.
  StoryEmbedNode replaceValue(StoryEmbedNode node, T value) {
    return node.copyWithValue(value, plainText: _plainTextOf(value));
  }

  /// [toPlainText], or nothing if the embed throws: plain text is derived, so it must never block a document.
  String _plainTextOf(T value) {
    try {
      return toPlainText(value);
    } catch (error, stackTrace) {
      FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stackTrace, library: 'storypad_editor'));
      return '';
    }
  }

  /// Whether [node] is one of this embed's nodes.
  bool handles(DocumentNode node) => node is StoryEmbedNode && node.type == type;

  /// The typed value of one of this embed's nodes.
  T valueOf(StoryEmbedNode node) {
    assert(node.type == type, 'Node ${node.id} is a "${node.type}" embed, not "$type".');
    return node.value as T;
  }

  // Untyped trampolines, so callers holding a `StoryEmbedCodec<Object>` never have to cast `T` themselves.

  /// [toHtml] for a node of this embed.
  StoryHtmlElement toHtmlOf(StoryEmbedNode node) => toHtml(valueOf(node));

  /// [toQuill] for a node of this embed, or `null` if the embed has no Quill form or throws (reported, and the node is
  /// then written as Markdown instead).
  QuillEmbedOp? toQuillOf(StoryEmbedNode node) {
    try {
      return toQuill(valueOf(node));
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'storypad_editor',
          context: ErrorDescription('while writing a "$type" embed to Quill (${node.value}); written as Markdown'),
        ),
      );
      return null;
    }
  }

  /// [fromQuill], wrapped into a node. An exception from the embed counts as a rejection (`null`), so the content goes
  /// to the unknown embed instead of aborting the whole import.
  StoryEmbedNode? nodeFromQuill(QuillEmbedOp op, {String? id}) => _guarded('fromQuill', op, () {
    final value = fromQuill(op);
    return value == null ? null : createNode(value, id: id);
  });

  /// [fromHtml], wrapped into a node. An exception from the embed counts as a rejection (`null`), so the line goes to
  /// the unknown embed instead of aborting the whole decode.
  StoryEmbedNode? nodeFromHtml(StoryHtmlElement element, {String? id}) => _guarded('fromHtml', element, () {
    final value = fromHtml(element);
    return value == null ? null : createNode(value, id: id);
  });

  StoryEmbedNode? _guarded(String method, Object input, StoryEmbedNode? Function() read) {
    try {
      return read();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'storypad_editor',
          context: ErrorDescription('while reading a "$type" embed ($method: $input); kept as unknown content instead'),
        ),
      );
      return null;
    }
  }

  @override
  String toString() => '$runtimeType($type)';
}
