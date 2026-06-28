part of '../stats_view.dart';

/// One compact summary chip in the overview grid: an icon over a bold value and
/// a muted label.
///
/// ```
/// ┌──────────────┐
/// │ 📖           │  icon
/// │ 128          │  value
/// │ Entries      │  label
/// └──────────────┘
/// ```
class _StatsMetricChip extends StatelessWidget {
  const _StatsMetricChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.of(context);
    final TextTheme textTheme = TextTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.readOnly.surface3,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 8.0,
        children: [
          Icon(icon, size: 16.0, color: colorScheme.primary),
          Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: .ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: .ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
