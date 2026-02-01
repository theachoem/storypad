import 'package:storypad/core/services/windowed_detector_service.dart';
import 'package:storypad/core/storages/new_badge_storage.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/providers/root_provider.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/root/local_widgets/root_side_bar.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/widgets/side_items/side_items.dart';
import 'package:storypad/widgets/sp_app_lock_wrapper.dart';
import 'package:storypad/widgets/sp_onboarding_wrapper.dart';

import 'root_view_model.dart';

part 'root_content.dart';
part 'local_widgets/root_route_observer.dart';

class RootView extends StatelessWidget {
  const RootView({
    super.key,
  });

  static BuildContext? _rootContext;
  static BuildContext? get rootContext => _rootContext?.mounted ?? false ? _rootContext : null;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<RootViewModel>(
      create: (context) => RootViewModel(),
      builder: (context, viewModel, child) {
        _rootContext = context;

        final rootProvider = Provider.of<RootProvider>(context);
        return _RootContent(viewModel, rootProvider);
      },
    );
  }
}
