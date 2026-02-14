part of 'quill_adapter.dart';

/// Quill-specific color button widget for rich text formatting.
///
/// This widget provides color and background color selection for text,
/// using flutter_quill's formatting APIs.
class _QuillRichTextColorButton extends StatefulWidget {
  const _QuillRichTextColorButton({
    required this.controller,
    required this.isBackground,
    this.positionedOnUpper = true,
  });

  final RichTextController controller;
  final bool isBackground;
  final bool positionedOnUpper;

  @override
  State<_QuillRichTextColorButton> createState() => _QuillRichTextColorButtonState();
}

class _QuillRichTextColorButtonState extends State<_QuillRichTextColorButton> {
  late bool _isToggledColor;
  late bool _isToggledBackground;

  /// Access to underlying QuillController for formatting operations
  quill.QuillController get _quillController {
    return (widget.controller as QuillRichTextController).quillController;
  }

  @override
  void initState() {
    super.initState();
    final style = _quillController.getSelectionStyle();
    _isToggledColor = style.attributes.containsKey('color');
    _isToggledBackground = style.attributes.containsKey('background');
    widget.controller.addListener(_handleSelectionChange);
  }

  @override
  void didUpdateWidget(covariant _QuillRichTextColorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleSelectionChange);
      widget.controller.addListener(_handleSelectionChange);
      final style = _quillController.getSelectionStyle();
      _isToggledColor = style.attributes.containsKey('color');
      _isToggledBackground = style.attributes.containsKey('background');
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleSelectionChange);
    super.dispose();
  }

  void _handleSelectionChange() {
    final style = _quillController.getSelectionStyle();
    setState(() {
      _isToggledColor = style.attributes.containsKey('color');
      _isToggledBackground = style.attributes.containsKey('background');
    });
  }

  Color? _getCurrentColor() {
    final style = _quillController.getSelectionStyle();
    final colorValue = widget.isBackground ? style.attributes['background']?.value : style.attributes['color']?.value;
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
      final attribute = widget.isBackground ? quill.Attribute.background : quill.Attribute.color;
      _quillController.formatSelection(quill.Attribute.clone(attribute, null));
    } else {
      // Apply color formatting
      final hexColor = '#${_colorToHex(color)}';
      _quillController.formatSelection(quill.Attribute.fromKeyValue(attributeKey, hexColor));
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
          tooltip: defaultTooltip,
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
