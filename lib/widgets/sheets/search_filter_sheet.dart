import 'package:flutter/material.dart';
import 'package:storypad/views/search/filter/search_filter_view.dart';
import 'package:storypad/widgets/sheets/base_bottom_sheet.dart';

class SearchFilterSheet extends BaseBottomSheet {
  final SearchFilterRoute params;

  SearchFilterSheet({
    required this.params,
  });

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SearchFilterView(
      params: params,
    );
  }
}
