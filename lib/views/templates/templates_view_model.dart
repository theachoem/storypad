import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/views/templates/edit/edit_template_view.dart';
import 'package:storypad/views/templates/show/show_template_view.dart';
import 'templates_view.dart';

class TemplatesViewModel extends ChangeNotifier with DisposeAwareMixin {
  final TemplatesRoute params;

  TemplatesViewModel({
    required this.params,
  }) {
    load();
  }

  CollectionDbModel<TemplateDbModel>? templates;

  Future<void> load() async {
    templates = await TemplateDbModel.db.where();
    notifyListeners();
  }

  Future<void> goToNewPage(BuildContext context) async {
    await EditTemplateRoute().push(context);
    await load();
  }

  void goToShowPage(BuildContext context, TemplateDbModel template) async {
    final result = await ShowTemplateRoute(
      template: template,
      initialYear: params.initialYear,
      initialMonth: params.initialMonth,
      initialDay: params.initialDay,
    ).push(context);

    if (context.mounted && result is StoryDbModel) {
      Navigator.maybePop(context, result);
    } else {
      await load();
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (templates == null) return;

    templates = templates!.reorder(oldIndex: oldIndex, newIndex: newIndex);
    notifyListeners();

    int length = templates!.items.length;
    for (int i = 0; i < length; i++) {
      final item = templates!.items[i];
      if (item.index != i) {
        await TemplateDbModel.db.set(item.copyWith(index: i, updatedAt: DateTime.now()));
      }
    }

    await load();
  }
}
