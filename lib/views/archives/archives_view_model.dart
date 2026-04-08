import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/widgets/story_list/sp_story_list_multi_edit_wrapper.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/types/path_type.dart';
import 'archives_view.dart';

class ArchivesViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ArchivesRoute params;

  ArchivesViewModel({
    required this.params,
  }) {
    load();
  }

  int editedKey = 0;
  late PathType type = params.pathType;

  List<int>? years;

  Future<void> load() async {
    // years can't be empty, it will always return current year at least.
    years = await StoryDbModel.db
        .getStoryCountsByYear(
          filters: {
            'types': [type.name],
          },
        )
        .then((map) => map.keys.toList()..sort((a, b) => b.compareTo(a)));

    notifyListeners();
  }

  void refreshList() {
    editedKey++;
    load();
  }

  Future<void> onPopInvokedWithResult(bool didPop, dynamic result, BuildContext context) async {
    if (didPop) return;

    bool shouldPop = true;

    if (SpStoryListMultiEditWrapper.of(context).selectedStories.isNotEmpty) {
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
