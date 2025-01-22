import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/services/date_format_service.dart';

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
          leading: const Icon(Icons.sell),
          title: Text(tag.title),
          subtitle: Text(DateFormatService.yMEd_jmsNullable(tag.updatedAt) ?? 'N/A'),
        );
      },
    );
  }
}
