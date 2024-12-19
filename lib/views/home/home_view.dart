import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:spooky_mb/core/base/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:spooky_mb/core/databases/models/story_content_db_model.dart';
import 'package:spooky_mb/core/databases/models/story_db_model.dart';
import 'package:spooky_mb/core/services/date_format_service.dart';
import 'package:spooky_mb/views/home/local_widgets/home_flexible_space_bar.dart';
import 'package:spooky_mb/views/home/local_widgets/rounded_indicator.dart';
import 'package:spooky_mb/views/home/local_widgets/story_tile.dart';
import 'package:spooky_mb/views/archives/archives_view.dart';
import 'package:spooky_mb/views/backups/backups_view.dart';
import 'package:spooky_mb/views/setting/setting_view.dart';
import 'package:spooky_mb/views/tags/tags_view.dart';
import 'package:spooky_mb/views/theme/theme_view.dart';
import 'package:spooky_mb/widgets/sp_nested_navigation.dart';

import 'home_view_model.dart';

part 'home_adaptive.dart';
part 'local_widgets/month.dart';
part 'local_widgets/home_end_drawer.dart';
part 'local_widgets/home_scaffold.dart';
part 'local_widgets/timeline_verticle_divider.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<HomeViewModel>(
      create: (context) => HomeViewModel(),
      builder: (context, viewModel, child) {
        return _HomeAdaptive(viewModel);
      },
    );
  }
}
