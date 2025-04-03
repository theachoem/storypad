import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/widgets/sp_icons.dart';

class BackupTagsTableViewer extends StatelessWidget {
  const BackupTagsTableViewer({
    super.key,
    required this.tags,
  });

  final List<TagDbModel> tags;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        return ListTile(
          leading: Icon(SpIcons.of(context).tag),
          title: Text(tag.title),
          subtitle: Text(DateFormatHelper.yMEd_jmNullable(tag.updatedAt, context.locale) ?? tr("general.na")),
        );
      },
    );
  }
}
