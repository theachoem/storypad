import 'package:flutter/material.dart';
import 'package:storypad/core/rich_text/rich_text.dart';
import 'package:storypad/widgets/sp_color_picker.dart';
import 'package:storypad/widgets/sp_floating_pop_up_button.dart';

/// Standalone color button widget for rich text formatting.
///
/// This widget provides color and background color selection for text,
/// without depending on flutter_quill's internal toolbar APIs.
class SpRichTextColorButton extends StatefulWidget {
  const SpRichTextColorButton({
    required this.controller,
    required this.isBackground,
    this.positionedOnUpper = true,
    this.tooltip,
    super.key,
  });

  final RichTextController controller;
  final bool isBackground;
  final bool positionedOnUpper;
  final String? tooltip;

  @override
  State<SpRichTextColorButton> createState() => _SpRichTextColorButtonState();
}

class _SpRichTextColorButtonState extends State<SpRichTextColorButton> {
  late bool _isToggledColor;
  late bool _isToggledBackground;

  @override
  void initState() {
    super.initState();
    final style = widget.controller.getSelectionStyle();
    _isToggledColor = style.containsKey('color');
    _isToggledBackground = style.containsKey('background');
    widget.controller.addListener(_handleSelectionChange);
  }

  @override
  void didUpdateWidget(covariant SpRichTextColorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleSelectionChange);
      widget.controller.addListener(_handleSelectionChange);
      final style = widget.controller.getSelectionStyle();
      _isToggledColor = style.containsKey('color');
      _isToggledBackground = style.containsKey('background');
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleSelectionChange);
    super.dispose();
  }

  void _handleSelectionChange() {
    final style = widget.controller.getSelectionStyle();
    setState(() {
      _isToggledColor = style.containsKey('color');
      _isToggledBackground = style.containsKey('background');
    });
  }

  Color? _getCurrentColor() {
    final style = widget.controller.getSelectionStyle();
    final colorValue = widget.isBackground ? style['background'] : style['color'];
    if (colorValue == null) return null;
    return _stringToColor(colorValue.toString());
  }

  /// Converts hex color string to Color object.
  /// Handles formats: '#RRGGBB', '#AARRGGBB', 'RRGGBB', 'AARRGGBB'
  Color _stringToColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return Colors.transparent;
    }

    // Remove '#' if present
    String hexString = colorString.replaceAll('#', '');

    // Add alpha if not present (6 chars = RGB, need ARGB)
    if (hexString.length == 6) {
      hexString = 'FF$hexString';
    }

    try {
      return Color(int.parse(hexString, radix: 16));
    } catch (e) {
      return Colors.transparent;
    }
  }

  /// Converts Color to hex string without '#' prefix.
  /// Returns format: 'AARRGGBB'
  String _colorToHex(Color color) {
    return '${(color.a * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
        '${(color.r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
        '${(color.g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
        '${(color.b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}';
  }

  Color _contrastColor(Color backgroundColor) {
    // Calculate relative luminance
    if (ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark) {
      return Colors.white;
    }
    return Colors.black;
  }

  void _applyColor(Color? color) {
    final attributeKey = widget.isBackground ? 'background' : 'color';

    if (color == null) {
      // Remove color formatting
      widget.controller.removeFormat(attributeKey);
    } else {
      // Apply color formatting
      final hexColor = '#${_colorToHex(color)}';
      widget.controller.formatSelection(attributeKey, hexColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Get current color
    final currentColor = _getCurrentColor();
    final isToggled = widget.isBackground ? _isToggledBackground : _isToggledColor;

    // Determine icon and fill colors
    Color iconColor = isToggled && currentColor != null ? currentColor : (theme.iconTheme.color ?? Colors.black);
    Color? fillColor;
    Color? displayIconColor;

    if (isToggled && currentColor != null) {
      final contrastColor = _contrastColor(currentColor);

      if (contrastColor == Colors.black) {
        if (isDarkMode) {
          fillColor = Colors.transparent;
          displayIconColor = iconColor;
        } else {
          fillColor = iconColor;
          displayIconColor = theme.iconTheme.color;
        }
      } else {
        // contrastColor == Colors.white
        if (isDarkMode) {
          fillColor = iconColor;
          displayIconColor = theme.iconTheme.color;
        } else {
          fillColor = Colors.transparent;
          displayIconColor = iconColor;
        }
      }
    } else {
      displayIconColor = theme.iconTheme.color;
    }

    final iconData = widget.isBackground ? Icons.format_color_fill : Icons.color_lens;
    final defaultTooltip = widget.isBackground ? 'Background Color' : 'Font Color';

    return SpFloatingPopUpButton(
      estimatedFloatingWidth: spColorPickerMinWidth,
      bottomToTop: !widget.positionedOnUpper,
      dyGetter: (dy) {
        if (widget.positionedOnUpper) {
          return dy + 54.0;
        } else {
          return dy - (spOnPickingColorHeight * 2 - 8);
        }
      },
      floatingBuilder: (close) {
        return SpColorPicker(
          position: widget.positionedOnUpper ? SpColorPickerPosition.top : SpColorPickerPosition.bottom,
          currentColor: currentColor,
          level: SpColorPickerLevel.two,
          onPickedColor: (color) {
            // Toggle off if same color selected
            if (color == currentColor) {
              _applyColor(null);
            } else {
              _applyColor(color);
            }
            close();
          },
        );
      },
      builder: (open) {
        return IconButton(
          tooltip: widget.tooltip ?? defaultTooltip,
          icon: Icon(iconData, color: displayIconColor),
          style: ButtonStyle(
            backgroundColor: fillColor != null ? WidgetStatePropertyAll(fillColor) : null,
          ),
          onPressed: open,
        );
      },
    );
  }
}
