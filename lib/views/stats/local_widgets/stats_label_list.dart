part of '../stats_view.dart';

/// Ranked rows for named buckets (tags, people, places, countries). Each row has
/// a faint proportional bar so the relative weight reads at a glance without a
/// chart library. Collapses to the top 5 with an inline "show more" toggle.
class _StatsLabelList extends StatelessWidget {
  const _StatsLabelList({required this.items, required this.icon, this.onTap});

  final List<LabelStatItem> items;
  final IconData icon;

  /// Opens the filtered stories sheet for a row. Pass null for non-tappable sections.
  final void Function(LabelStatItem item)? onTap;

  @override
  Widget build(BuildContext context) {
    final int maxCount = items.isEmpty ? 1 : items.first.count;
    final bool canExpand = items.length > _kStatsTopVisible;

    return SpSingleStateWidget<bool>.listen(
      initialValue: false,
      builder: (context, expanded, notifier) {
        final List<LabelStatItem> visible = expanded || !canExpand ? items : items.take(_kStatsTopVisible).toList();

        return Column(
          children: [
            for (final item in visible)
              _buildRowVisual(
                context,
                icon: icon,
                label: item.label,
                trailing: '${item.count}',
                fraction: maxCount == 0 ? 0.0 : item.count / maxCount,
                onTap: onTap == null ? null : () => onTap!(item),
              ),
            if (canExpand)
              _buildRowVisual(
                context,
                icon: expanded ? SpIcons.expandLess : SpIcons.expandMore,
                label: expanded ? tr('button.show_less') : tr('button.show_more'),
                trailing: '${items.length - _kStatsTopVisible}',
                fraction: 0.0,
                onTap: () => notifier.value = !expanded,
              ),
          ],
        );
      },
    );
  }

  /// Shared row visual: leading icon, label, trailing count, and a faint
  /// proportional bar (drawn only when [fraction] > 0). The expand/collapse
  /// toggle reuses this so it reads as just another row in the list.
  Widget _buildRowVisual(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String trailing,
    required double fraction,
    VoidCallback? onTap,
  }) {
    final ColorScheme colorScheme = ColorScheme.of(context);
    final TextTheme textTheme = TextTheme.of(context);

    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          children: [
            if (fraction > 0)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction.clamp(0.04, 1.0),
                  child: Container(color: colorScheme.readOnly.surface3!),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Row(
                spacing: 8.0,
                children: [
                  Icon(
                    icon,
                    size: 16.0,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                  ),
                  Text(
                    trailing,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return row;
    return SpTapEffect(onTap: onTap, child: row);
  }
}
