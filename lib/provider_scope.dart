import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/providers/app_lock_provider.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/providers/in_app_update_provider.dart';
import 'package:storypad/providers/relax_sounds_provider.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/providers/device_preferences_provider.dart';

// global providers
class ProviderScope extends StatelessWidget {
  const ProviderScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ListenableProvider<BackupProvider>(
          create: (context) => BackupProvider(),
        ),
        ListenableProvider<TagsProvider>(
          create: (context) => TagsProvider(),
        ),
        ListenableProvider<AppLockProvider>(
          create: (context) => AppLockProvider(),
        ),
        ListenableProvider<DevicePreferencesProvider>(
          create: (context) => DevicePreferencesProvider(),
        ),
        ListenableProvider<InAppUpdateProvider>(
          create: (context) => InAppUpdateProvider(),
        ),
        ListenableProvider<InAppPurchaseProvider>(
          create: (context) => InAppPurchaseProvider(context),
        ),
        ListenableProvider<RelaxSoundsProvider>(
          lazy: true,
          create: (context) => RelaxSoundsProvider(),
        ),
      ],
      child: child,
    );
  }
}
