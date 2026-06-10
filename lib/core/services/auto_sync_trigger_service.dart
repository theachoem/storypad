import 'dart:async';

import 'package:flutter/widgets.dart';

/// Decides when an auto sync flow should run:
/// - Once when [start] is called (e.g. on app startup).
/// - Again whenever the app is resumed from background, throttled by
///   [throttleDuration] so quick app switches don't re-trigger it.
class AutoSyncTriggerService with WidgetsBindingObserver {
  AutoSyncTriggerService({
    required this.onTrigger,
    this.throttleDuration = const Duration(minutes: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final FutureOr<void> Function() onTrigger;
  final Duration throttleDuration;
  final DateTime Function() _now;

  DateTime? _lastTriggerAt;
  DateTime? get lastTriggerAt => _lastTriggerAt;

  /// Starts observing app lifecycle changes and performs the initial trigger.
  void start() {
    WidgetsBinding.instance.addObserver(this);
    _trigger();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_canTrigger) return;

    _trigger();
  }

  bool get _canTrigger {
    final lastTriggerAt = _lastTriggerAt;
    if (lastTriggerAt == null) return true;

    return _now().difference(lastTriggerAt) >= throttleDuration;
  }

  void _trigger() {
    _lastTriggerAt = _now();
    onTrigger();
  }
}
