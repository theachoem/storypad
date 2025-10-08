import 'dart:async';

import 'package:flutter/material.dart';

class SpCountdownTimer extends StatefulWidget {
  const SpCountdownTimer({
    super.key,
    required this.endAt,
    required this.builder,
  });

  final DateTime? endAt;
  final Widget Function(
    BuildContext context,
    int hour,
    int minute,
    int second,
  )
  builder;

  @override
  State<SpCountdownTimer> createState() => _SpCountdownTimerState();
}

class _SpCountdownTimerState extends State<SpCountdownTimer> {
  Timer? timer;
  bool get ended => widget.endAt != null ? DateTime.now().isAfter(widget.endAt!) : true;

  @override
  void initState() {
    resetTimer();
    super.initState();
  }

  void resetTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (ended) {
        timer?.cancel();
        timer = null;
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SpCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.endAt != widget.endAt) {
      resetTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.endAt != null ? widget.endAt!.difference(DateTime.now()) : const Duration();

    return widget.builder(
      context,
      duration.inHours % 60,
      duration.inMinutes % 60,
      duration.inSeconds % 60,
    );
  }
}
