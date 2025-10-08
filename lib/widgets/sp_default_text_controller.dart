import 'package:flutter/material.dart';

class SpDefaultTextController extends StatefulWidget {
  const SpDefaultTextController({
    super.key,
    required this.builder,
    required this.initialText,
    this.withForm = false,
  });

  final String? initialText;
  final Widget Function(BuildContext context, TextEditingController controller) builder;
  final bool withForm;

  @override
  State<SpDefaultTextController> createState() => _SpDefaultTextControllerState();
}

class _SpDefaultTextControllerState extends State<SpDefaultTextController> {
  late final TextEditingController controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.withForm) {
      return Form(
        child: Builder(
          builder: (context) {
            return widget.builder(context, controller);
          },
        ),
      );
    }
    return widget.builder(context, controller);
  }
}
