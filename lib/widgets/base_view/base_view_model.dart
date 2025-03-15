import 'package:flutter/material.dart';

class BaseViewModel extends ChangeNotifier {
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
