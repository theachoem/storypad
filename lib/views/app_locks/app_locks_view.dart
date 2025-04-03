import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:storypad/providers/app_lock_provider.dart' show AppLockProvider;
import 'package:storypad/views/app_locks/security_questions/security_questions_view.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';

import 'app_locks_view_model.dart';

part 'app_locks_content.dart';

class AppLocksRoute extends BaseRoute {
  AppLocksRoute();

  @override
  Future<T?> push<T extends Object?>(
    BuildContext context, {
    bool rootNavigator = false,
  }) async {
    bool authenticated = await context.read<AppLockProvider>().authenticateIfHas(context);
    if (!authenticated || !context.mounted) return null;

    return super.push(
      context,
      rootNavigator: rootNavigator,
    );
  }

  @override
  Widget buildPage(BuildContext context) => AppLocksView(params: this);
}

class AppLocksView extends StatelessWidget {
  const AppLocksView({
    super.key,
    required this.params,
  });

  final AppLocksRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<AppLocksViewModel>(
      create: (context) => AppLocksViewModel(params: params),
      builder: (context, viewModel, child) {
        return _AppLocksContent(viewModel);
      },
    );
  }
}
