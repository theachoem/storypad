import 'package:flutter_test/flutter_test.dart';

import '../support/controller_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paragraphs, list items and tasks indent and outdent together', () {
    final controller = controllerFor('p\n\n- l\n- [ ] t');
    selectText(controller, 0, 0, 2, 1);

    controller.actions.indent();
    expect(controller.toMarkdown(), '<div data-indent="1">\n\np\n\n</div>\n\n    - l\n    - [ ] t');

    controller.actions.outdent();
    expect(controller.toMarkdown(), 'p\n\n- l\n- [ ] t');
  });

  test('a task indents freely, without a parent task above', () {
    final controller = controllerFor('paragraph\n\n- [ ] task');
    placeCaret(controller, 1, 0);

    controller.actions.indent();
    controller.actions.indent();
    expect(controller.toMarkdown(), 'paragraph\n\n        - [ ] task');
  });

  test('indent stops at 6 levels; canIndent/canOutdent reflect it', () {
    final controller = controllerFor('p');
    placeCaret(controller, 0, 0);
    expect(controller.actions.canOutdent, isFalse);

    for (var i = 0; i < 10; i++) {
      controller.actions.indent();
    }
    expect(controller.toMarkdown(), '<div data-indent="6">\n\np\n\n</div>');
    expect(controller.actions.canIndent, isFalse);
    expect(controller.actions.canOutdent, isTrue);
  });
}
