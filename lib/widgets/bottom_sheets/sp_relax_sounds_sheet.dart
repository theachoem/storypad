import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart' show kIsCupertino;
import 'package:storypad/views/relax_sounds/relax_sounds_view.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';

class SpRelaxSoundsSheet extends BaseBottomSheet {
  const SpRelaxSoundsSheet();

  @override
  bool get fullScreen => true;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    if (kIsCupertino) {
      return buildView();
    } else {
      double maxChildSize = 1 - View.of(context).viewPadding.top / MediaQuery.of(context).size.height;
      return DraggableScrollableSheet(
        expand: false,
        maxChildSize: maxChildSize,
        initialChildSize: maxChildSize,
        builder: (context, controller) {
          return PrimaryScrollController(
            controller: controller,
            child: buildView(),
          );
        },
      );
    }
  }

  RelaxSoundsView buildView() {
    return const RelaxSoundsView(
      params: RelaxSoundsRoute(),
    );
  }
}
