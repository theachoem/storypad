import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/types/app_logo.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/paywall/paywall_view.dart';
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
    final iapProvider = Provider.of<InAppPurchaseProvider>(context);

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
        onTap: (index) {
          final logo = logos.elementAt(index);
          if (!logo.free && !iapProvider.isProUser) {
            const PaywallRoute(initialFocus: .customizations).push(context);
          } else {
            onLogoSelected.call(logo);
          }
        },
        children: logos.map((logo) {
          return Stack(
            children: [
              logo.asset.image(
                width: 72,
                height: 72,
                fit: .cover,
              ),
              if (!logo.free && !iapProvider.isProUser)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(SpIcons.lock, size: 16.0, color: Colors.black),
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
