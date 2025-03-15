import 'package:flutter/material.dart';
import 'package:storypad/views/search/filter/search_filter_view.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';

class SearchFilterBottomSheet extends BaseBottomSheet {
  final SearchFilterRoute params;

  SearchFilterBottomSheet({
    required this.params,
  });

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, controller) {
        return PrimaryScrollController(
          controller: controller,
          child: SearchFilterView(params: params),
        );
      },
    );
  }
}
