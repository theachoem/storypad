import 'package:flutter/material.dart';
import 'package:storypad_editor/storypad_editor.dart';

import '../demo_content.dart';
import '../embeds/demo_embeds.dart';
import '../toolbar/editor_toolbar.dart';

/// The bare editing surface: a [RawEditor] over a controller holding the demo story, plus app-bar actions that go
/// through the controller (insert embeds, read the Markdown back).
class RawEditorPage extends StatefulWidget {
  const RawEditorPage({super.key});

  @override
  State<RawEditorPage> createState() => _RawEditorPageState();
}

class _RawEditorPageState extends State<RawEditorPage> {
  late final _controller = StoryEditorController(embeds: demoEmbeds, markdown: demoMarkdown);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insert(_Insertable item) {
    switch (item) {
      case _Insertable.photo:
        _controller.insertEmbed(const MediaEmbed(), const MediaValue(['images/new.jpg']));
      case _Insertable.album:
        _controller.insertEmbed(const MediaEmbed(), const MediaValue(['images/a.jpg', 'videos/b.mp4']));
      case _Insertable.audio:
        _controller.insertEmbed(const AudioEmbed(), 'audio/new.m4a');
      case _Insertable.date:
        _controller.insertEmbed(const DateEmbed(), DateTime.now());
    }
  }

  Future<void> _showMarkdown() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Markdown'),
        content: SingleChildScrollView(child: SelectableText(_controller.toMarkdown())),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raw editor'),
        actions: [
          // Inserting takes focus away from the editor; the controller remembers where the caret was.
          PopupMenuButton<_Insertable>(
            tooltip: 'Insert',
            icon: const Icon(Icons.add),
            onSelected: _insert,
            itemBuilder: (context) => [
              for (final item in _Insertable.values) PopupMenuItem(value: item, child: Text(item.label)),
            ],
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _controller.readOnlyListenable,
            builder: (context, readOnly, _) => IconButton(
              tooltip: readOnly ? 'Edit' : 'Read only',
              icon: Icon(readOnly ? Icons.edit_outlined : Icons.visibility_outlined),
              onPressed: () => _controller.readOnly = !readOnly,
            ),
          ),
          IconButton(tooltip: 'Show Markdown', icon: const Icon(Icons.code), onPressed: _showMarkdown),
        ],
      ),
      body: SafeArea(
        child: EditorWithToolbar(
          controller: _controller,
          editor: RawEditor(controller: _controller),
        ),
      ),
    );
  }
}

enum _Insertable {
  photo('Photo'),
  album('Album'),
  audio('Voice note'),
  date('Date');

  const _Insertable(this.label);

  final String label;
}
