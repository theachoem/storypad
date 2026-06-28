part of '../stats_view.dart';

/// Top emoji tags (feelings / activities) as a grid of emoji cells, each with a
/// small count badge. Ordered most-used first by the service. The grid expands
/// to the full available width: the column count is derived from a target cell
/// size, then each cell is widened to evenly fill the row.
class _StatsEmojiGrid extends StatelessWidget {
  const _StatsEmojiGrid({required this.items, required this.onTap});

  static const double _spacing = 8.0;
  static const double _targetCellWidth = 52.0;

  final List<EmojiStatItem> items;

  /// Opens the filtered stories sheet for the tapped emoji's tag.
  final void Function(int tagId) onTap;

  @override
  Widget build(BuildContext context) {
    final bool canExpand = items.length > _kStatsTopVisible;

    return SpSingleStateWidget<bool>.listen(
      initialValue: false,
      builder: (context, expanded, notifier) {
        final List<EmojiStatItem> visible = expanded || !canExpand ? items : items.take(_kStatsTopVisible).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final int crossAxisCount = ((constraints.maxWidth + _spacing) / (_targetCellWidth + _spacing))
                .floor()
                .clamp(1, 99);
            final double cellWidth = (constraints.maxWidth - _spacing * (crossAxisCount - 1)) / crossAxisCount;

            return Wrap(
              spacing: _spacing,
              runSpacing: _spacing,
              children: [
                for (final item in visible)
                  SizedBox(
                    width: cellWidth,
                    height: cellWidth,
                    child: _buildCell(context, item),
                  ),
                if (canExpand)
                  SizedBox(
                    width: cellWidth,
                    height: cellWidth,
                    child: _buildExpandCell(
                      context,
                      expanded: expanded,
                      onTap: () => notifier.value = !expanded,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Trailing cell that toggles between the collapsed top-5 view and the full set,
  /// styled to sit flush with the emoji cells in the grid.
  Widget _buildExpandCell(
    BuildContext context, {
    required bool expanded,
    required VoidCallback onTap,
  }) {
    final ColorScheme colorScheme = ColorScheme.of(context);

    return SpTapEffect(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.readOnly.surface3,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: expanded
            ? Icon(
                SpIcons.expandLess,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              )
            : Text(
                '+${items.length - _kStatsTopVisible}',
                style: TextTheme.of(context).bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, EmojiStatItem item) {
    final ColorScheme colorScheme = ColorScheme.of(context);

    return SpTapEffect(
      onTap: () => onTap(item.tagId),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.readOnly.surface3,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                item.emoji,
                style: TextTheme.of(context).headlineSmall,
              ),
            ),
            Positioned(
              right: 0.0,
              bottom: 0.0,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20.0),
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(12.0),
                  ),
                ),
                child: Text(
                  '${item.count}',
                  textAlign: .center,
                  style: TextTheme.of(context).bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
