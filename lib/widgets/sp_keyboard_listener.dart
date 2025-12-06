import 'package:flutter/cupertino.dart';

class SpKeyboardListener extends StatefulWidget {
  const SpKeyboardListener({
    super.key,
    required this.child,
    this.onKeyEvent,
  });

  final Widget child;
  final ValueChanged<KeyEvent>? onKeyEvent;

  @override
  State<SpKeyboardListener> createState() => _SpKeyboardListenerState();
}

class _SpKeyboardListenerState extends State<SpKeyboardListener> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      onKeyEvent: widget.onKeyEvent,
      autofocus: true,
      focusNode: _focusNode,
      child: widget.child,
    );
  }
}
