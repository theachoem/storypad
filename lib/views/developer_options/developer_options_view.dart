import 'package:flutter/material.dart';
import 'package:storypad/views/developer_options/recently_deleted_records/recently_deleted_records_view.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/bottom_sheets/sp_share_logs_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

class DeveloperOptionsRoute extends BaseRoute {
  const DeveloperOptionsRoute();

  @override
  Widget buildPage(BuildContext context) => DeveloperOptionsView(params: this);
}

class DeveloperOptionsView extends StatelessWidget {
  const DeveloperOptionsView({
    super.key,
    required this.params,
  });

  final DeveloperOptionsRoute params;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Developer Options"),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(SpIcons.table),
            title: const Text("Delete Records"),
            subtitle: const Text(
              "For safety, permanently deleted records are kept on your device for 7 days "
              "(and are not backed up to the cloud). "
              "To remove them immediately, clear the app cache.",
            ),
            trailing: const Icon(SpIcons.keyboardRight),
            onTap: () => const RecentlyDeletedRecordsRoute().push(context),
          ),
          ListTile(
            leading: const Icon(SpIcons.info),
            title: const Text("See Debug Logs"),
            subtitle: const Text("View the app debug logs."),
            trailing: const Icon(SpIcons.keyboardRight),
            onTap: () => SpShareLogsBottomSheet().show(context: context),
          ),
        ],
      ),
    );
  }
}
