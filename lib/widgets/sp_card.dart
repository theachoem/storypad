import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              margin: EdgeInsets.only(right: logoSize + 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextTheme.of(context)
                        .titleMedium
                        ?.copyWith(color: ColorScheme.of(context).secondary, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextTheme.of(context).bodyMedium?.copyWith(color: ColorScheme.of(context).secondary),
                  ),
                  const SizedBox(height: 12.0),
                ],
              ),
            ),
            Positioned(
              top: 16.0,
              right: 16.0,
              child: Icon(
                SpIcons.keyboardRight,
                color: ColorScheme.of(context).secondary,
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpTapEffect(
      effects: const [SpTapEffectType.scaleDown],
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: ColorScheme.of(context).secondaryContainer,
        ),
        child: child,
      ),
    );
  }
}
