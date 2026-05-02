import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';

class SpStoriesBottomSheet extends BaseBottomSheet {
  const SpStoriesBottomSheet({
    required this.filter,
  });

  final SearchFilterObject filter;

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: SpStoryList.withQuery(
        filter: filter,
        disableMultiEdit: true,
      ),
    );
  }
}
