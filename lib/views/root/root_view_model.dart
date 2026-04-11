import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/home/home_view.dart';

class RootViewModel extends ChangeNotifier with DebounchedCallback {
  // This is to trigger auto backup when user navigates to home page.
  // It is not fully accurate as some data can be modified directly on home page,
  // but it is good enough for most cases. User can still click backup button manually to ensure data is backed up.
  void autoBackupWhenNavigateToHome(Route<dynamic> route, BuildContext context) {
    debouncedCallback(duration: const Duration(seconds: 1), () {
      if (!context.mounted) return;
      if (route.settings.name == const HomeRoute().routeName) {
        BackupProvider? backupProvider;

        try {
          backupProvider = context.read<BackupProvider>();
        } catch (e) {
          // There are case where backup provider might not be available yet.
          return;
        }

        if (backupProvider.readyToSynced && !backupProvider.allYearSynced) {
          backupProvider.autoSync(context: context);
        }
      }
    });
  }
}
