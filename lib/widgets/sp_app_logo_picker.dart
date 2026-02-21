import 'package:flutter/material.dart';
import 'package:storypad/core/types/app_logo.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpAppLogoPicker extends StatelessWidget {
  const SpAppLogoPicker({
    super.key,
    required this.onLogoSelected,
    required this.selectedAppLogo,
  });

  final void Function(AppLogo) onLogoSelected;
  final AppLogo selectedAppLogo;

  @override
  Widget build(BuildContext context) {
    // Make sure male logo is always first to avoid in appropriate display.
    final logos = {AppLogo.storypad_2_0, ...AppLogo.values};

    return SizedBox(
      height: 72,
      child: CarouselView(
        scrollDirection: Axis.horizontal,
        itemExtent: 72,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        onTap: (value) {
          onLogoSelected.call(logos.elementAt(value));
        },
        children: logos.map((logo) {
          return Stack(
            children: [
              logo.asset.image(
                width: 72,
                height: 72,
                fit: .cover,
              ),
              if (selectedAppLogo == logo)
                Positioned(
                  bottom: 4.0,
                  right: 4.0,
                  child: SpFadeIn.fromBottom(
                    child: const Icon(SpIcons.checkCircle, color: Colors.black),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
