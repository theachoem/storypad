import 'package:storypad_editor/storypad_editor.dart';

import 'embed_attributes.dart';

/// One or more photos/videos (an "album" when there's more than one), with size and alignment.
class MediaValue {
  const MediaValue(this.paths, {this.size = EmbedSize.normal, this.alignment = EmbedAlignment.none});

  /// Relative asset paths, e.g. `images/1762500783746.jpg`, `videos/1762500783747.mp4`. Never empty (the codec
  /// rejects an empty value, so the unknown embed preserves it instead).
  final List<String> paths;
  final EmbedSize size;
  final EmbedAlignment alignment;

  bool get isAlbum => paths.length > 1;

  MediaValue copyWith({List<String>? paths, EmbedSize? size, EmbedAlignment? alignment}) {
    return MediaValue(paths ?? this.paths, size: size ?? this.size, alignment: alignment ?? this.alignment);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MediaValue || size != other.size || alignment != other.alignment) return false;
    if (paths.length != other.paths.length) return false;
    for (var i = 0; i < paths.length; i++) {
      if (paths[i] != other.paths[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(paths), size, alignment);

  @override
  String toString() => 'MediaValue($paths, $size, $alignment)';
}

/// Whether [path] is a video, by StoryPad's asset folder convention.
bool isVideoPath(String path) => path.startsWith('videos/');

/// StoryPad's media embed.
///
/// - Quill: `{"media": "images/a.jpg|videos/b.mp4"}` (or the legacy `image` key, interchangeable), with
///   `custom-embed-size`/`custom-embed-alignment` attributes.
/// - Markdown: a single photo is `<img src>` (so a bare `![](images/a.jpg)` when it has no attributes); a single video
///   `<video controls src>`; an album `<sp-album>` wrapping `<img>`/`<video>` children, which still show in a renderer
///   that doesn't know `<sp-album>`.
class MediaEmbed extends StoryEmbedCodec<MediaValue> {
  const MediaEmbed();

  @override
  String get type => 'media';

  @override
  Set<String> get quillKeys => const {'media', 'image'};

  @override
  Set<String> get htmlTags => const {'img', 'video', 'sp-album'};

  @override
  MediaValue? fromQuill(QuillEmbedOp op) {
    final value = op.value;
    if (value is! String) return null;

    final paths = value.split('|').where((path) => path.isNotEmpty).toList();
    if (paths.isEmpty) return null;
    return MediaValue(paths, size: op.attribute(embedSize), alignment: op.attribute(embedAlignment));
  }

  @override
  MediaValue? fromHtml(StoryHtmlElement element) {
    final sources = element.tag == 'sp-album' ? element.children : [element];
    final paths = [
      for (final source in sources)
        if (source['src'] case final src? when src.isNotEmpty) src,
    ];
    if (paths.isEmpty) return null;
    return MediaValue(paths, size: element.attribute(embedSize), alignment: element.attribute(embedAlignment));
  }

  @override
  StoryHtmlElement toHtml(MediaValue value) {
    final attributes = {...embedSize.toHtml(value.size), ...embedAlignment.toHtml(value.alignment)};
    if (!value.isAlbum) return _source(value.paths.single, attributes);
    return StoryHtmlElement(
      'sp-album',
      attributes: attributes,
      children: [for (final path in value.paths) _source(path)],
    );
  }

  static StoryHtmlElement _source(String path, [Map<String, String> attributes = const {}]) {
    return isVideoPath(path)
        ? StoryHtmlElement('video', attributes: {'controls': '', 'src': path, ...attributes})
        : StoryHtmlElement('img', attributes: {'src': path, ...attributes});
  }
}
