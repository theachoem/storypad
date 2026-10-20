import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// transformSelectedText, e.g. Uppercase/Lowercase from a context menu.
void main() {
  test('transforms the selected text in place, keeping its formatting and the selection', () {
    final controller = controllerFor('say **hello** world');
    selectText(controller, 0, 4, 0, 13);

    controller.actions.transformSelectedText((text) => text.toUpperCase());

    expect(controller.toMarkdown(), 'say **HELLO** WORld');
    final selection = controller.selection.value!;
    expect((selection.base.nodePosition as TextNodePosition).offset, 4);
    expect((selection.extent.nodePosition as TextNodePosition).offset, 13);
  });

  test('across blocks, as one undo step', () {
    final controller = controllerFor('one\n\n- two\n\nthree');
    selectText(controller, 0, 1, 2, 2);

    controller.actions.transformSelectedText((text) => text.toUpperCase());
    expect(controller.toMarkdown(), 'oNE\n\n- TWO\n\nTHree');

    controller.actions.undo();
    expect(controller.toMarkdown(), 'one\n\n- two\n\nthree');
  });

  test('a transform that changes the length keeps the first character\'s formatting and shifts the selection', () {
    final controller = controllerFor('*abc* end');
    selectText(controller, 0, 0, 0, 3);

    controller.actions.transformSelectedText((text) => '${text.toUpperCase()}!');

    expect(controller.toMarkdown(), '*ABC!* end');
    expect((controller.selection.value!.extent.nodePosition as TextNodePosition).offset, 4);
  });

  test('nothing selected (a caret) does nothing', () {
    final controller = controllerFor('abc');
    placeCaret(controller, 0, 1);
    controller.actions.transformSelectedText((text) => text.toUpperCase());
    expect(controller.toMarkdown(), 'abc');
    expect(controller.actions.canUndo, isFalse);
  });
}
