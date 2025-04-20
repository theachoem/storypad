import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/views/discover/discover_view.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';

class SpDiscoverSheet extends BaseBottomSheet {
  final DiscoverRoute params;

  SpDiscoverSheet({
    required this.params,
  });

  @override
  bool get fullScreen => true;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    if (kIsCupertino) {
      return DiscoverView(params: params);
    } else {
      double maxChildSize = 1 - View.of(context).viewPadding.top / MediaQuery.of(context).size.height;
      return DraggableScrollableSheet(
        expand: false,
        maxChildSize: maxChildSize,
        minChildSize: 0.5,
        initialChildSize: maxChildSize,
        builder: (context, controller) {
          return PrimaryScrollController(
            controller: controller,
            child: DiscoverView(params: params),
          );
        },
      );
    }
  }
}
