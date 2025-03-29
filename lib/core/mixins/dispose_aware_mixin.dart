import 'package:flutter/material.dart' show ChangeNotifier;

mixin DisposeAwareMixin on ChangeNotifier {
  bool _disposed = false;
  bool get disposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
