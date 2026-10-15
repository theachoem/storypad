import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';

import '../support/controller_helpers.dart';

void main() {
  testWidgets('a burst of edits is reported once, after the debounce, with the final Markdown', (tester) async {
    final controller = controllerFor('Hello world');
    final reported = <String>[];
    await pumpStoryEditor(
      tester,
      controller,
      editor: MarkdownEditor(controller: controller, onChanged: reported.add),
    );

    selectText(controller, 0, 0, 0, 5);
    controller.actions.toggleBold();
    await tester.pump(const Duration(milliseconds: 100));
    controller.actions.toggleItalic();
    await tester.pump(const Duration(milliseconds: 100));
    expect(reported, isEmpty);

    await tester.pump(const Duration(milliseconds: 300));
    expect(reported, ['***Hello*** world']);
  });

  testWidgets('selection changes are not reported; each new Markdown value is, once', (tester) async {
    final controller = controllerFor('Hello');
    final reported = <String>[];
    await pumpStoryEditor(
      tester,
      controller,
      editor: MarkdownEditor(controller: controller, onChanged: reported.add, debounce: Duration.zero),
    );

    placeCaret(controller, 0, 2);
    await tester.pump();
    expect(reported, isEmpty);

    selectNode(controller, 0);
    controller.actions.toggleBold();
    await tester.pump();
    controller.actions.undo();
    await tester.pump();
    expect(reported, ['**Hello**', 'Hello']);

    // Edits made together (in one synchronous block) are reported as their net change: here, none.
    controller.actions.redo();
    controller.actions.undo();
    await tester.pump();
    expect(reported, ['**Hello**', 'Hello']);
  });

  testWidgets('a pending change is flushed when the editor is disposed', (tester) async {
    final controller = controllerFor('Hello');
    final reported = <String>[];
    await pumpStoryEditor(
      tester,
      controller,
      editor: MarkdownEditor(controller: controller, onChanged: reported.add),
    );

    selectNode(controller, 0);
    controller.actions.toggleBold();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(reported, ['**Hello**']);
  });

  testWidgets('with no debounce, a change made right before disposal is still reported', (tester) async {
    final controller = controllerFor('Hello');
    final reported = <String>[];
    await pumpStoryEditor(
      tester,
      controller,
      editor: MarkdownEditor(controller: controller, onChanged: reported.add, debounce: Duration.zero),
    );

    selectNode(controller, 0);
    controller.actions.toggleBold();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(reported, ['**Hello**']);
  });

  testWidgets('a pending change flushed on a controller swap goes to the old callback, safely for setState', (
    tester,
  ) async {
    final first = controllerFor('one');
    final second = controllerFor('two');
    final key = GlobalKey<_HostState>();
    await pumpStoryEditor(
      tester,
      first,
      editor: _Host(key: key, controller: first),
    );

    selectNode(first, 0);
    first.actions.toggleBold();
    key.currentState!.swap(second);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(key.currentState!.reported, ['**one**']);
  });
}

class _Host extends StatefulWidget {
  const _Host({super.key, required this.controller});

  final StoryEditorController controller;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late StoryEditorController controller = widget.controller;
  final reported = <String>[];

  void swap(StoryEditorController next) => setState(() => controller = next);

  @override
  Widget build(BuildContext context) {
    return MarkdownEditor(
      controller: controller,
      // Calls setState: must not happen while the tree is locked.
      onChanged: (markdown) => setState(() => reported.add(markdown)),
    );
  }
}
