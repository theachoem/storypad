import 'package:flutter/material.dart';

class SpDefaultScrollController extends StatefulWidget {
  const SpDefaultScrollController({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, ScrollController controller) builder;

  @override
  State<SpDefaultScrollController> createState() => _SpDefaultScrollControllerState();

  static ScrollController? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_SpDefaultScrollControllerState>()?.controller;
  }

  static ScrollController of(BuildContext context) {
    return context.findAncestorStateOfType<_SpDefaultScrollControllerState>()!.controller;
  }

  static Widget listenToOffet({
    required Widget Function(BuildContext context, double offset, Widget? child) builder,
  }) {
    return Builder(
      builder: (context) {
        final state = context.findAncestorStateOfType<_SpDefaultScrollControllerState>();
        return ValueListenableBuilder(
          valueListenable: state!.controllerOffetNotifier,
          builder: (context, offet, child) {
            return builder(context, offet, child);
          },
        );
      },
    );
  }
}

class _SpDefaultScrollControllerState extends State<SpDefaultScrollController> {
  final ScrollController controller = ScrollController();
  final ValueNotifier<double> controllerOffetNotifier = ValueNotifier(0.0);

  @override
  void initState() {
    controller.addListener(_listener);
    super.initState();
  }

  @override
  void dispose() {
    controller.removeListener(_listener);
    controller.dispose();
    controllerOffetNotifier.dispose();
    super.dispose();
  }

  void _listener() {
    controllerOffetNotifier.value = controller.offset;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, controller);
  }
}
