import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:storypad_editor/storypad_editor.dart';

/// Test-only embeds exercising the embed contract the way an app's embeds would, without depending on the example
/// app's demo embeds.

/// The simplest embed: a String value, one Quill key, one custom tag.
///
/// Quill: `{"sticker": "cat"}`. Markdown: `<sp-sticker name="cat"></sp-sticker>`.
class StickerEmbedCodec extends StoryEmbed<String> {
  const StickerEmbedCodec();

  @override
  String get type => 'sticker';

  @override
  Set<String> get quillKeys => const {'sticker'};

  @override
  Set<String> get htmlTags => const {'sp-sticker'};

  @override
  String? fromQuill(QuillEmbedOp op) {
    final value = op.value;
    return value is String && value.isNotEmpty ? value : null;
  }

  @override
  String? fromHtml(StoryHtmlElement element) {
    final name = element['name'];
    return name == null || name.isEmpty ? null : name;
  }

  @override
  StoryHtmlElement toHtml(String value) => StoryHtmlElement('sp-sticker', attributes: {'name': value});

  @override
  String toPlainText(String value) => ':$value:';

  @override
  Widget build(BuildContext context, StoryEmbedContext<String> embed) {
    return GestureDetector(
      key: ValueKey('sticker-${embed.nodeId}'),
      onTap: embed.readOnly ? null : () => embed.update((current) => '$current!'),
      child: Text(
        'sticker ${embed.value}${embed.isSelected ? ' (selected)' : ''}${embed.readOnly ? ' (read-only)' : ''}',
      ),
    );
  }
}

enum GalleryAlignment { none, left, center, right }

enum GallerySize { normal, max }

const galleryAlignment = StoryEmbedAttribute<GalleryAlignment>.enumeration(
  quillKey: 'x-align',
  htmlName: 'data-align',
  values: {GalleryAlignment.left: 'left', GalleryAlignment.center: 'center', GalleryAlignment.right: 'right'},
  fallback: GalleryAlignment.none,
);

const gallerySize = StoryEmbedAttribute<GallerySize>.enumeration(
  quillKey: 'x-size',
  htmlName: 'data-size',
  values: {GallerySize.normal: 'default', GallerySize.max: 'max'},
  fallback: GallerySize.normal,
);

/// A multi-field value with typed attributes.
class GalleryValue {
  const GalleryValue(this.paths, {this.alignment = GalleryAlignment.none, this.size = GallerySize.normal});

  final List<String> paths;
  final GalleryAlignment alignment;
  final GallerySize size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GalleryValue &&
          const ListEquality<String>().equals(paths, other.paths) &&
          alignment == other.alignment &&
          size == other.size;

  @override
  int get hashCode => Object.hash(const ListEquality<String>().hash(paths), alignment, size);

  @override
  String toString() => 'GalleryValue($paths, $alignment, $size)';
}

/// A multi-key, multi-tag embed with typed attributes, shaped like StoryPad's media/album embed:
///
/// - Quill: `{"gallery": "a.jpg|b.jpg"}` or the legacy `{"photo": "a.jpg"}`, with `x-align`/`x-size` attributes.
/// - Markdown: a single path is `<img src>` (so a bare `![](a.jpg)` also reads back); 2+ paths are
///   `<sp-gallery><img src="a.jpg"><img src="b.jpg"></sp-gallery>`.
class GalleryEmbedCodec extends StoryEmbed<GalleryValue> {
  const GalleryEmbedCodec();

  @override
  String get type => 'gallery';

  @override
  Set<String> get quillKeys => const {'gallery', 'photo'};

  @override
  Set<String> get htmlTags => const {'img', 'sp-gallery'};

  @override
  GalleryValue? fromQuill(QuillEmbedOp op) {
    final value = op.value;
    if (value is! String) return null;
    final paths = value.split('|').where((path) => path.isNotEmpty).toList();
    if (paths.isEmpty) return null;
    return GalleryValue(paths, alignment: op.attribute(galleryAlignment), size: op.attribute(gallerySize));
  }

  @override
  GalleryValue? fromHtml(StoryHtmlElement element) {
    final paths = switch (element.tag) {
      'img' => [?element['src']],
      _ => [for (final child in element.children) ?child['src']],
    }.where((path) => path.isNotEmpty).toList();
    if (paths.isEmpty) return null;
    return GalleryValue(paths, alignment: element.attribute(galleryAlignment), size: element.attribute(gallerySize));
  }

  @override
  StoryHtmlElement toHtml(GalleryValue value) {
    final attributes = {...galleryAlignment.toHtml(value.alignment), ...gallerySize.toHtml(value.size)};
    if (value.paths.length == 1) {
      return StoryHtmlElement('img', attributes: {'src': value.paths.single, ...attributes});
    }
    return StoryHtmlElement(
      'sp-gallery',
      attributes: attributes,
      children: [
        for (final path in value.paths) StoryHtmlElement('img', attributes: {'src': path}),
      ],
    );
  }

  @override
  String toPlainText(GalleryValue value) => value.paths.join(' ');

  @override
  Widget build(BuildContext context, StoryEmbedContext<GalleryValue> embed) {
    return Text('gallery ${embed.value.paths.join(',')}', key: ValueKey('gallery-${embed.nodeId}'));
  }
}

const testEmbeds = <StoryEmbed>[StickerEmbedCodec(), GalleryEmbedCodec()];

const testEmbedCodecs = <StoryEmbedCodec>[StickerEmbedCodec(), GalleryEmbedCodec()];
