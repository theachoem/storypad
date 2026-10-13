import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/rich_editor/sp_editor.dart';
import 'package:storypad/core/rich_editor/sp_editor_controller.dart';
import 'package:storypad/core/rich_editor/sp_editor_toolbar.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad_editor/super_editor.dart';

/// A page and its toolbar, as the story page hosts them, in the page's scroll view.
void main() {
  Future<({SpEditorController controller, FocusNode focusNode, List<int> changes})> pumpPage(
    WidgetTester tester, {
    String markdown = '',
    bool readOnly = false,
    bool keepsChanges = true,
    VoidCallback? onGoToEdit,
  }) async {
    final controller = SpEditorController(
      markdown: markdown,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: readOnly,
    );
    final focusNode = FocusNode();
    final changes = <int>[];
    addTearDown(() {
      focusNode.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SpEditor(
                  controller: controller,
                  focusNode: focusNode,
                  readOnly: readOnly,
                  storyContent: StoryContentDbModel.create(),
                  layoutType: null,
                  onChanged: keepsChanges ? () => changes.add(changes.length) : null,
                  onGoToEdit: onGoToEdit,
                ),
              ],
            ),
          ),
          bottomNavigationBar: SpEditorToolbar(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (controller: controller, focusNode: focusNode, changes: changes);
  }

  testWidgets('focusing the page focuses the editor, with the caret at the end', (tester) async {
    final page = await pumpPage(
      tester,
      markdown: 'Hello',
    );

    page.focusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(page.controller.editor.focusNode.hasFocus, isTrue);
    expect(page.focusNode.hasFocus, isTrue, reason: 'the page and its toolbar track this node');
    expect(page.controller.selection, const TextSelection.collapsed(offset: 5));
  });

  testWidgets('edits are reported right away (so Done never misses the last keystrokes)', (tester) async {
    final page = await pumpPage(
      tester,
      markdown: 'Hello',
    );
    page.focusNode.requestFocus();
    await tester.pumpAndSettle();

    page.controller.editor.editor.execute([
      InsertTextRequest(
        documentPosition: page.controller.editor.selection.value!.extent,
        textToInsert: ' world',
        attributions: {},
      ),
    ]);
    // Reported in a microtask right after the edit, before any later tap (e.g. Done) is handled.
    await Future<void>.value();

    expect(page.changes, isNotEmpty);
    expect(page.controller.serialize(), 'Hello world');
  });

  testWidgets('the toolbar formats the selection', (tester) async {
    final page = await pumpPage(
      tester,
      markdown: 'Hello',
    );
    page.controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();

    await tester.tap(find.byIcon(SpIcons.formatBold));
    await tester.pumpAndSettle();

    expect(page.controller.serialize(), '**Hello**');
  });

  testWidgets('the heading buttons set, switch and clear the line\'s heading level', (tester) async {
    final page = await pumpPage(tester, markdown: 'Hello');
    page.controller.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump();

    Future<void> tap(IconData icon) async {
      await tester.ensureVisible(find.byIcon(icon));
      await tester.tap(find.byIcon(icon));
      await tester.pumpAndSettle();
    }

    await tap(SpIcons.heading1);
    expect(page.controller.serialize(), '# Hello');
    await tap(SpIcons.heading2);
    expect(page.controller.serialize(), '## Hello');
    await tap(SpIcons.heading2);
    expect(page.controller.serialize(), 'Hello');
  });

  testWidgets('a view whose changes aren\'t kept has no live checkboxes', (tester) async {
    final page = await pumpPage(
      tester,
      markdown: '- [ ] task',
      readOnly: true,
      keepsChanges: false,
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(page.controller.editor.toMarkdown(), '- [ ] task');
  });

  testWidgets('read-only with changes kept: a checkbox toggle is reported', (tester) async {
    final page = await pumpPage(
      tester,
      markdown: '- [ ] task',
      readOnly: true,
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(page.changes, isNotEmpty);
    expect(page.controller.serialize(), '- [x] task');
  });

  testWidgets('read-only, the right-click menu offers Edit; editing, Uppercase and Lowercase', (tester) async {
    var edits = 0;
    final page = await pumpPage(
      tester,
      markdown: 'Hello',
      readOnly: true,
      onGoToEdit: () => edits++,
    );

    await tester.tapAt(tester.getTopLeft(find.byType(TextComponent)) + const Offset(8, 8), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('Uppercase'), findsNothing);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(edits, 1);
    expect(page.controller.editor.readOnly, isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('editing: Uppercase changes the selected text', (tester) async {
    final page = await pumpPage(
      tester,
      markdown: 'Hello',
    );
    page.controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();

    await tester.tapAt(tester.getTopLeft(find.byType(TextComponent)) + const Offset(8, 8), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uppercase'));
    await tester.pumpAndSettle();
    expect(page.controller.serialize(), 'HELLO');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('content changed before the page is built is reported once it is (a story started from a photo)', (
    tester,
  ) async {
    final controller = SpEditorController(
      markdown: '',
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: false,
    );
    final focusNode = FocusNode();
    addTearDown(() {
      focusNode.dispose();
      controller.dispose();
    });
    // As EditStoryViewModel.init does for an initial asset (a photo; text here, since rendering a photo needs the app's
    // providers), before the page is built.
    controller.selection = const TextSelection.collapsed(offset: 0);
    controller.editor.editor.execute([const InsertPlainTextAtCaretRequest('Hello')]);

    final changes = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpEditor(
              controller: controller,
              focusNode: focusNode,
              readOnly: false,
              storyContent: StoryContentDbModel.create(),
              layoutType: null,
              onChanged: () => changes.add(changes.length),
              onGoToEdit: null,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(changes, hasLength(1));
    expect(controller.serialize(), 'Hello');
  });

  testWidgets('with text selected, undo/redo become move up/down and move the selected lines', (tester) async {
    final page = await pumpPage(
      tester,
      markdown: 'one\n\ntwo\n\nthree',
    );
    expect(find.byIcon(SpIcons.undo), findsOneWidget);

    // Select "two" (offsets: "one\n" is 4).
    page.controller.selection = const TextSelection(baseOffset: 4, extentOffset: 7);
    await tester.pump();
    expect(find.byIcon(SpIcons.undo), findsNothing);

    await tester.tap(find.byIcon(SpIcons.moveUp));
    await tester.pumpAndSettle();
    expect(page.controller.serialize(), 'two\n\none\n\nthree');
  });

  testWidgets('moving lines keeps each line its own style, the first line included', (tester) async {
    final page = await pumpPage(tester, markdown: '### Trip\n\nbody\n\n# Big');

    double sizeOf(String text) {
      final root = tester.widget<RichText>(find.text(text, findRichText: true)).text;
      double? found;
      void visit(InlineSpan span, double? inherited) {
        final size = span.style?.fontSize ?? inherited;
        if (span is TextSpan && span.text == text) found = size;
        if (span is TextSpan) span.children?.forEach((child) => visit(child, size));
      }

      visit(root, null);
      return found!;
    }

    final sizes = {
      for (final text in ['Trip', 'body', 'Big']) text: sizeOf(text),
    };
    expect(sizes['Big'], greaterThan(sizes['Trip']!));
    expect(sizes['Trip'], greaterThan(sizes['body']!));

    // "body" to the top, then "Big" to the top: each line keeps its style wherever it goes.
    page.controller.selection = const TextSelection.collapsed(offset: 6);
    page.controller.editor.actions.moveSelectedBlocks(up: true);
    await tester.pumpAndSettle();
    page.controller.selection = const TextSelection.collapsed(offset: 11);
    page.controller.editor.actions.moveSelectedBlocks(up: true);
    page.controller.editor.actions.moveSelectedBlocks(up: true);
    await tester.pumpAndSettle();

    expect(page.controller.serialize(), '# Big\n\nbody\n\n### Trip');
    for (final MapEntry(key: text, value: size) in sizes.entries) {
      expect(sizeOf(text), size, reason: text);
    }
  });
}
