import 'package:flutter/material.dart';
import 'package:storypad_editor/storypad_editor.dart';

import '../embeds/demo_embeds.dart';

/// Several editors in one scroll view, like StoryPad's multi-page stories: each is shrink-wrapped (a sliver), has its
/// own controller, and a distinct `inputRole` so their keyboard connections don't collide.
class MultiEditorPage extends StatefulWidget {
  const MultiEditorPage({super.key});

  @override
  State<MultiEditorPage> createState() => _MultiEditorPageState();
}

class _MultiEditorPageState extends State<MultiEditorPage> {
  var _nextPage = 1;
  late final List<(int, StoryEditorController)> _pages = [_newPage()];

  (int, StoryEditorController) _newPage() {
    final number = _nextPage++;
    return (number, StoryEditorController(embeds: demoEmbeds, markdown: '## Page $number\n\nWrite something…'));
  }

  @override
  void dispose() {
    for (final (_, controller) in _pages) {
      controller.dispose();
    }
    super.dispose();
  }

  void _remove((int, StoryEditorController) page) {
    setState(() => _pages.remove(page));
    WidgetsBinding.instance.addPostFrameCallback((_) => page.$2.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiple editors'),
        actions: [
          IconButton(
            tooltip: 'Add page',
            icon: const Icon(Icons.note_add_outlined),
            onPressed: () => setState(() => _pages.add(_newPage())),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          for (final page in _pages) ...[
            SliverToBoxAdapter(
              child: ListTile(
                title: Text('Page ${page.$1}'),
                trailing: _pages.length > 1
                    ? IconButton(tooltip: 'Remove page', icon: const Icon(Icons.close), onPressed: () => _remove(page))
                    : null,
              ),
            ),
            RawEditor(
              key: ObjectKey(page.$2),
              controller: page.$2,
              inputRole: 'page-${page.$1}',
              layout: StoryEditorLayout.sliver,
            ),
          ],
        ],
      ),
    );
  }
}
