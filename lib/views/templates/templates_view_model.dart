import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/views/templates/edit/edit_template_view.dart';
import 'templates_view.dart';

class TemplatesViewModel extends ChangeNotifier with DisposeAwareMixin {
  final TemplatesRoute params;

  TemplatesViewModel({
    required this.params,
  }) {
    load();
  }

  List<TemplateDbModel>? templates;

  Future<void> load() async {
    templates = await TemplateDbModel.db.where().then((e) => e?.items ?? []);
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
}
