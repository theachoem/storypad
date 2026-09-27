import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storypad_editor/storypad_editor.dart';

import '../demo_content.dart';
import '../embeds/demo_embeds.dart';
import '../native_context_menu.dart';
import '../toolbar/editor_toolbar.dart';

/// A [MarkdownEditor] with its Markdown shown live beside it, plus import/export: paste Markdown, convert a story's
/// Quill Delta JSON (the migration path), or copy the current Markdown.
///
/// Loading new content creates a new controller (content is never swapped into an existing one); the editor is keyed
/// by its controller, and the old controller is disposed once the old editor is gone.
class MarkdownEditorPage extends StatefulWidget {
  const MarkdownEditorPage({super.key});

  @override
  State<MarkdownEditorPage> createState() => _MarkdownEditorPageState();
}

class _MarkdownEditorPageState extends State<MarkdownEditorPage> {
  late StoryEditorController _controller = StoryEditorController(embeds: demoEmbeds, markdown: demoMarkdown);
  late String _markdown = _controller.toMarkdown();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _load(StoryEditorController controller) {
    final old = _controller;
    setState(() {
      _controller = controller;
      _markdown = controller.toMarkdown();
    });
    // After this frame the old editor is unmounted, so its controller can go.
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  Future<void> _import() async {
    final markdown = await _promptForText(title: 'Import Markdown', hint: '# Title\n\nSome **Markdown**');
    if (markdown != null) _load(StoryEditorController(embeds: demoEmbeds, markdown: markdown));
  }

  Future<void> _convertFromQuill() async {
    final json = await _promptForText(title: 'Convert from Quill JSON', hint: '[{"insert": "Hello\\n"}]');
    if (json == null || !mounted) return;

    try {
      final decoded = jsonDecode(json);
      final ops = decoded is Map ? decoded['ops'] : decoded;
      if (ops is! List) throw const FormatException('Expected a list of ops, or {"ops": [...]}.');
      _load(StoryEditorController.fromQuill(ops, embeds: demoEmbeds));
    } on FormatException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not valid Quill JSON: ${error.message}')));
    }
  }

  Future<void> _export() async {
    await Clipboard.setData(ClipboardData(text: _controller.toMarkdown()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Markdown copied')));
    }
  }

  Future<String?> _promptForText({required String title, required String hint}) {
    return showDialog<String>(
      context: context,
      builder: (context) => _TextPrompt(title: title, hint: hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorController = _controller;
    final editor = EditorWithToolbar(
      key: ObjectKey(editorController),
      controller: editorController,
      editor: MarkdownEditor(
        controller: editorController,
        desktopContextMenu: showDesktopContextMenu,
        onChanged: (markdown) {
          // A change flushed from a replaced (or disposed) editor arrives after it's gone: ignore it.
          if (mounted && identical(editorController, _controller)) setState(() => _markdown = markdown);
        },
      ),
    );
    final pane = _MarkdownPane(markdown: _markdown);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown editor'),
        actions: [
          IconButton(tooltip: 'Import Markdown', icon: const Icon(Icons.file_open_outlined), onPressed: _import),
          IconButton(
            tooltip: 'Convert from Quill JSON',
            icon: const Icon(Icons.transform),
            onPressed: _convertFromQuill,
          ),
          IconButton(tooltip: 'Copy Markdown', icon: const Icon(Icons.copy), onPressed: _export),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 800
              ? Row(
                  children: [
                    Expanded(child: editor),
                    const VerticalDivider(width: 1),
                    Expanded(child: pane),
                  ],
                )
              : Column(
                  children: [
                    Expanded(flex: 2, child: editor),
                    const Divider(height: 1),
                    Expanded(child: pane),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MarkdownPane extends StatelessWidget {
  const _MarkdownPane({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          markdown,
          key: const ValueKey('markdown-pane'),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      ),
    );
  }
}

/// A dialog asking for some multi-line text.
class _TextPrompt extends StatefulWidget {
  const _TextPrompt({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: TextField(
          controller: _text,
          autofocus: true,
          minLines: 6,
          maxLines: 12,
          decoration: InputDecoration(hintText: widget.hint, border: const OutlineInputBorder()),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _text.text), child: const Text('Load')),
      ],
    );
  }
}
