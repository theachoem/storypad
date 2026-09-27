import 'package:flutter/material.dart';
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
///
/// Renders a placeholder tile per photo/video (the example has no real assets) with align/size/remove controls.
class MediaEmbed extends StoryEmbed<MediaValue> {
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

  @override
  Widget build(BuildContext context, StoryEmbedContext<MediaValue> embed) => _MediaView(embed: embed);
}

class _MediaView extends StatelessWidget {
  const _MediaView({required this.embed});

  final StoryEmbedContext<MediaValue> embed;

  @override
  Widget build(BuildContext context) {
    final value = embed.value;
    final isMax = value.size == EmbedSize.max;
    return Align(
      alignment: switch (value.alignment) {
        EmbedAlignment.center => Alignment.center,
        EmbedAlignment.right => Alignment.centerRight,
        _ => Alignment.centerLeft,
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMax ? double.infinity : 220),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(spacing: 4, runSpacing: 4, children: [for (final path in value.paths) _Tile(path: path)]),
            if (!embed.readOnly) _buildControls(isMax),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(bool isMax) {
    return Wrap(
      children: [
        for (final (alignment, icon) in const [
          (EmbedAlignment.left, Icons.format_align_left),
          (EmbedAlignment.center, Icons.format_align_center),
          (EmbedAlignment.right, Icons.format_align_right),
        ])
          IconButton(
            tooltip: 'Align ${alignment.name}',
            visualDensity: VisualDensity.compact,
            isSelected: embed.value.alignment == alignment,
            icon: Icon(icon),
            // Tapping the current alignment turns it off, like StoryPad's toolbar.
            onPressed: isMax
                ? null
                : () => embed.update(
                    (current) =>
                        current.copyWith(alignment: current.alignment == alignment ? EmbedAlignment.none : alignment),
                  ),
          ),
        IconButton(
          tooltip: 'Toggle size',
          visualDensity: VisualDensity.compact,
          icon: Icon(isMax ? Icons.zoom_in_map : Icons.zoom_out_map),
          onPressed: () => embed.update(
            (current) => current.copyWith(size: current.size == EmbedSize.max ? EmbedSize.normal : EmbedSize.max),
          ),
        ),
        IconButton(
          tooltip: 'Remove',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.delete_outline),
          onPressed: embed.remove,
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey('media-tile-$path'),
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isVideoPath(path) ? Icons.videocam_outlined : Icons.image_outlined),
          const SizedBox(height: 4),
          Text(
            path.split('/').last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
