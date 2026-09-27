import 'package:flutter/material.dart';

import 'raw_editor_page.dart';

/// The example's pages, each exercising part of the package.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = <(String, String, WidgetBuilder)>[
      ('Raw editor', 'RawEditor over a controller with the demo embeds', (_) => const RawEditorPage()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('storypad_editor')),
      body: ListView(
        children: [
          for (final (title, subtitle, builder) in pages)
            ListTile(
              title: Text(title),
              subtitle: Text(subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: builder)),
            ),
        ],
      ),
    );
  }
}
