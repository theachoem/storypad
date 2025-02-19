import 'dart:math';
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/feeling_object.dart';

class SpFeelingPicker extends StatefulWidget {
  const SpFeelingPicker({
    super.key,
    required this.feeling,
    required this.onPicked,
  });

  final String? feeling;
  final void Function(String? feeling) onPicked;

  @override
  State<SpFeelingPicker> createState() => _SpFeelingPickerState();
}

class _SpFeelingPickerState extends State<SpFeelingPicker> {
  late final ScrollController controller;
  late final List<MapEntry<String, FeelingObject>> feelingsMap;
  late String? feeling;

  @override
  void initState() {
    feeling = widget.feeling;
    feelingsMap = FeelingObject.feelingsMap.entries.toList();
    controller = ScrollController();
    animateToInitialFeeling();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void animateToInitialFeeling() {
    double offset = findInitialScrollOffset(feeling);
    if (offset < 100) return;
    Future.delayed(Durations.medium2).then((value) {
      controller.animateTo(
        min(offset, controller.position.maxScrollExtent),
        duration: Duration(milliseconds: max(100 * offset ~/ 100, 350)),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  void onPicked(String feeling) {
    widget.onPicked(
      feeling == this.feeling ? null : feeling,
    );
  }

  double findInitialScrollOffset(String? selectedFeeling) {
    if (selectedFeeling == null) return 0;

    FeelingObject? selected = FeelingObject.feelingsMap[selectedFeeling];
    List<String> keysList = FeelingObject.feelingsMap.keys.toList();

    if (selected != null) {
      int index = keysList.indexOf(selectedFeeling);
      int rowIndex = (index / 3).floor();
      int lastRow = keysList.length - 3 * 1;

      // scroll to -2 on last row, while -1 on other
      // to made them in middle on grid of 3
      if (index > lastRow) {
        rowIndex = max(0, rowIndex - 2);
        return rowIndex * 100;
      } else {
        rowIndex = max(0, rowIndex - 1);
        return rowIndex * 100;
      }
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: 300,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: ColorScheme.of(context).surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: ColorScheme.of(context).onSurface.withValues(alpha: 0.1), width: 1),
      ),
      child: GridView.builder(
        controller: controller,
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: feelingsMap.length,
        cacheExtent: 100,
        itemBuilder: (context, index) {
          final feeling = feelingsMap[index];
          return buildFeelingCard(feeling, context);
        },
      ),
    );
  }

  Widget buildFeelingCard(
    MapEntry<String, FeelingObject> feeling,
    BuildContext context,
  ) {
    return Material(
      color: this.feeling == feeling.key ? ColorScheme.of(context).readOnly.surface1 : Colors.transparent,
      child: InkWell(
        onTap: () => onPicked(feeling.key),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              feeling.value.image64.image(
                width: 36,
                height: 36,
              ),
              const SizedBox(height: 8.0),
              Text(
                feeling.value.translation(context),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
