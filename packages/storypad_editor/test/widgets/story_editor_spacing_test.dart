import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// StoryEditorSpacing: the space around each block, by kind, in one place.
void main() {
  const spacing = StoryEditorSpacing(
    text: BlockSpacing.all(1),
    heading: BlockSpacing.only(top: 12, bottom: 8),
    block: BlockSpacing.all(6),
    byType: {'sticker': BlockSpacing.zero},
  );

  /// The space between each two blocks: one's space below plus the next's above.
  List<double> gapsIn(StoryEditorController controller) {
    final spaces = [for (final node in controller.document) spacing.of(controller.document, node)];
    return [for (var i = 1; i < spaces.length; i++) spaces[i - 1].bottom + spaces[i].top];
  }

  test('between two blocks, the larger of their spaces -- collapsed, not added up; a per-type override first', () {
    final controller = controllerFor(
      'intro\n\n## Heading\n\nbody\n\n- item\n\n- [ ] task\n\n> quote\n\n---\n\n<sp-sticker name="cat"></sp-sticker>',
    );
    expect(gapsIn(controller), [
      12, // text (1) → heading (12 above)
      8, // heading (8 below) → text
      1,
      1,
      6, // text → quote (a block: 6)
      6, // quote → divider: 6, not 12
      6, // divider → sticker (none of its own)
    ]);
  });

  test('none at the document\'s edges: the first block gets no space above, the last none below', () {
    final controller = controllerFor('intro\n\n## Heading');
    expect(spacing.of(controller.document, nodeAt(controller, 0)).top, 0);
    expect(spacing.of(controller.document, nodeAt(controller, 1)).bottom, 0);

    // A lone heading (a page title) sits as evenly as a lone paragraph.
    final title = controllerFor('### Trip');
    expect(spacing.of(title.document, nodeAt(title, 0)), BlockSpacing.zero);

    final list = controllerFor('- a\n- b');
    expect(gapsIn(list), [1]);
    expect(spacing.of(list.document, nodeAt(list, 1)).bottom, 0);
  });

  test('a leading heading (a page title) gets no space above, only below', () {
    final controller = controllerFor('### Trip\n\nbody');
    expect(spacing.of(controller.document, nodeAt(controller, 0)), const BlockSpacing.only(bottom: 8));
  });

  test('equality, so an unchanged spacing never restyles the editor', () {
    expect(
      const StoryEditorSpacing(byType: {'media': BlockSpacing.zero}),
      StoryEditorSpacing(byType: {'media': BlockSpacing.only()}),
    );
    expect(spacing.copyWith(block: const BlockSpacing.all(6)), spacing);
    expect(spacing.copyWith(block: const BlockSpacing.all(7)), isNot(spacing));
  });

  testWidgets('the editor lays blocks out with it', (tester) async {
    Future<double> gapAboveHeading(StoryEditorSpacing spacing) async {
      final controller = controllerFor('body\n\n## Heading');
      await pumpStoryEditor(
        tester,
        controller,
        editor: RawEditor(controller: controller, spacing: spacing),
      );
      Rect rectOf(String text) => tester.getRect(
        find.byWidgetPredicate((widget) => widget is TextComponent && widget.text.toPlainText() == text),
      );
      return rectOf('Heading').top - rectOf('body').bottom;
    }

    final none = await gapAboveHeading(const StoryEditorSpacing(text: BlockSpacing.zero, heading: BlockSpacing.zero));
    final spaced = await gapAboveHeading(
      const StoryEditorSpacing(text: BlockSpacing.zero, heading: BlockSpacing.only(top: 12)),
    );
    expect(spaced - none, moreOrLessEquals(12));
  });

  testWidgets('the page space surrounds the document, and the first block starts right at it', (tester) async {
    final controller = controllerFor('# Title\n\nbody');
    await pumpStoryEditor(
      tester,
      controller,
      editor: RawEditor(
        controller: controller,
        spacing: const StoryEditorSpacing(page: EdgeInsets.fromLTRB(10, 20, 10, 0), heading: BlockSpacing.all(30)),
      ),
    );
    final title = tester.getRect(
      find.byWidgetPredicate((widget) => widget is TextComponent && widget.text.toPlainText() == 'Title'),
    );
    final editor = tester.getRect(find.byType(RawEditor));
    expect(title.left - editor.left, 10);
    expect(title.top - editor.top, 20);
  });
}
