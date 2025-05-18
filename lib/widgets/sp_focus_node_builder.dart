import 'package:flutter/material.dart';

class SpFocusNodeBuilder extends StatefulWidget {
  const SpFocusNodeBuilder({
    super.key,
    required this.focusNode,
    required this.builder,
    this.child,
  });

  final Widget? child;
  final FocusNode focusNode;
  final Widget Function(BuildContext context, bool focused, Widget? child) builder;

  @override
  State<SpFocusNodeBuilder> createState() => SpFocusNodeBuilderState();
}

class SpFocusNodeBuilderState extends State<SpFocusNodeBuilder> {
  bool focused = false;

  @override
  void initState() {
    widget.focusNode.addListener(_listener);
    super.initState();
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    focused = widget.focusNode.hasFocus;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, focused, widget.child);
  }
}
