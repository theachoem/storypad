import 'package:flutter/material.dart';

/// [SpAppInitializer] is a widget that runs asynchronous platform channel initializers
/// after [runApp] is called and the widget tree is built. This is useful for
/// platform channel-based initialization (e.g., plugins, background recovery, etc.)
/// which require all plugins to be registered, as this only occurs after the app starts.
///
/// **Note:**
/// - This widget should NOT be used for loading data that the UI critically depends on
///   for first render, because the UI will already be built when your [onPlatformInitialized]
///   callback runs.
/// - Use it for tasks that must run after platform channels are ready and
///   where a brief delay or non-blocking initialization is acceptable.
class SpAppInitializer extends StatefulWidget {
  const SpAppInitializer({
    super.key,
    required this.child,
    required this.onPlatformInitialized,
  });

  final Future<void> Function() onPlatformInitialized;
  final Widget child;

  @override
  State<SpAppInitializer> createState() => _SpAppInitializerState();
}

class _SpAppInitializerState extends State<SpAppInitializer> {
  @override
  void initState() {
    super.initState();

    widget.onPlatformInitialized();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
