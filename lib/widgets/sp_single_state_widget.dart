import 'package:flutter/material.dart';

class CmSingleStateWidget<T> extends StatefulWidget {
  const CmSingleStateWidget({
    super.key,
    required this.initialValue,
    required this.builder,
  });

  final T initialValue;
  final Widget Function(BuildContext context, CmValueNotifier<T> notifier) builder;

  @override
  State<CmSingleStateWidget<T>> createState() => _CmSingleStateWidgetState<T>();
}

class _CmSingleStateWidgetState<T> extends State<CmSingleStateWidget<T>> {
  late final CmValueNotifier<T> stateNotifier;

  @override
  void initState() {
    stateNotifier = CmValueNotifier<T>(widget.initialValue);
    super.initState();
  }

  @override
  void dispose() {
    stateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      stateNotifier,
    );
  }
}

class CmValueNotifier<T> extends ValueNotifier<T> {
  CmValueNotifier(super.value);

  bool _disposed = false;

  bool get disposed => _disposed;

  @override
  void notifyListeners() {
    if (disposed) return;
    super.notifyListeners();
  }

  @override
  set value(T newValue) {
    if (disposed) return;
    super.value = newValue;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
