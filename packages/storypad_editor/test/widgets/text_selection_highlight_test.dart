import 'dart:ui' show BoxHeightStyle;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/src/widgets/text_selection_highlight.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// A text block's selection highlight, as native text paints it: each line exactly over its own height, the lines in
/// one fill -- not super_editor's, which grows each line 2px up and down, so a wrapped paragraph's lines overlap and the
/// see-through color darkens there.
void main() {
  const selectionColor = Color(0x663399FF);
  const transparent = Color(0x00000000);
  final longText = List.filled(12, 'Many banks block iframes to prevent clickjacking.').join(' ');

  Future<void> pump(WidgetTester tester, StoryEditorController controller) {
    return pumpStoryEditor(
      tester,
      controller,
      size: const Size(320, 1200),
      editor: RawEditor(controller: controller, selectionColor: selectionColor),
    );
  }

  RenderParagraph paragraphIn(WidgetTester tester, Finder block) => tester.renderObject<RenderParagraph>(
    find.descendant(of: block, matching: find.byWidgetPredicate((widget) => widget is RichText)).first,
  );

  testWidgets('a wrapped paragraph: lines that meet, not overlap, in one fill; super_editor\'s own is transparent', (
    tester,
  ) async {
    final controller = controllerFor('$longText\n\nafter');
    await pump(tester, controller);
    selectNode(controller, 0);
    await tester.pump();

    final block = find.byType(TextSelectionHighlight).first;
    final highlight = tester.renderObject<RenderTextSelectionHighlight>(block);
    final paragraph = paragraphIn(tester, block);
    final origin = paragraph.localToGlobal(Offset.zero, ancestor: highlight);
    final lines = [
      for (final box in paragraph.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: longText.length),
        boxHeightStyle: BoxHeightStyle.max,
      ))
        box.toRect().shift(origin),
    ];
    expect(lines.length, greaterThan(2), reason: 'the paragraph wraps');

    expect(
      highlight,
      paints..path(
        color: selectionColor,
        includes: [for (final line in lines) line.center, Offset(lines[0].center.dx, lines[0].bottom)],
        // super_editor's reached 2px past the text.
        excludes: [
          Offset(lines.first.center.dx, lines.first.top - 1),
          Offset(lines.last.center.dx, lines.last.bottom + 1),
        ],
      ),
    );
    expect(highlight, paintsExactlyCountTimes(#drawPath, 1));

    final textComponent = tester.renderObject(find.descendant(of: block, matching: find.byType(TextComponent)));
    expect(textComponent, paints..rrect(color: transparent));
    expect(textComponent, isNot(paints..rrect(color: selectionColor)));
  });

  testWidgets('an empty line within a selection, a list item and a task: highlighted at their text', (tester) async {
    final controller = controllerFor('first\n\n&nbsp;\n\n- item\n\n- [ ] task');
    await pump(tester, controller);
    selectText(controller, 0, 0, 3, 4);
    await tester.pump();

    final blocks = find.byType(TextSelectionHighlight);
    final empty = tester.renderObject<RenderTextSelectionHighlight>(blocks.at(1));
    expect(empty.highlightWhenEmpty, isTrue);
    expect(
      empty,
      paints..path(
        color: selectionColor,
        // super_editor's 20px at the line's start.
        includes: [Offset(10, paragraphIn(tester, blocks.at(1)).size.height / 2)],
        excludes: [Offset(24, paragraphIn(tester, blocks.at(1)).size.height / 2)],
      ),
    );

    for (final index in [2, 3]) {
      final highlight = tester.renderObject<RenderTextSelectionHighlight>(blocks.at(index));
      final paragraph = paragraphIn(
        tester,
        find.descendant(of: blocks.at(index), matching: find.byType(TextComponent)),
      );
      final text = paragraph.localToGlobal(Offset.zero, ancestor: highlight) & paragraph.size;
      expect(
        highlight,
        paints..path(
          color: selectionColor,
          includes: [Offset(text.left + 4, text.center.dy)],
          excludes: [Offset(text.left - 4, text.center.dy)],
        ),
        reason: 'block $index: at its text, past its marker',
      );
    }
  });
}
