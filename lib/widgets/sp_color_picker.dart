import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/widgets/sp_cross_fade.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

enum SpColorPickerLevel {
  one,
  two,
}

enum SpColorPickerPosition {
  top,
  bottom,
}

class SpColorPicker extends StatefulWidget {
  const SpColorPicker({
    super.key,
    required this.onPickedColor,
    this.currentColor,
    this.level = SpColorPickerLevel.one,
    this.position = SpColorPickerPosition.top,
  });

  final SpColorPickerLevel level;
  final SpColorPickerPosition position;
  final ValueChanged<Color> onPickedColor;
  final Color? currentColor;

  @override
  SpColorPickerState createState() => SpColorPickerState();
}

/// value 2 at end is border width `all(1)`
const double spOnPickingSwatchHeight = 34 * 4 + 16.0 * 2 + 8.0 * 4 + 2;
const double spOnPickingColorHeight = 34 * 2 + 16.0 * 2 + 8.0 * 2 - 4 + 2;
const double spColorPickerMinWidth = 246.0;

class SpColorPickerState extends State<SpColorPicker> {
  /// final map = {
  ///   0: [0, 1, 2, 3],
  ///   1: [4, 5, 6, 7],
  ///   2: [8, 9, 10, 11],
  ///   3: [12, 13, 14, 15],
  ///   4: [16, 17, 18, 19],
  ///   5: [20]
  /// };
  ///
  Map<int, List<int>> listToTreeMap(List<dynamic> list, {int rowLength = 5}) {
    Map<int, List<int>> map = {};
    for (int c = 0; c <= list.length ~/ rowLength; c++) {
      List<int> children = [];
      for (int r = c; r < c + rowLength; r++) {
        int index = c * (rowLength - 1) + r;
        if (index <= list.length - 1) children.add(index);
      }
      map[c] = children;
    }

    map.removeWhere((key, value) => value.isEmpty);
    return map;
  }

  Color? currentSelectedColor;
  Color? currentSelectedColorsSwatch;

  Map<int, List<int>>? _colorsMap;
  bool isColorChildPicking = false;

  final List<ColorSwatch> _colorsSwatch = [];
  List<Color?> _colorNormal = [];

  @override
  void initState() {
    super.initState();
    _colorsSwatch.addAll(kMaterialColors);
    _colorsSwatch.add(getBlackWhiteSwatch());
    _colorsMap = listToTreeMap(_colorsSwatch);
    _setCurrentColor();
  }

  ColorSwatch<dynamic> getBlackWhiteSwatch() {
    bool isDarkMode = PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    final ColorSwatch blackWhiteSwatchColor = ColorSwatch(
      isDarkMode ? 0xFFFFFFFF : 0xFF000000,
      const {50: Color(0xff000000), 100: Color(0xffffffff)},
    );

    return blackWhiteSwatchColor;
  }

  void _setCurrentColor() {
    Future.delayed(const Duration(milliseconds: 1)).then((value) {
      for (ColorSwatch e in _colorsSwatch) {
        final colorSwatches = _getMaterialColorShades(e);
        if (colorSwatches.contains(widget.currentColor)) {
          setState(() {
            currentSelectedColorsSwatch = e;
          });
        }
      }
    });
  }

  List<Color?> _getMaterialColorShades(ColorSwatch color) {
    return <Color?>[
      if (color[50] != null) color[50],
      if (color[100] != null) color[100],
      if (color[200] != null) color[200],
      if (color[300] != null) color[300],
      if (color[400] != null) color[400],
      if (color[500] != null) color[500],
      if (color[600] != null) color[600],
      if (color[700] != null) color[700],
      if (color[800] != null) color[800],
      if (color[900] != null) color[900],
    ];
  }

  void onPickedColor(Color color) {
    switch (widget.level) {
      case SpColorPickerLevel.one:
        widget.onPickedColor(color);
        break;
      case SpColorPickerLevel.two:
        if (isColorChildPicking == false) {
          extendChildren(color);
        } else {
          widget.onPickedColor(color);
        }
        break;
    }
  }

  // ignore: strict_top_level_inference
  void extendChildren(color) {
    setState(() {
      isColorChildPicking = true;
      _colorNormal = _getMaterialColorShades(color!);
      _colorsMap = listToTreeMap(_colorNormal);
    });

    Future.delayed(const Duration(milliseconds: 100)).then((value) {
      if (widget.currentColor != null && _colorNormal.contains(widget.currentColor)) {
        setState(() {
          currentSelectedColor = widget.currentColor;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Alignment containerAlignment;
    Alignment childSwapAlignment;

    switch (widget.position) {
      case SpColorPickerPosition.top:
        containerAlignment = Alignment.topLeft;
        childSwapAlignment = Alignment.bottomLeft;
        break;
      case SpColorPickerPosition.bottom:
        containerAlignment = Alignment.bottomLeft;
        childSwapAlignment = Alignment.topCenter;
        break;
    }

    return Container(
      height: spOnPickingSwatchHeight,
      alignment: containerAlignment,
      child: SpCrossFade(
        alignment: childSwapAlignment,
        showFirst: !isColorChildPicking,
        duration: Durations.medium1,
        firstChild: buildColorListWrapper(
          context: context,
          child: buildColorListing(context),
          height: spOnPickingSwatchHeight,
        ),
        secondChild: buildColorListWrapper(
          context: context,
          height: _colorsMap!.length == 1 ? spOnPickingColorHeight - 32 - 12 : spOnPickingColorHeight,
          child: buildColorListing(context),
        ),
      ),
    );
  }

  Widget buildColorListWrapper({
    required BuildContext context,
    required Widget child,
    required double height,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: spColorPickerMinWidth),
      height: height,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: 16.0 - 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), width: 1),
        ),
        child: child,
      ),
    );
  }

  Widget buildColorListing(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        _colorsMap!.length,
        (c) {
          final List<int>? childrenIndex = _colorsMap![c];
          final double bottom = _colorsMap!.length - 1 == c ? 0 : 8.0;
          return Container(
            margin: EdgeInsets.only(bottom: bottom),
            child: Row(
              children: List.generate(
                _colorsMap![c]!.length,
                (i) => buildColorItem(childrenIndex, i, context),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildColorItem(List<int>? childrenIndex, int i, BuildContext context) {
    final int index = childrenIndex![i];
    final double right = i != (childrenIndex.length) - 1 ? 8.0 : 0;
    final dynamic color;
    color = isColorChildPicking ? _colorNormal[index] : _colorsSwatch[index];
    final bool isSelected = currentSelectedColor == color || currentSelectedColorsSwatch == color;

    return SpColorItem(
      color: color,
      selected: isSelected,
      margin: EdgeInsets.only(right: right, bottom: 0, top: 0),
      onPressed: (color) => onPickedColor(color),
      size: 32,
    );
  }
}

class SpColorItem extends StatelessWidget {
  const SpColorItem({
    super.key,
    this.margin,
    this.selected = false,
    this.onPressed,
    required this.color,
    this.size = 32.0,
  });

  final EdgeInsets? margin;
  final bool selected;
  final Color color;
  final void Function(Color)? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Durations.medium1,
      margin: margin,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          width: 2.0,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: selected ? 1 : 0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: SpTapEffect(
          onTap: onPressed != null ? () => onPressed!(color) : null,
          effects: const [
            SpTapEffectType.border,
          ],
          child: Container(
            width: size - 2,
            height: size - 2,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
