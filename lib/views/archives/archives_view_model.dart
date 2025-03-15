import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/story_list/story_list_multi_edit_wrapper.dart';
import 'package:storypad/widgets/base_view/base_view_model.dart';
import 'package:storypad/core/types/path_type.dart';
import 'archives_view.dart';

class ArchivesViewModel extends BaseViewModel {
  final ArchivesRoute params;

  ArchivesViewModel({
    required this.params,
  });

  int editedKey = 0;
  PathType type = PathType.archives;

  void changeEditKey() {
    editedKey++;
    notifyListeners();
  }

  void setType(PathType type) {
    this.type = type;
    notifyListeners();
  }

  Future<void> onPopInvokedWithResult(bool didPop, dynamic result, BuildContext context) async {
    if (didPop) return;

    bool shouldPop = true;

    if (StoryListMultiEditWrapper.of(context).selectedStories.isNotEmpty) {
      OkCancelResult result = await showOkCancelAlertDialog(
        context: context,
        title: tr("dialog.are_you_sure_to_discard_these_changes.title"),
        isDestructiveAction: true,
        okLabel: tr("button.discard"),
      );
      shouldPop = result == OkCancelResult.ok;
    }

    if (shouldPop && context.mounted) Navigator.of(context).pop(result);
  }
}
