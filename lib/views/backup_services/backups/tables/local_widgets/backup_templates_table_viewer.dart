import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';

class BackupTemplatesTableViewer extends StatelessWidget {
  const BackupTemplatesTableViewer({
    super.key,
    required this.templates,
  });

  final List<TemplateDbModel> templates;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return ListTile(
          title: Text(template.content?.title ?? tr('general.na')),
          subtitle: Text(DateFormatHelper.yMEd_jmNullable(template.updatedAt, context.locale) ?? tr("general.na")),
        );
      },
    );
  }
}
