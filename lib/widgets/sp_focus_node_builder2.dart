import 'package:flutter/material.dart';

class SpFocusNodeBuilder2 extends StatefulWidget {
  const SpFocusNodeBuilder2({
    super.key,
    required this.focusNode1,
    required this.focusNode2,
    required this.builder,
    this.onFucusChangeAfterInitialized,
    this.child,
  });

  final Widget? child;
  final FocusNode focusNode1;
  final FocusNode focusNode2;
  final void Function(bool node1Focused, bool node2Focused)? onFucusChangeAfterInitialized;
  final Widget Function(BuildContext context, bool node1Focused, bool node2Focused, Widget? child) builder;

  @override
  State<SpFocusNodeBuilder2> createState() => SpFocusNodeBuilder2State();
}

class SpFocusNodeBuilder2State extends State<SpFocusNodeBuilder2> {
  bool node1Focused = false;
  bool node2Focused = false;

  bool _initialized = false;

  @override
  void initState() {
    widget.focusNode1.addListener(_listener);
    widget.focusNode2.addListener(_listener);
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialized = true;
    });
  }

  @override
  void dispose() {
    widget.focusNode1.removeListener(_listener);
    widget.focusNode2.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    node1Focused = widget.focusNode1.hasFocus;
    node2Focused = widget.focusNode2.hasFocus;
    if (mounted) setState(() {});

    if (_initialized) {
      widget.onFucusChangeAfterInitialized!(node1Focused, node2Focused);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      node1Focused,
      node2Focused,
      widget.child,
    );
  }
}
