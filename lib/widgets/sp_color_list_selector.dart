// TODO: fix color.value deprecation
// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

class SpColorListSelector extends StatelessWidget {
  const SpColorListSelector({
    super.key,
    required this.selectedColor,
    required this.onChanged,
    this.padding = const EdgeInsets.all(16.0),
  });

  final void Function(Color? color) onChanged;
  final Color? selectedColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(spacing: 4.0, children: [
        buildButton(
          tooltip: tr("button.reset"),
          context: context,
          backgroundColor: null,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(null);
          },
          selected: selectedColor == null,
          child: const Icon(SpIcons.hideSource),
        ),
        ...kMaterialColors.map<Widget>(
          (color) {
            return buildButton(
              context: context,
              child: null,
              backgroundColor: color,
              foregroundColor: Colors.black,
              selected: color.value == selectedColor?.value,
              onTap: () => onChanged(color),
            );
          },
        )
      ]),
    );
  }

  Widget buildButton({
    required VoidCallback onTap,
    required BuildContext context,
    required Widget? child,
    required Color? backgroundColor,
    required Color? foregroundColor,
    bool selected = false,
    String? tooltip,
  }) {
    Widget button = SpTapEffect(
      effects: [
        SpTapEffectType.border,
        SpTapEffectType.scaleDown,
      ],
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
            width: 2.0,
          ),
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: selected
              ? SpFadeIn.fromBottom(
                  child: Icon(
                  SpIcons.check,
                  color: foregroundColor,
                ))
              : child,
        ),
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
