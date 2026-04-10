import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_image.dart';

class SpAlbumGrid extends StatelessWidget {
  const SpAlbumGrid({
    super.key,
    required this.paths,
    this.onTap,
  });

  final List<String> paths;

  /// Called when a cell is tapped, with the tapped index into [paths].
  final void Function(int index)? onTap;

  // Tweak album visuals here.
  double get gap => 4;
  double get outerRadius => 8;
  double get innerRadius => 4;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) return const SizedBox.shrink();

    if (paths.length == 1) {
      return AspectRatio(
        aspectRatio: 1,
        child: _buildTile(
          context,
          path: paths[0],
          index: 0,
          edges: const _TileEdges(top: true, right: true, bottom: true, left: true),
        ),
      );
    }

    final display = paths.take(6).toList();
    final extraCount = paths.length - 6;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final cell2Size = (totalWidth - gap) / 2;
        final cell3Size = (totalWidth - gap * 2) / 3;

        if (display.length == 2) {
          return build2Tiles(cell2Size, context, display);
        }

        if (display.length == 3) {
          final leftWidth = (totalWidth - gap) * 2 / 3;
          final rightWidth = (totalWidth - gap) / 3;
          final leftHeight = leftWidth;
          final smallCellHeight = (leftHeight - gap) / 2;

          return build3Tiles(leftHeight, leftWidth, context, display, rightWidth, smallCellHeight);
        }

        if (display.length == 4) {
          return build4Tiles(cell2Size, context, display);
        }

        // 5 images: large left spanning 2 rows, 2×2 grid on the right.
        if (display.length == 5) {
          return build5Tiles(totalWidth, context, display);
        }

        // 6+ images: 2 rows of 3, "+N" overlay on last cell if more than 6.
        return build6Tiles(cell3Size, context, display, extraCount);
      },
    );
  }

  Widget build6Tiles(double cell3Size, BuildContext context, List<String> display, int extraCount) {
    return SizedBox(
      height: cell3Size * 2 + gap,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildTile(
                    context,
                    path: display[0],
                    index: 0,
                    edges: const _TileEdges(top: true, right: false, bottom: false, left: true),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _buildTile(
                    context,
                    path: display[1],
                    index: 1,
                    edges: const _TileEdges(top: true, right: false, bottom: false, left: false),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _buildTile(
                    context,
                    path: display[2],
                    index: 2,
                    edges: const _TileEdges(top: true, right: true, bottom: false, left: false),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: gap),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildTile(
                    context,
                    path: display[3],
                    index: 3,
                    edges: const _TileEdges(top: false, right: false, bottom: true, left: true),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _buildTile(
                    context,
                    path: display[4],
                    index: 4,
                    edges: const _TileEdges(top: false, right: false, bottom: true, left: false),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _buildTile(
                    context,
                    path: display[5],
                    index: 5,
                    edges: const _TileEdges(top: false, right: true, bottom: true, left: false),
                    overlay: extraCount > 0
                        ? ColoredBox(
                            color: Colors.black.withValues(alpha: 0.45),
                            child: Center(
                              child: Text(
                                '+$extraCount',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget build5Tiles(double totalWidth, BuildContext context, List<String> display) {
    final leftWidth = (totalWidth - gap) / 2;
    final rightWidth = (totalWidth - gap) / 2;
    final totalHeight = rightWidth; // make the right 2x2 square cells
    final smallCellHeight = (totalHeight - gap) / 2;

    return SizedBox(
      height: totalHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: leftWidth,
            child: _buildTile(
              context,
              path: display[0],
              index: 0,
              edges: const _TileEdges(top: true, right: false, bottom: true, left: true),
            ),
          ),
          SizedBox(width: gap),
          SizedBox(
            width: rightWidth,
            child: Column(
              children: [
                SizedBox(
                  height: smallCellHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTile(
                          context,
                          path: display[1],
                          index: 1,
                          edges: const _TileEdges(top: true, right: false, bottom: false, left: false),
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        child: _buildTile(
                          context,
                          path: display[2],
                          index: 2,
                          edges: const _TileEdges(top: true, right: true, bottom: false, left: false),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: gap),
                SizedBox(
                  height: smallCellHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTile(
                          context,
                          path: display[3],
                          index: 3,
                          edges: const _TileEdges(top: false, right: false, bottom: true, left: false),
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        child: _buildTile(
                          context,
                          path: display[4],
                          index: 4,
                          edges: const _TileEdges(top: false, right: true, bottom: true, left: false),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget build4Tiles(double cell2Size, BuildContext context, List<String> display) {
    return SizedBox(
      height: cell2Size * 2 + gap,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildTile(
                    context,
                    path: display[0],
                    index: 0,
                    edges: const _TileEdges(top: true, right: false, bottom: false, left: true),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _buildTile(
                    context,
                    path: display[1],
                    index: 1,
                    edges: const _TileEdges(top: true, right: true, bottom: false, left: false),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: gap),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildTile(
                    context,
                    path: display[2],
                    index: 2,
                    edges: const _TileEdges(top: false, right: false, bottom: true, left: true),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _buildTile(
                    context,
                    path: display[3],
                    index: 3,
                    edges: const _TileEdges(top: false, right: true, bottom: true, left: false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget build3Tiles(
    double leftHeight,
    double leftWidth,
    BuildContext context,
    List<String> display,
    double rightWidth,
    double smallCellHeight,
  ) {
    return SizedBox(
      height: leftHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: leftWidth,
            child: _buildTile(
              context,
              path: display[0],
              index: 0,
              edges: const _TileEdges(top: true, right: false, bottom: true, left: true),
            ),
          ),
          SizedBox(width: gap),
          SizedBox(
            width: rightWidth,
            child: Column(
              children: [
                SizedBox(
                  height: smallCellHeight,
                  child: _buildTile(
                    context,
                    path: display[1],
                    index: 1,
                    edges: const _TileEdges(top: true, right: true, bottom: false, left: false),
                  ),
                ),
                SizedBox(height: gap),
                SizedBox(
                  height: smallCellHeight,
                  child: _buildTile(
                    context,
                    path: display[2],
                    index: 2,
                    edges: const _TileEdges(top: false, right: true, bottom: true, left: false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget build2Tiles(double cell2Size, BuildContext context, List<String> display) {
    return SizedBox(
      height: cell2Size,
      child: Row(
        children: [
          Expanded(
            child: _buildTile(
              context,
              path: display[0],
              index: 0,
              edges: const _TileEdges(top: true, right: false, bottom: true, left: true),
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _buildTile(
              context,
              path: display[1],
              index: 1,
              edges: const _TileEdges(top: true, right: true, bottom: true, left: false),
            ),
          ),
        ],
      ),
    );
  }

  BorderRadius _radiusFor(_TileEdges edges) {
    return BorderRadius.only(
      topLeft: Radius.circular(edges.top && edges.left ? outerRadius : innerRadius),
      topRight: Radius.circular(edges.top && edges.right ? outerRadius : innerRadius),
      bottomRight: Radius.circular(edges.bottom && edges.right ? outerRadius : innerRadius),
      bottomLeft: Radius.circular(edges.bottom && edges.left ? outerRadius : innerRadius),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String path,
    required int index,
    required _TileEdges edges,
    Widget? overlay,
  }) {
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(index) : null,
      child: Material(
        clipBehavior: .hardEdge,
        shape: RoundedRectangleBorder(
          borderRadius: _radiusFor(edges),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SpImage(
              link: path,
              width: double.infinity,
              height: double.infinity,
            ),
            ?overlay,
          ],
        ),
      ),
    );
  }
}

class _TileEdges {
  const _TileEdges({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  final bool top;
  final bool right;
  final bool bottom;
  final bool left;
}
