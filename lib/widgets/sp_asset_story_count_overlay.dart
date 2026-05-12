import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpAssetStoryCountOverlay extends StatelessWidget {
  const SpAssetStoryCountOverlay({
    super.key,
    required this.storyCount,
    this.showArchiveIconWhenZero = false,
    this.left = 8.0,
    this.right = 8.0,
    this.bottom = 4.0,
  });

  final int storyCount;
  final bool showArchiveIconWhenZero;
  final double left;
  final double right;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: .0),
                Colors.black.withValues(alpha: .6),
                Colors.black.withValues(alpha: .9),
              ],
            ),
          ),
          alignment: Alignment.bottomLeft,
          padding: EdgeInsets.only(left: left, right: right, bottom: bottom),
          child: Text.rich(
            TextSpan(
              style: const TextStyle(color: Colors.white, fontSize: 11),
              children: [
                TextSpan(text: plural('plural.story', storyCount)),
                if (showArchiveIconWhenZero && storyCount == 0) ...[
                  const TextSpan(text: ' '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      SpIcons.archive,
                      size: 12.0,
                      color: ColorScheme.of(context).error,
                    ),
                  ),
                ],
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
