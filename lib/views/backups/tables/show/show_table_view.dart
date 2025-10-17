import 'package:storypad/core/databases/adapters/objectbox/assets_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/events_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/preferences_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/stories_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/tags_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/templates_box.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/event_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/views/backups/tables/local_widgets/backup_assets_table_viewer.dart';
import 'package:storypad/views/backups/tables/local_widgets/backup_default_table_viewer.dart';
import 'package:storypad/views/backups/tables/local_widgets/backup_events_table_viewer.dart';
import 'package:storypad/views/backups/tables/local_widgets/backup_preferences_table_viewer.dart';
import 'package:storypad/views/backups/tables/local_widgets/backup_stories_table_viewer.dart';
import 'package:storypad/views/backups/tables/local_widgets/backup_tags_table_viewer.dart';
import 'package:storypad/views/backups/tables/local_widgets/backup_templates_table_viewer.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';

import 'show_table_view_model.dart';

part 'show_table_content.dart';

class ShowTableRoute extends BaseRoute {
  ShowTableRoute({
    required this.tableName,
    required this.translateTabledName,
    required this.context,
    required this.tableContents,
  });

  final String tableName;
  final String translateTabledName;
  final BuildContext context;
  final List<Map<String, dynamic>> tableContents;

  @override
  Widget buildPage(BuildContext context) => ShowTableView(params: this);
}

class ShowTableView extends StatelessWidget {
  const ShowTableView({
    super.key,
    required this.params,
  });

  final ShowTableRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<ShowTableViewModel>(
      create: (context) => ShowTableViewModel(params: params),
      builder: (context, viewModel, child) {
        return _ShowTableContent(viewModel);
      },
    );
  }
}
