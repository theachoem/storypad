import 'package:flutter/material.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

/// A single int option with its display label (e.g. a year or month number).
typedef SpPickerOption = ({int value, String label});

/// Single-select list sheet: a column of options with a check on the selected
/// one. Closes on pick. Mirrors `SpFontWeightSheet`'s pattern.
class SpPickerSheet extends BaseBottomSheet {
  const SpPickerSheet({
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<SpPickerOption> options;
  final int selectedValue;
  final void Function(int value) onChanged;

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      child: SpSingleStateWidget.listen(
        initialValue: selectedValue,
        builder: (context, selected, notifier) {
          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                ...options.map((option) {
                  return ListTile(
                    title: Text(option.label),
                    trailing: Visibility(
                      visible: option.value == selected,
                      child: SpFadeIn.fromBottom(
                        child: Icon(
                          SpIcons.checkCircle,
                          color: ColorScheme.of(context).primary,
                        ),
                      ),
                    ),
                    onTap: () {
                      notifier.value = option.value;
                      onChanged(option.value);
                      Navigator.maybeOf(context)?.pop();
                    },
                  );
                }),
                SizedBox(height: bottomPadding),
              ],
            ),
          );
        },
      ),
    );
  }
}
