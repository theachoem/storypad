part of '../edit_story_view.dart';

class _FocusNodeBuilder extends StatefulWidget {
  const _FocusNodeBuilder({
    required this.focusNode,
    required this.builder,
    this.child,
  });

  final Widget? child;
  final FocusNode focusNode;
  final Widget Function(BuildContext context, bool focused, Widget? child) builder;

  @override
  State<_FocusNodeBuilder> createState() => _FocusNodeBuilderState();
}

class _FocusNodeBuilderState extends State<_FocusNodeBuilder> {
  bool focused = false;

  @override
  void initState() {
    widget.focusNode.addListener(_listener);
    super.initState();
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
