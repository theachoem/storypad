import 'package:super_editor/super_editor.dart';

import 'quill_embed_op.dart';
import 'story_embed_node.dart';
import 'story_html_element.dart';

/// Everything the package needs to know about one kind of embed, except how it looks: its Quill import, its
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
    return StoryEmbedNode(id: id ?? Editor.createNodeId(), type: type, value: value, plainText: toPlainText(value));
  }

  /// A copy of [node] holding [value] instead.
  StoryEmbedNode replaceValue(StoryEmbedNode node, T value) {
    return node.copyWithValue(value, plainText: toPlainText(value));
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

  /// [fromQuill], wrapped into a node.
  StoryEmbedNode? nodeFromQuill(QuillEmbedOp op, {String? id}) {
    final value = fromQuill(op);
    return value == null ? null : createNode(value, id: id);
  }

  /// [fromHtml], wrapped into a node.
  StoryEmbedNode? nodeFromHtml(StoryHtmlElement element, {String? id}) {
    final value = fromHtml(element);
    return value == null ? null : createNode(value, id: id);
  }

  @override
  String toString() => '$runtimeType($type)';
}
