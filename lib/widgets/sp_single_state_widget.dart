import 'package:flutter/material.dart';

class SpSingleStateWidget<T> extends StatefulWidget {
  const SpSingleStateWidget({
    super.key,
    required this.initialValue,
    required this.builder,
  });

  factory SpSingleStateWidget.listen({
    required T initialValue,
    required Widget Function(BuildContext context, T value, CmValueNotifier<T> notifier) builder,
  }) {
    return SpSingleStateWidget(
      initialValue: initialValue,
      builder: (context, notifier) {
        return ValueListenableBuilder(
          valueListenable: notifier,
          builder: (context, value, child) {
            return builder(context, value, notifier);
          },
        );
      },
    );
  }

  final T initialValue;
  final Widget Function(BuildContext context, CmValueNotifier<T> notifier) builder;

  @override
  State<SpSingleStateWidget<T>> createState() => _SpSingleStateWidgetState<T>();
}

class _SpSingleStateWidgetState<T> extends State<SpSingleStateWidget<T>> {
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
