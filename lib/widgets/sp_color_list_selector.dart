// TODO: fix color.value deprecation
// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

class SpColorListSelector extends StatelessWidget {
  const SpColorListSelector({
    super.key,
    required this.selectedColor,
    required this.colorTone,
    required this.onChanged,
    this.padding = const EdgeInsets.all(16.0),
  });

  final void Function(Color? color, int? colorTone) onChanged;
  final Color? selectedColor;
  final EdgeInsets padding;

  /// colorTone can be from 0 to 99.
  /// Because we has only 4 level. 0, 33, 66, 99.
  /// SpStoryPreferenceTheme will use it for change page background tones.
  final int colorTone;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(spacing: 4.0, children: [
        buildButton(
          tooltip: tr("button.reset"),
          context: context,
          backgroundColor: null,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          onTap: (int colorTone) {
            HapticFeedback.selectionClick();
            onChanged(null, colorTone);
          },
          selected: selectedColor == null,
          child: const Icon(SpIcons.hideSource),
        ),
        buildButton(
          context: context,
          child: null,
          foregroundColor: Theme.brightnessOf(context) == Brightness.dark ? Colors.white : Colors.black,
          backgroundColor: Theme.brightnessOf(context) == Brightness.dark ? Colors.black : Colors.white,
          selected: Colors.black.value == selectedColor?.value,
          onTap: (colorTone) => onChanged(Colors.black, colorTone),
        ),
        ...kMaterialColors.map<Widget>(
          (color) {
            return buildButton(
              context: context,
              child: null,
              backgroundColor: color,
              foregroundColor: Colors.black,
              selected: color.value == selectedColor?.value,
              onTap: (colorTone) => onChanged(color, colorTone),
            );
          },
        )
      ]),
    );
  }

  Widget buildButton({
    required void Function(int colorTone) onTap,
    required BuildContext context,
    required Widget? child,
    required Color? backgroundColor,
    required Color? foregroundColor,
    bool selected = false,
    String? tooltip,
  }) {
    int nextColorTone;

    if (selected) {
      nextColorTone = colorTone + 33 > 99 ? 0 : colorTone + 33;
    } else {
      nextColorTone = 0;
    }

    Widget button = SpTapEffect(
      effects: [
        SpTapEffectType.border,
        SpTapEffectType.scaleDown,
      ],
      onTap: () => onTap(nextColorTone),
      child: Stack(
        children: [
          Visibility(
            visible: selected,
            child: Positioned.fill(
              child: CircularProgressIndicator(
                color: ColorScheme.of(context).readOnly.surface5,
                value: 1,
                strokeCap: StrokeCap.round,
                strokeWidth: 3,
              ),
            ),
          ),
          Visibility(
            visible: selected,
            child: Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: colorTone - 33 < 0 ? 0 : colorTone - 33, end: colorTone.toDouble()),
                duration: Durations.long1,
                curve: Curves.easeInOutQuart,
                builder: (context, value, _) {
                  return CircularProgressIndicator(
                    value: value / 100,
                    strokeCap: StrokeCap.round,
                    strokeWidth: 3,
                  );
                },
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            transformAlignment: Alignment.center,
            transform: Matrix4.identity()
              ..scale(
                // black / white color look smaller with eye even they has same size. Scale a little bit.
                selected ? 0.8 : (backgroundColor == Colors.black || backgroundColor == Colors.white ? 1.03 : 1.0),
              ),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: selected
                ? SpFadeIn.bound(
                    child: Icon(
                      SpIcons.tune,
                      color: backgroundColor == null
                          ? null
                          : ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                    ),
                  )
                : child,
          ),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    } else {
      return button;
    }
  }
}
