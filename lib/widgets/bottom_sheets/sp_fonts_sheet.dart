import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart' show kIsCupertino;
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
  bool get fullScreen => true;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    if (kIsCupertino) {
      return buildView();
    } else {
      return DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.7,
        builder: (context, controller) {
          return PrimaryScrollController(
            controller: controller,
            child: buildView(),
          );
        },
      );
    }
  }

  FontsView buildView() {
    return FontsView(
      params: FontsRoute(
        currentFontFamily: currentFontFamily,
        currentFontWeight: currentFontWeight,
        onChanged: onChanged,
      ),
    );
  }
}
