import 'package:flutter/material.dart';

class BackupDefaultTableViewer extends StatelessWidget {
  const BackupDefaultTableViewer({
    super.key,
    required this.tableContents,
  });

  final List<Map<String, dynamic>> tableContents;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tableContents.length,
      itemBuilder: (context, index) {
        Map<dynamic, dynamic> content = tableContents[index];
        return ListTile(
          title: Text(content['id'].toString()),
        );
      },
    );
  }
}
