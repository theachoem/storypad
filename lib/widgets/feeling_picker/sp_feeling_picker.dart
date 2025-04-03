import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/feeling_object.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

part 'feeling_group_picker.dart';
part 'feeling_group_item_picker.dart';
part 'feeling_object_card.dart';

class SpFeelingPicker extends StatefulWidget {
  const SpFeelingPicker({
    super.key,
    required this.feeling,
    required this.onPicked,
  });

  final String? feeling;
  final Future<void> Function(String? feeling) onPicked;

  @override
  State<SpFeelingPicker> createState() => _SpFeelingPickerState();
}

class _SpFeelingPickerState extends State<SpFeelingPicker> {
  double width = 300;
  double height = 300;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: width,
      height: height,
      duration: Durations.medium1,
      curve: Curves.ease,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: ColorScheme.of(context).surface,
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Wrap(
          children: [
            Navigator(
              onGenerateRoute: (settings) {
                return MaterialPageRoute(builder: (context) {
                  return _FeelingGroupPicker(
                    feeling: widget.feeling,
                    onPicked: widget.onPicked,
                    onHeightChanged: (height) async {
                      setState(() => this.height = height);
                    },
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
