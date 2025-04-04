import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/views/search/filter/search_filter_view.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';

class SpSearchFilterBottomSheet extends BaseBottomSheet {
  final SearchFilterRoute params;

  SpSearchFilterBottomSheet({
    required this.params,
  });

  @override
  bool get fullScreen => true;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    if (kIsCupertino) {
      return SearchFilterView(params: params);
    } else {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (context, controller) {
          return PrimaryScrollController(
            controller: controller,
            child: SearchFilterView(params: params),
          );
        },
      );
    }
  }
}
