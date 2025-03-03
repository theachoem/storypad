part of 'story_tile_list_item.dart';

class _StoryMonthHeader extends StatelessWidget {
  const _StoryMonthHeader({
    required this.index,
    required this.context,
    required this.story,
    required this.showYear,
  });

  final int index;
  final BuildContext context;
  final StoryDbModel story;
  final bool showYear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 4.0, top: index == 0 ? 8.0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(width: 16.0),
          _MonthChip(story: story),
          if (showYear) ...[
            const SizedBox(width: 4.0),
            Container(
              width: 2,
              height: 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorScheme.of(context).onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 4.0),
            Text(
              story.year.toString(),
              style: TextTheme.of(context)
                  .labelSmall
                  ?.copyWith(color: ColorScheme.of(context).onSurface.withValues(alpha: 0.5)),
            ),
          ]
        ],
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.story,
  });

  final StoryDbModel story;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: StoryTile.monogramSize,
      alignment: Alignment.center,
      child: CustomPaint(
        painter: _MonthChipBoxPainter(
          fillColor: Theme.of(context).colorScheme.surface,
          borderRadius: 8.0,
          borderWidth: 1,
          borderColor: Theme.of(context).dividerColor,
        ),
        child: Text(
          DateFormatHelper.MMM(DateTime(2000, story.month), context.locale),
          style: TextTheme.of(context).labelSmall,
        ),
      ),
    );
  }
}

class _MonthChipBoxPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  _MonthChipBoxPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    double extraPadding = 4;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        -extraPadding,
        0,
        size.width + extraPadding * 2,
        size.height,
      ),
      Radius.circular(borderRadius),
    );

    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
