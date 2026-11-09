import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/services/tag_color_service.dart';

/// A tag's title, followed by a dot of its color when it has one ([TagColors.swatch], as on the edit
/// tag page). The dot is the font size, inside the line height, so a list tile keeps the same height
/// with or without it.
class SpTagTitle extends StatelessWidget {
  const SpTagTitle(this.tag, {super.key});

  final TagDbModel tag;

  @override
  Widget build(BuildContext context) {
    final seed = tag.colorSeed;
    if (seed == null) return Text(tag.title);

    final fontSize = DefaultTextStyle.of(context).style.fontSize ?? 16.0;
    final dotSize = MediaQuery.textScalerOf(context).scale(fontSize);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: tag.title),
          const WidgetSpan(child: SizedBox(width: 8.0)),
          WidgetSpan(
            alignment: .middle,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: .circle,
                color: TagColorService.resolve(seed, Theme.of(context).brightness).swatch,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
