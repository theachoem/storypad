import 'dart:async';
import 'dart:math';

import 'package:animated_clipper/animated_clipper.dart';
import 'package:flutter/material.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/rich_editor/sp_editor_scope.dart';
import 'package:storypad/core/types/page_layout_type.dart';
import 'package:storypad/widgets/bottom_sheets/sp_album_management_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_asset_info_sheet.dart';
import 'package:storypad/widgets/media_viewer/sp_media_viewer.dart';
import 'package:storypad/widgets/sp_album_grid.dart';
import 'package:storypad/widgets/sp_floating_pop_up_button.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_media_tile.dart';
import 'package:storypad_editor/storypad_editor.dart';

enum SpEmbedAlignment { none, left, center, right }

enum SpEmbedSize { normal, max }

/// One or more photos/videos (an album when there's more than one), with size and alignment.
@immutable
class SpMediaValue {
  const SpMediaValue(this.paths, {this.size = .normal, this.alignment = .none});

  /// Relative asset paths (`images/<id>.jpg`, `videos/<id>.mp4`) or URLs. Never empty.
  final List<String> paths;
  final SpEmbedSize size;
  final SpEmbedAlignment alignment;

  bool get isAlbum => paths.length > 1;

  SpMediaValue copyWith({List<String>? paths, SpEmbedSize? size, SpEmbedAlignment? alignment}) {
    return SpMediaValue(paths ?? this.paths, size: size ?? this.size, alignment: alignment ?? this.alignment);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SpMediaValue || size != other.size || alignment != other.alignment) return false;
    if (paths.length != other.paths.length) return false;
    for (int i = 0; i < paths.length; i++) {
      if (paths[i] != other.paths[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(paths), size, alignment);

  @override
  String toString() => 'SpMediaValue($paths, $size, $alignment)';
}

/// Photos and videos share one embed, so an album can mix both (see docs/app/features/media.md).
///
/// - Quill: `{"media": "images/a.jpg|videos/b.mp4"}` (or the legacy `image` key, read identically), with
///   `custom-embed-size`/`custom-embed-alignment`. Always written back as `media`.
/// - Markdown: a single photo `<img src>` (a bare `![](images/a.jpg)` without attributes), a single video
///   `<video controls src>`, an album `<sp-album>` wrapping `<img>`/`<video>` children.
class SpMediaEmbed extends StoryEmbed<SpMediaValue> {
  const SpMediaEmbed();

  // Each layout attribute is defined once for both formats: the Quill op attribute and the HTML attribute in Markdown.
  static const _alignment = StoryEmbedAttribute<SpEmbedAlignment>.enumeration(
    quillKey: 'custom-embed-alignment',
    htmlName: 'data-align',
    values: {SpEmbedAlignment.left: 'left', SpEmbedAlignment.center: 'center', SpEmbedAlignment.right: 'right'},
    fallback: SpEmbedAlignment.none,
  );

  static const _size = StoryEmbedAttribute<SpEmbedSize>.enumeration(
    quillKey: 'custom-embed-size',
    htmlName: 'data-size',
    values: {SpEmbedSize.normal: 'default', SpEmbedSize.max: 'max'},
    fallback: SpEmbedSize.normal,
  );

  @override
  String get type => 'media';

  @override
  Set<String> get quillKeys => const {'media', 'image'};

  @override
  Set<String> get htmlTags => const {'img', 'video', 'sp-album'};

  @override
  SpMediaValue? fromQuill(QuillEmbedOp op) {
    final value = op.value;
    if (value is! String) return null;

    final paths = value.split('|').where((path) => path.isNotEmpty).toList();
    if (paths.isEmpty) return null;
    return SpMediaValue(paths, size: op.attribute(_size), alignment: op.attribute(_alignment));
  }

  @override
  QuillEmbedOp toQuill(SpMediaValue value) => QuillEmbedOp.of(
    'media',
    value.paths.join('|'),
    attributes: {..._size.toQuill(value.size), ..._alignment.toQuill(value.alignment)},
  );

  @override
  SpMediaValue? fromHtml(StoryHtmlElement element) {
    final sources = element.tag == 'sp-album' ? element.children : [element];
    final paths = [
      for (final source in sources)
        if (source['src'] case final src? when src.isNotEmpty) src,
    ];
    if (paths.isEmpty) return null;
    return SpMediaValue(paths, size: element.attribute(_size), alignment: element.attribute(_alignment));
  }

  @override
  StoryHtmlElement toHtml(SpMediaValue value) {
    final attributes = {..._size.toHtml(value.size), ..._alignment.toHtml(value.alignment)};
    if (!value.isAlbum) return _source(value.paths.single, attributes);
    return StoryHtmlElement(
      'sp-album',
      attributes: attributes,
      children: [for (final path in value.paths) _source(path)],
    );
  }

  static StoryHtmlElement _source(String path, [Map<String, String> attributes = const {}]) {
    return path.startsWith('videos/')
        ? StoryHtmlElement('video', attributes: {'controls': '', 'src': path, ...attributes})
        : StoryHtmlElement('img', attributes: {'src': path, ...attributes});
  }

  @override
  Widget build(BuildContext context, StoryEmbedContext<SpMediaValue> embed) => _MediaEmbedView(embed: embed);
}

class _MediaEmbedView extends StatelessWidget {
  const _MediaEmbedView({required this.embed});

  final StoryEmbedContext<SpMediaValue> embed;

  SpMediaValue get value => embed.value;
  bool get readOnly => embed.readOnly;
  bool get isMaxSize => value.size == .max;

  void _remove() {
    if (!readOnly) embed.remove();
  }

  void _updatePaths(List<String> paths) {
    if (readOnly) return;
    if (paths.isEmpty) {
      embed.remove();
    } else {
      embed.update((current) => current.copyWith(paths: paths));
    }
  }

  void _toggleAlignment(SpEmbedAlignment alignment) {
    embed.update((current) => current.copyWith(alignment: current.alignment == alignment ? .none : alignment));
  }

  void _toggleSize() {
    embed.update((current) => current.copyWith(size: current.size == .max ? .normal : .max));
  }

  Alignment? _alignment(BuildContext context) {
    return switch (value.alignment) {
      .left => Alignment.centerLeft,
      .center => Alignment.center,
      .right => Alignment.centerRight,
      .none => AppTheme.getDirectionValue(context, Alignment.centerRight, Alignment.centerLeft),
    };
  }

  @override
  Widget build(BuildContext context) {
    final layoutType = SpEditorScope.maybeOf(context)?.layoutType;
    if (value.isAlbum) return _buildAlbum(context, layoutType);
    return _buildSingle(context, value.paths.single, layoutType);
  }

  Widget _buildSingle(BuildContext context, String link, PageLayoutType? layoutType) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double? width;
        double? height;

        if (isMaxSize) {
          width = double.infinity;
        } else {
          final side = MediaQuery.textScalerOf(context).scale(layoutType == .grid ? 88 : 150);
          width = min(constraints.maxWidth, side);
          height = min(constraints.maxWidth, side);
        }

        return Container(
          width: double.infinity,
          alignment: _alignment(context),
          child: Stack(
            children: [
              GestureDetector(
                onTap: readOnly ? () => _viewMedia(context, link) : null,
                onLongPress: () async {
                  Feedback.forLongPress(context);
                  final asset = await AssetDbModel.findBy(relativePath: link);
                  if (!context.mounted || asset == null) return;
                  SpAssetInfoSheet(asset: asset, onRemoveAssetEmbed: readOnly ? null : _remove).show(context: context);
                },
                child: Material(
                  clipBehavior: .hardEdge,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: SpMediaTile(link: link, width: width, height: height),
                ),
              ),
              if (!readOnly) Positioned(top: 0, right: 0, child: _buildMoreVertButton(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlbum(BuildContext context, PageLayoutType? layoutType) {
    final paths = value.paths;
    final maxWidth = isMaxSize
        ? double.infinity
        : MediaQuery.textScalerOf(context).scale(layoutType == .grid ? 180 : 300);

    return Container(
      width: double.infinity,
      alignment: _alignment(context),
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SpAlbumGrid(paths: paths, onTap: readOnly ? (index) => _viewMediaAt(context, paths, index) : null),
          ),
          if (!readOnly) Positioned(top: 0, right: 0, child: _buildMoreVertButton(context)),
        ],
      ),
    );
  }

  Widget _buildMoreVertButton(BuildContext context) {
    final buttons = <IconButton>[
      for (final (alignment, icon) in const [
        (SpEmbedAlignment.left, SpIcons.alignLeft),
        (SpEmbedAlignment.center, SpIcons.alignCenter),
        (SpEmbedAlignment.right, SpIcons.alignRight),
      ])
        IconButton(
          isSelected: value.alignment == alignment,
          icon: Icon(icon),
          onPressed: isMaxSize ? null : () => _toggleAlignment(alignment),
        ),
      IconButton(icon: Icon(isMaxSize ? SpIcons.zoomOut : SpIcons.zoomIn), onPressed: _toggleSize),
      IconButton(
        icon: Icon(value.isAlbum ? SpIcons.edit : SpIcons.addPhoto),
        onPressed: () async {
          final result = await SpAlbumManagementSheet(paths: value.paths).show<List<String>?>(context: context);
          if (!context.mounted) return;
          if (result is List<String>) _updatePaths(result);
        },
      ),
      IconButton(color: ColorScheme.of(context).error, icon: const Icon(SpIcons.delete), onPressed: _remove),
    ];

    final rowCount = (buttons.length / 3).ceil();
    const itemSize = 48.0;
    const padding = 4.0;
    final width = itemSize * min(3, buttons.length) + padding * 2 + 2;
    final height = itemSize * rowCount + padding * 2 + 2;

    return SpFloatingPopUpButton(
      estimatedFloatingWidth: width,
      bottomToTop: false,
      dyGetter: (dy) => dy + 48,
      pathBuilder: PathBuilders.slideDown,
      floatingBuilder: (FutureOr<void> Function() close) {
        return Container(
          width: width,
          height: height,
          clipBehavior: .hardEdge,
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: ColorScheme.of(context).surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          ),
          child: Wrap(
            children: buttons.map((button) {
              final selected = button.onPressed != null && button.isSelected == true;
              return SizedBox(
                width: itemSize,
                height: itemSize,
                child: Center(
                  child: IconButton(
                    isSelected: selected,
                    icon: button.icon,
                    color: button.color,
                    style: IconButton.styleFrom(
                      side: selected ? BorderSide(color: Theme.of(context).dividerColor) : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    onPressed: button.onPressed == null
                        ? null
                        : () async {
                            await close();
                            button.onPressed!();
                          },
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      builder: (callback) => IconButton.filledTonal(icon: const Icon(SpIcons.moreVert), onPressed: callback),
    );
  }

  void _viewMedia(BuildContext context, String link) {
    Feedback.forTap(context);
    final media = SpEditorScope.maybeOf(context)?.fetchAllMedia() ?? const <String>[];
    final images = media.contains(link) ? media : [link];
    SpMediaViewer.fromString(images: images, initialIndex: images.indexOf(link), context: context).show(context);
  }

  void _viewMediaAt(BuildContext context, List<String> paths, int index) {
    Feedback.forTap(context);
    SpMediaViewer.fromString(images: paths, initialIndex: index, context: context).show(context);
  }
}
