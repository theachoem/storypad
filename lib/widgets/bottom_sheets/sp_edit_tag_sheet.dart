import 'package:flutter/material.dart';
import 'package:storypad/views/tags/edit/edit_tag_view.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';

/// The edit/new tag form as a sheet, for opening it from another sheet (the story labels sheet)
/// instead of a whole page on top. Pops an [EditTagResult], like [EditTagRoute].
class SpEditTagSheet extends BaseBottomSheet {
  const SpEditTagSheet({required this.params});

  final EditTagRoute params;

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return Column(
      mainAxisSize: .min,
      children: [
        Flexible(child: EditTagView(params: params, inSheet: true)),
        buildBottomPadding(bottomPadding),
      ],
    );
  }
}
