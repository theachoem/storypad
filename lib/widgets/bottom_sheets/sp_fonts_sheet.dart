import 'package:flutter/material.dart';
import 'package:storypad/views/fonts/fonts_view.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';

class SpFontsSheet extends BaseBottomSheet {
  final String currentFontFamily;
  final FontWeight currentFontWeight;
  final void Function(String fontFamily) onChanged;

  SpFontsSheet({
    required this.currentFontFamily,
    required this.currentFontWeight,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.7,
      builder: (context, controller) {
        return PrimaryScrollController(
          controller: controller,
          child: FontsView(
            params: FontsRoute(
              currentFontFamily: currentFontFamily,
              currentFontWeight: currentFontWeight,
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}
