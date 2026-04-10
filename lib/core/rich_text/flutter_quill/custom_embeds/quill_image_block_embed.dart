part of '../quill_adapter.dart';

class _QuillImageBlockEmbed extends quill.EmbedBuilder {
  final List<String> Function() fetchAllImages;
  final PageLayoutType? layoutType;

  _QuillImageBlockEmbed({
    required this.fetchAllImages,
    required this.layoutType,
  });

  @override
  String get key => quill.BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    return _QuillImageRenderer(
      controller: embedContext.controller,
      readOnly: embedContext.readOnly,
      node: embedContext.node,
      fetchAllImages: fetchAllImages,
      layoutType: layoutType,
    );
  }
}

class _QuillImageRenderer extends StatelessWidget {
  const _QuillImageRenderer({
    required this.node,
    required this.controller,
    required this.readOnly,
    required this.fetchAllImages,
    required this.layoutType,
  });

  final quill.Embed node;
  final quill.QuillController controller;
  final PageLayoutType? layoutType;
  final bool readOnly;
  final List<String> Function() fetchAllImages;

  static List<String> _parsePaths(String value) => value.split('|').where((s) => s.isNotEmpty).toList();

  void remove() {
    if (readOnly) return;
    controller.replaceText(node.documentOffset, node.length, '', controller.selection);
  }

  void _updatePaths(List<String> newPaths) {
    if (readOnly) return;
    if (newPaths.isEmpty) {
      remove();
      return;
    }

    final op = node.toDelta().operations.first;
    final attributes = op.attributes == null ? null : Map<String, dynamic>.from(op.attributes!);
    final delta = QuillRichTextController._buildEmbedDelta(
      embedType: quill.BlockEmbed.imageType,
      value: newPaths.join('|'),
      attributes: attributes,
    );
    controller.replaceText(node.documentOffset, node.length, delta, controller.selection);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> paths = _parsePaths(node.value.data);
    if (paths.length > 1) return _buildAlbum(context, paths);
    final String link = paths.isNotEmpty ? paths.first : node.value.data;
    return _buildSingle(context, link);
  }

  Widget _buildSingle(BuildContext context, String link) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double? width;
        double? height;

        if (_EmbedSizeAttribute.maxSize.hasApplied(node)) {
          width = double.infinity;
          height = null;
        } else {
          if (layoutType == PageLayoutType.grid) {
            width = min(constraints.maxWidth, MediaQuery.textScalerOf(context).scale(88));
            height = min(constraints.maxWidth, MediaQuery.textScalerOf(context).scale(88));
          } else {
            width = min(constraints.maxWidth, MediaQuery.textScalerOf(context).scale(150));
            height = min(constraints.maxWidth, MediaQuery.textScalerOf(context).scale(150));
          }
        }

        return Container(
          width: double.infinity,
          alignment:
              _EmbedAlignmentAttribute.toAlignment(node) ??
              AppTheme.getDirectionValue(context, Alignment.centerRight, Alignment.centerLeft),
          child: Stack(
            children: [
              GestureDetector(
                onTap: readOnly ? () => viewImage(context, link) : null,
                onLongPress: () async {
                  Feedback.forLongPress(context);
                  final relativePath = node.value.data;
                  final asset = await AssetDbModel.findBy(relativePath: relativePath);
                  if (!context.mounted || asset == null) return;
                  SpAssetInfoSheet(
                    asset: asset,
                    onRemoveAssetEmbed: readOnly ? null : () => remove(),
                  ).show(context: context);
                },
                child: Material(
                  clipBehavior: Clip.hardEdge,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: SpImage(
                    link: link,
                    width: width,
                    height: height,
                  ),
                ),
              ),
              if (!readOnly)
                Positioned(
                  top: 0,
                  right: 0,
                  child: buildMoreVertButton(context),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlbum(BuildContext context, List<String> paths) {
    final isMaxSize = _EmbedSizeAttribute.maxSize.hasApplied(node);
    return LayoutBuilder(
      builder: (context, constraints) {
        double? maxWidth;
        if (!isMaxSize) {
          if (layoutType == PageLayoutType.grid) {
            maxWidth = MediaQuery.textScalerOf(context).scale(180);
          } else {
            maxWidth = MediaQuery.textScalerOf(context).scale(300);
          }
        }

        return Container(
          width: double.infinity,
          alignment:
              _EmbedAlignmentAttribute.toAlignment(node) ??
              AppTheme.getDirectionValue(context, Alignment.centerRight, Alignment.centerLeft),
          child: Stack(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
                child: SpAlbumGrid(
                  paths: paths,
                  onTap: readOnly ? (index) => _viewImageAt(context, paths, index) : null,
                ),
              ),
              if (!readOnly)
                Positioned(
                  top: 0,
                  right: 0,
                  child: buildMoreVertButton(context),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget buildMoreVertButton(BuildContext context) {
    final paths = _parsePaths(node.value.data);
    final isAlbum = paths.length > 1;

    final List<IconButton> buttons = [
      IconButton(
        isSelected: _EmbedAlignmentAttribute.left.hasApplied(node),
        icon: const Icon(Icons.format_align_left),
        onPressed: _EmbedSizeAttribute.maxSize.hasApplied(node)
            ? null
            : () => _EmbedAlignmentAttribute.left.toggle(controller, node),
      ),
      IconButton(
        isSelected: _EmbedAlignmentAttribute.center.hasApplied(node),
        icon: const Icon(Icons.format_align_center),
        onPressed: _EmbedSizeAttribute.maxSize.hasApplied(node)
            ? null
            : () => _EmbedAlignmentAttribute.center.toggle(controller, node),
      ),
      IconButton(
        isSelected: _EmbedAlignmentAttribute.right.hasApplied(node),
        icon: const Icon(Icons.format_align_right),
        onPressed: _EmbedSizeAttribute.maxSize.hasApplied(node)
            ? null
            : () => _EmbedAlignmentAttribute.right.toggle(controller, node),
      ),
      IconButton(
        icon: Icon(_EmbedSizeAttribute.maxSize.hasApplied(node) ? SpIcons.zoomOut : SpIcons.zoomIn),
        onPressed: () => _EmbedSizeAttribute.toggle(controller, node),
      ),

      IconButton(
        icon: isAlbum ? const Icon(SpIcons.edit) : const Icon(SpIcons.addPhoto),
        onPressed: () async {
          final result = await SpAlbumManagementSheet(paths: paths).show<List<String>?>(context: context);
          if (!context.mounted) return;
          if (result is List<String>) _updatePaths(result);
        },
      ),
      IconButton(
        color: ColorScheme.of(context).error,
        icon: const Icon(SpIcons.delete),
        onPressed: () => remove(),
      ),
    ];

    int rowCount = (buttons.length / 3).ceilToDouble().toInt();

    double itemSize = 48;
    double padding = 4.0;

    double contentsWidth = itemSize * min(3, buttons.length);
    double width = contentsWidth + padding * 2 + 2;
    double height = itemSize * rowCount + padding * 2 + 2;

    return SpFloatingPopUpButton(
      estimatedFloatingWidth: width,
      bottomToTop: false,
      dyGetter: (dy) => dy + 48,
      pathBuilder: PathBuilders.slideDown,
      floatingBuilder: (FutureOr<void> Function() close) {
        return Container(
          width: width,
          height: height,
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: ColorScheme.of(context).surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          ),
          child: Wrap(
            spacing: 0.0,
            runSpacing: 0.0,
            children: buttons.map((button) {
              bool selected = button.onPressed != null && button.isSelected == true;

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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
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
      builder: (callback) {
        return IconButton.filledTonal(
          icon: const Icon(SpIcons.moreVert),
          onPressed: callback,
        );
      },
    );
  }

  Future<void> viewImage(BuildContext context, String link) async {
    Feedback.forTap(context);
    List<String> images = fetchAllImages();

    if (images.contains(link)) {
      SpImagesViewer.fromString(
        images: images,
        initialIndex: images.indexOf(link),
        context: context,
      ).show(context);
    } else {
      SpImagesViewer.fromString(
        images: [link],
        initialIndex: 0,
        context: context,
      ).show(context);
    }
  }

  Future<void> _viewImageAt(BuildContext context, List<String> paths, int index) async {
    Feedback.forTap(context);
    SpImagesViewer.fromString(
      images: paths,
      initialIndex: index,
      context: context,
    ).show(context);
  }
}
