import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

class SpCard extends StatelessWidget {
  const SpCard({
    super.key,
    this.onTap,
    required this.child,
  });

  final void Function()? onTap;
  final Widget child;

  factory SpCard.withLogo({
    required String title,
    required String subtitle,
    required ImageProvider logo,
    double logoSize = 48,
    required void Function()? onTap,
  }) {
    return SpCard(
      onTap: onTap,
      child: Builder(builder: (context) {
        return Stack(
          children: [
            Positioned(
              right: 16,
              bottom: 16,
              child: SpFadeIn.bound(
                delay: Durations.medium1,
                child: Image(
                  image: logo,
                  height: logoSize,
                  width: logoSize,
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              margin: EdgeInsets.only(right: logoSize + 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextTheme.of(context)
                        .titleMedium
                        ?.copyWith(color: ColorScheme.of(context).bootstrap.warning.color, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextTheme.of(context)
                        .bodyMedium
                        ?.copyWith(color: ColorScheme.of(context).bootstrap.warning.color),
                  ),
                  SizedBox(height: 12.0),
                ],
              ),
            ),
            Positioned(
              top: 16.0,
              right: 16.0,
              child: Icon(Icons.keyboard_arrow_right, color: ColorScheme.of(context).bootstrap.warning.color),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpTapEffect(
      effects: [SpTapEffectType.scaleDown],
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 16.0),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: ColorScheme.of(context).bootstrap.warning.container,
        ),
        child: child,
      ),
    );
  }
}
