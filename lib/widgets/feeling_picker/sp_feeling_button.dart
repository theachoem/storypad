import 'package:animated_clipper/animated_clipper.dart' show PathBuilders;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/objects/feeling_object.dart' show FeelingObject;
import 'package:storypad/widgets/feeling_picker/sp_feeling_picker.dart';
import 'package:storypad/widgets/sp_floating_pop_up_button.dart' show SpFloatingPopUpButton;
import 'package:storypad/widgets/sp_icons.dart';

class SpFeelingButton extends StatelessWidget {
  const SpFeelingButton({
    super.key,
    this.feeling,
    required this.onPicked,
  });

  final String? feeling;
  final Future<void> Function(String? feeling) onPicked;

  static Color backgroundColor(BuildContext context) =>
      (AppTheme.isDarkMode(context) ? Colors.white : Colors.black).withValues(alpha: 0.05);

  @override
  Widget build(BuildContext context) {
    return SpFloatingPopUpButton(
      estimatedFloatingWidth: 300,
      bottomToTop: false,
      margin: 12.0,
      dyGetter: (dy) => dy + 48 + 8,
      pathBuilder: PathBuilders.slideDown,
      floatingBuilder: (void Function() callback) {
        return SpFeelingPicker(
          feeling: feeling,
          onPicked: (feeling) async {
            await onPicked(feeling);
            callback();
          },
        );
      },
      builder: (callback) {
        return Container(
          margin: const EdgeInsets.all(4.0),
          child: Material(
            type: MaterialType.circle,
            color: backgroundColor(context),
            child: Tooltip(
              message: FeelingObject.feelingsByKey[feeling]?.translation(context) ?? tr("button.set_feeling"),
              child: InkWell(
                borderRadius: BorderRadius.circular(48.0),
                onTap: callback,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: AnimatedSwitcher(
                    switchInCurve: Curves.ease,
                    switchOutCurve: Curves.ease,
                    duration: Durations.medium3,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      );
                    },
                    child: FeelingObject.feelingsByKey[feeling]?.image64
                            .image(width: 24, key: ValueKey('feeling-$feeling')) ??
                        const Icon(SpIcons.addFeeling, key: ValueKey('feeling-none')),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
