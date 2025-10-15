import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef SpTwoValueWidgetBuilder<T, P> = Widget Function(BuildContext context, T value1, P value2, Widget? child);

class SpTwoValueListenableBuilder<T, P> extends StatefulWidget {
  const SpTwoValueListenableBuilder({
    super.key,
    required this.valueListenable1,
    required this.valueListenable2,
    required this.builder,
    this.child,
  });

  final ValueListenable<T> valueListenable1;
  final ValueListenable<P> valueListenable2;
  final SpTwoValueWidgetBuilder<T, P> builder;
  final Widget? child;

  @override
  State<StatefulWidget> createState() => _SpTwoValueListenableBuilderState<T, P>();
}

class _SpTwoValueListenableBuilderState<T, P> extends State<SpTwoValueListenableBuilder<T, P>> {
  late T value1;
  late P value2;

  @override
  void initState() {
    super.initState();
    value1 = widget.valueListenable1.value;
    value2 = widget.valueListenable2.value;
    widget.valueListenable1.addListener(_value1Changed);
    widget.valueListenable2.addListener(_value2Changed);
  }

  @override
  void didUpdateWidget(SpTwoValueListenableBuilder<T, P> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueListenable1 != widget.valueListenable1) {
      oldWidget.valueListenable1.removeListener(_value1Changed);
      value1 = widget.valueListenable1.value;
      widget.valueListenable1.addListener(_value1Changed);
    }
    if (oldWidget.valueListenable2 != widget.valueListenable2) {
      oldWidget.valueListenable2.removeListener(_value2Changed);
      value2 = widget.valueListenable2.value;
      widget.valueListenable2.addListener(_value2Changed);
    }
  }

  @override
  void dispose() {
    widget.valueListenable1.removeListener(_value1Changed);
    widget.valueListenable2.removeListener(_value2Changed);
    super.dispose();
  }

  void _value1Changed() {
    setState(() {
      value1 = widget.valueListenable1.value;
    });
  }

  void _value2Changed() {
    setState(() {
      value2 = widget.valueListenable2.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value1, value2, widget.child);
  }
}
