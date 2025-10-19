import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/services/remote_config/remote_config_service.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_markdown_body.dart';
import 'package:storypad/widgets/sp_wave_animation.dart';

class SpUnlockRelaxSoundsSheet extends BaseBottomSheet {
  const SpUnlockRelaxSoundsSheet({
    required this.onUnlock,
    required this.displayPrice,
  });

  final void Function(BuildContext context) onUnlock;
  final String displayPrice;

  @override
  bool get fullScreen => false;

  (String, String) getContent() {
    final variant = RemoteConfigService.relaxSoundUnlockSheetVariant.get();

    switch (variant) {
      case 'variant_5':
        return (
          'Your calm, upgraded',
          'Enjoy all relaxing sounds for just **$displayPrice**. Lifetime access, no subscription, unlock your ultimate peace.',
        );
      case 'variant_4':
        return (
          'Lifetime calm access',
          'Get the full collection of premium relaxing sounds for **$displayPrice**. No subscription, enjoy lifetime access to your calm space.',
        );
      case 'variant_3':
        return (
          'Join hundreds of relaxed users',
          'Unlock the full relaxing sounds library for **$displayPrice**. Lifetime access, no subscription - see why so many users love it.',
        );
      case 'variant_2':
        return (
          'Unlock the ultimate StoryPad experience',
          'Get all relaxing sounds and premium features for **$displayPrice**. Lifetime access, no subscription, make your journaling experience complete.',
        );
      case 'variant_1':
      default:
        return (
          'Unlock full relaxation',
          'Get relaxing sounds for just **$displayPrice**. Lifetime access, no subscription.',
        );
    }
  }

  @override
  Widget build(BuildContext context, double bottomPadding) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final (title, body) = getContent();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 16.0),
            child: const SpWaveAnimation(),
          ),
          const SizedBox(height: 24.0),
          Text.rich(
            TextSpan(
              text: title,
              style: textTheme.headlineSmall,
              children: [
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    SpIcons.musicNote,
                    size: 20.0,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          SpMarkdownBody(
            body: body,
            align: WrapAlignment.center,
          ),
          const SizedBox(height: 24.0),
          FilledButton.icon(
            onPressed: () => onUnlock(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(SpIcons.lock),
            label: Text(tr('button.unlock')),
          ),
          const SizedBox(height: 8.0),
          TextButton(
            onPressed: () => Navigator.maybePop(context),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: const StadiumBorder(),
            ),
            child: Text(tr('button.maybe_later')),
          ),
          buildBottomPadding(bottomPadding),
        ],
      ),
    );
  }
}
