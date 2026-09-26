import 'package:collection/collection.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:meta/meta.dart';

import 'story_embed_attribute.dart';

/// One HTML element, as an embed reads it from Markdown ([StoryEmbedCodec.fromHtml]) and writes it back
/// ([StoryEmbedCodec.toHtml]).
///
/// Embeds never build HTML strings themselves: [render] owns escaping (attribute values and text) and guarantees the
/// result is a single line, which the Markdown block syntax depends on -- an embed is always exactly one line of
/// Markdown source.
///
/// Children are supported for container tags (e.g. an album wrapping `<img>`s). Mixed content (text interleaved with
/// child elements) is not: an element has either [children] or [text].
@immutable
final class StoryHtmlElement {
  StoryHtmlElement(
    this.tag, {
    Map<String, String> attributes = const {},
    List<StoryHtmlElement> children = const [],
    this.text,
  }) : attributes = Map.unmodifiable(attributes),
       children = List.unmodifiable(children),
       rawHtml = null {
    if (!_tagPattern.hasMatch(tag)) {
      throw ArgumentError.value(tag, 'tag', 'must be a lowercase HTML tag name ([a-z][a-z0-9-]*)');
    }
    for (final name in attributes.keys) {
      if (!_attributeNamePattern.hasMatch(name)) {
        throw ArgumentError.value(name, 'attributes', 'invalid HTML attribute name');
      }
    }
    if (text != null && children.isNotEmpty) {
      throw ArgumentError('An element has either children or text, not both.');
    }
  }

  /// An escape hatch: [html] is written to Markdown verbatim, unescaped. Only used to preserve lines the codec
  /// couldn't understand (see `UnknownEmbedValue`). It must be a single line.
  StoryHtmlElement.raw(String html)
    : tag = '',
      attributes = const {},
      children = const [],
      text = null,
      rawHtml = html {
    if (html.contains('\n') || html.contains('\r')) {
      throw ArgumentError.value(html, 'html', 'must be a single line');
    }
  }

  /// Converts a `package:html` element (as parsed from Markdown source) into a [StoryHtmlElement].
  factory StoryHtmlElement.fromDom(dom.Element element) {
    final children = element.children.map(StoryHtmlElement.fromDom).toList();
    final text = element.text;
    return StoryHtmlElement(
      element.localName!.toLowerCase(),
      attributes: {for (final entry in element.attributes.entries) entry.key.toString(): entry.value},
      children: children,
      text: children.isEmpty && text.isNotEmpty ? text : null,
    );
  }

  /// Parses the first element in [html], or returns `null` if there is none.
  static StoryHtmlElement? tryParse(String html) {
    final element = html_parser.parseFragment(html).nodes.whereType<dom.Element>().firstOrNull;
    return element == null ? null : StoryHtmlElement.fromDom(element);
  }

  /// Parses [html] only if it is exactly one element (surrounding whitespace allowed), e.g. a whole Markdown line
  /// holding one embed. Returns `null` for anything else, including an element followed by text.
  static StoryHtmlElement? tryParseSingle(String html) {
    final nodes = html_parser
        .parseFragment(html)
        .nodes
        .where((node) => node is! dom.Text || node.text.trim().isNotEmpty);
    if (nodes.length != 1) return null;
    final node = nodes.single;
    return node is dom.Element ? StoryHtmlElement.fromDom(node) : null;
  }

  static final _tagPattern = RegExp(r'^[a-z][a-z0-9-]*$');
  static final _attributeNamePattern = RegExp(r'^[a-zA-Z_:][-a-zA-Z0-9_:.]*$');

  /// Elements that have no closing tag.
  static const voidTags = {
    'area',
    'base',
    'br',
    'col',
    'embed',
    'hr',
    'img',
    'input',
    'link',
    'meta',
    'param',
    'source',
    'track',
    'wbr',
  };

  /// Lowercase tag name, e.g. `img`. Empty for a [StoryHtmlElement.raw] element.
  final String tag;

  /// Attributes, in insertion order (which is also render order).
  final Map<String, String> attributes;

  final List<StoryHtmlElement> children;

  /// Text content, for a leaf element like `<time>2024-01-01</time>`.
  final String? text;

  /// Non-null only for a [StoryHtmlElement.raw] element.
  final String? rawHtml;

  bool get isRaw => rawHtml != null;

  /// The raw string value of the attribute [name], if present.
  String? operator [](String name) => attributes[name];

  /// Reads a typed attribute, falling back to [StoryEmbedAttribute.fallback] when it's absent or unrecognized.
  A attribute<A extends Object>(StoryEmbedAttribute<A> attribute) => attribute.readHtml(this);

  /// Renders this element as a single line of escaped HTML.
  String render() {
    if (rawHtml != null) return rawHtml!;

    final buffer = StringBuffer('<$tag');
    for (final MapEntry(:key, :value) in attributes.entries) {
      buffer.write(' $key="${escapeAttribute(value)}"');
    }
    buffer.write('>');

    if (voidTags.contains(tag)) return buffer.toString();

    if (text != null) buffer.write(escapeText(text!));
    for (final child in children) {
      buffer.write(child.render());
    }
    buffer.write('</$tag>');
    return buffer.toString();
  }

  /// Escapes an attribute value for use inside double quotes. Newlines become character references so the output
  /// stays on one line.
  static String escapeAttribute(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('\n', '&#10;')
      .replaceAll('\r', '&#13;');

  /// Escapes element text content. Newlines become character references so the output stays on one line.
  static String escapeText(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('\n', '&#10;')
      .replaceAll('\r', '&#13;');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryHtmlElement &&
          tag == other.tag &&
          text == other.text &&
          rawHtml == other.rawHtml &&
          const MapEquality<String, String>().equals(attributes, other.attributes) &&
          const ListEquality<StoryHtmlElement>().equals(children, other.children);

  @override
  int get hashCode => Object.hash(
    tag,
    text,
    rawHtml,
    const MapEquality<String, String>().hash(attributes),
    const ListEquality<StoryHtmlElement>().hash(children),
  );

  @override
  String toString() => render();
}
