import 'package:flutter/material.dart';

import 'pages/home_page.dart';

void main() {
  runApp(const ExampleApp());
}

/// Manual-test app for storypad_editor, and the reference consumer: embeds and toolbars are defined app-side here,
/// exactly as StoryPad's app will define them.
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'storypad_editor example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const HomePage(),
    );
  }
}
