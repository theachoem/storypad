import 'dart:async';
import 'package:flutter/material.dart';

// Make sure to remove this widget from widget tree when no using, otherwise it will always run.
class SpRefreshStateInDuration extends StatefulWidget {
  const SpRefreshStateInDuration({
    super.key,
    required this.duration,
    required this.builder,
  });

  final Duration duration;
  final Widget Function(BuildContext context) builder;

  @override
  State<SpRefreshStateInDuration> createState() => _SpRefreshStateInDurationState();
}

class _SpRefreshStateInDurationState extends State<SpRefreshStateInDuration> {
  Timer? timer;

  @override
  void initState() {
    resetTimer();
    super.initState();
  }

  void resetTimer() {
    timer = Timer.periodic(widget.duration, (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
