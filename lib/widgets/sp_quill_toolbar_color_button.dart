// ignore_for_file: implementation_imports, invalid_use_of_internal_member

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/internal.dart';
import 'package:storypad/widgets/sp_color_picker.dart';
import 'package:storypad/widgets/sp_floating_pop_up_button.dart';

import 'package:flutter_quill/src/toolbar/base_button/base_value_button.dart';
import 'package:flutter_quill/src/common/utils/color.dart';
import 'package:flutter_quill/src/editor_toolbar_shared/color.dart';

typedef QuillToolbarColorBaseButton =
    QuillToolbarBaseButton<QuillToolbarColorButtonOptions, QuillToolbarColorButtonExtraOptions>;

typedef QuillToolbarColorBaseButtonState<W extends SpQuillToolbarColorButton> =
    QuillToolbarCommonButtonState<W, QuillToolbarColorButtonOptions, QuillToolbarColorButtonExtraOptions>;

/// Controls color styles.
///
/// When pressed, this button displays overlay toolbar with
/// buttons for each color.
class SpQuillToolbarColorButton extends QuillToolbarColorBaseButton {
  const SpQuillToolbarColorButton({
    required super.controller,
    required this.isBackground,
    this.positionedOnUpper = true,
    super.options = const QuillToolbarColorButtonOptions(),
    super.key,
  });

  /// Is this background color button or font color
  final bool isBackground;
  final bool positionedOnUpper;

  @override
  SpQuillToolbarColorButtonState createState() => SpQuillToolbarColorButtonState();
}

class SpQuillToolbarColorButtonState extends QuillToolbarColorBaseButtonState {
  late bool _isToggledColor;
  late bool _isToggledBackground;

  @override
  String get defaultTooltip => widget.isBackground ? context.loc.backgroundColor : context.loc.fontColor;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  void _didChangeEditingValue() {
    setState(() {
      _isToggledColor = _getIsToggledColor(widget.controller.getSelectionStyle().attributes);
      _isToggledBackground = _getIsToggledBackground(widget.controller.getSelectionStyle().attributes);
    });
  }

  @override
  void initState() {
    super.initState();
    _isToggledColor = _getIsToggledColor(_selectionStyle.attributes);
    _isToggledBackground = _getIsToggledBackground(_selectionStyle.attributes);
    widget.controller.addListener(_didChangeEditingValue);
  }

  bool _getIsToggledColor(Map<String, Attribute> attrs) {
    return attrs.containsKey(Attribute.color.key);
  }

  bool _getIsToggledBackground(Map<String, Attribute> attrs) {
    return attrs.containsKey(Attribute.background.key);
  }

  @override
  void didUpdateWidget(covariant SpQuillToolbarColorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _isToggledColor = _getIsToggledColor(_selectionStyle.attributes);
      _isToggledBackground = _getIsToggledBackground(_selectionStyle.attributes);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  @override
  IconData get defaultIconData => widget.isBackground ? Icons.format_color_fill : Icons.color_lens;

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);

    Color? iconColor = _isToggledColor && !widget.isBackground
        ? stringToColor(_selectionStyle.attributes['color']?.value)
        : themeData.iconTheme.color;

    Color? iconColorBackground = _isToggledBackground && widget.isBackground
        ? stringToColor(_selectionStyle.attributes['background']?.value)
        : themeData.iconTheme.color;

    bool isDarkMode = themeData.colorScheme.brightness == Brightness.dark;
    Color? fillColor = _textColorForBackground(iconColor!);
    Color fillColorBackground = _textColorForBackground(iconColorBackground!);

    Color? displayIconColor;
    Color? displayIconColorBackground;

    if (fillColor == Colors.black) {
      if (isDarkMode) {
        fillColor = Colors.transparent;
        displayIconColor = iconColor;
      } else {
        fillColor = iconColor;
        displayIconColor = themeData.iconTheme.color;
      }
    } else if (fillColor == Colors.white) {
      if (isDarkMode) {
        fillColor = iconColor;
        displayIconColor = themeData.iconTheme.color;
      } else {
        fillColor = Colors.transparent;
        displayIconColor = iconColor;
      }
    }

    if (fillColorBackground == Colors.black) {
      if (isDarkMode) {
        fillColorBackground = Colors.transparent;
        displayIconColorBackground = iconColorBackground;
      } else {
        fillColorBackground = iconColorBackground;
        displayIconColorBackground = themeData.iconTheme.color;
      }
    } else if (fillColorBackground == Colors.white) {
      if (isDarkMode) {
        fillColorBackground = iconColorBackground;
        displayIconColorBackground = themeData.iconTheme.color;
      } else {
        fillColorBackground = Colors.transparent;
        displayIconColorBackground = iconColorBackground;
      }
    }

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
          currentColor: widget.isBackground ? iconColorBackground : iconColor,
          level: SpColorPickerLevel.two,
          onPickedColor: (color) {
            if (widget.isBackground) {
              _changeColor(context, color == iconColorBackground ? null : color);
            } else {
              _changeColor(context, color == iconColor ? null : color);
            }
            close();
          },
        );
      },
      builder: (open) {
        return QuillToolbarIconButton(
          tooltip: tooltip,
          isSelected: false,
          iconTheme: QuillIconTheme(
            iconButtonUnselectedData: IconButtonData(
              color: widget.isBackground ? displayIconColorBackground : displayIconColor,
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(widget.isBackground ? fillColorBackground : fillColor),
              ),
            ),
          ),
          icon: Icon(iconData, size: iconSize * iconButtonFactor),
          onPressed: () => open(),
          afterPressed: afterButtonPressed,
        );
      },
    );
  }

  void _changeColor(BuildContext context, Color? color) {
    if (color == null) {
      widget.controller.formatSelection(
        widget.isBackground ? const BackgroundAttribute(null) : const ColorAttribute(null),
      );
      return;
    }
    var hex = colorToHex(color);
    hex = '#$hex';
    widget.controller.formatSelection(
      widget.isBackground ? BackgroundAttribute(hex) : ColorAttribute(hex),
    );
  }

  Color _textColorForBackground(Color backgroundColor) {
    if (ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark) {
      return Colors.white;
    }
    return Colors.black;
  }
}
