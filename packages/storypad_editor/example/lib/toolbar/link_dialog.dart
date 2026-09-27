import 'package:flutter/material.dart';
import 'package:storypad_editor/storypad_editor.dart';

/// Asks for a URL and links the selection to it, holding the selection while the dialog has focus.
Future<void> showLinkDialog(BuildContext context, StoryEditorController controller) {
  return controller.keepSelectionWhile(() async {
    final url = await showDialog<String>(
      context: context,
      builder: (context) => _LinkDialog(initialUrl: controller.actions.linkUrl),
    );
    if (url == null) return;
    if (url.trim().isEmpty) {
      controller.actions.removeLink();
    } else {
      controller.actions.setLink(url.trim());
    }
  });
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({this.initialUrl});

  final String? initialUrl;

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late final _url = TextEditingController(text: widget.initialUrl);

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialUrl != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit link' : 'Add link'),
      content: TextField(
        controller: _url,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'https://example.com'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _url.text), child: Text(isEditing ? 'Save' : 'Add')),
      ],
    );
  }
}
