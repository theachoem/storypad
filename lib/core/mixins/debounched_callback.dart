import 'dart:async';
import 'package:flutter/material.dart';

mixin DebounchedCallback {
  final Map<String, Timer?> _timers = {};
  Timer? _singleTimer;

  // With a key: only that key's timer (a key not used yet has none). Without: the last one started.
  Timer? _timer(String? key) => key == null ? _singleTimer : _timers[key];

  void debouncedCallback(
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 300),
    String? key,
  }) {
    cancelTimer(key);
    _singleTimer = Timer(duration, () async {
      callback();
    });
    if (key != null) {
      _timers[key] = _singleTimer;
    }
  }

  /// Whether a callback is waiting for its debounce to pass.
  bool hasPendingCallback([String? key]) => _timer(key)?.isActive ?? false;

  void cancelTimer(String? key) {
    if (_timer(key) != null && _timer(key)!.isActive) {
      _timer(key)?.cancel();
    }
  }
}
