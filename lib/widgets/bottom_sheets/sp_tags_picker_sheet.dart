import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart' show kIsCupertino;
import 'package:storypad/views/tags/tags_view.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';

class SpTagsPickerSheet extends BaseBottomSheet {
  const SpTagsPickerSheet({required this.selectedTagIds, this.maxCount});

  final List<int> selectedTagIds;
  final int? maxCount;

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
        builder: (context, controller) {
          return PrimaryScrollController(
            controller: controller,
            child: buildView(),
          );
        },
      );
    }
  }

  TagsView buildView() {
    return TagsView(
      params: TagsRoute(
        pickMode: true,
        maxCount: maxCount == null ? null : selectedTagIds.length + maxCount!,
        initialSelectedTags: selectedTagIds,
      ),
    );
  }
}
