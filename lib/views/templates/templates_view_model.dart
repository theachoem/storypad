import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
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

  Future<void> goToEditPage(BuildContext context, TemplateDbModel template) async {
    await EditTemplateRoute(initialTemplate: template).push(context);
    await load();
  }

  void delete(BuildContext context, TemplateDbModel template) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: tr('dialog.are_you_sure.title'),
      message: tr('dialog.are_you_sure.you_cant_undo_message'),
      isDestructiveAction: true,
    );

    if (result == OkCancelResult.ok) {
      await TemplateDbModel.db.delete(template.id);
      await load();
    }
  }

  void goToShowPage(BuildContext context, TemplateDbModel template) async {
    ShowTemplateRoute(
      template: template,
    ).push(context);
  }

  void useTemplate(BuildContext context, TemplateDbModel template) async {
    final result = await EditStoryRoute(
      initialYear: params.initialYear,
      initialMonth: params.initialMonth,
      initialDay: params.initialDay,
      template: template,
    ).push(context);

    if (context.mounted && result is StoryDbModel) {
      Navigator.maybePop(context, result);
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
