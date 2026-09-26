import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

/// Manual-test app for storypad_editor. Pages are added phase by phase, as
/// the package gains the pieces they exercise.
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'storypad_editor example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const Scaffold(body: Center(child: Text('storypad_editor example'))),
    );
  }
}
