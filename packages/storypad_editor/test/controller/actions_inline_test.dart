import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('toggling on a selection', () {
    final controller = controllerFor('Hello world');
    selectText(controller, 0, 0, 0, 5);

    controller.actions.toggleBold();
    expect(controller.actions.isBold, isTrue);
    expect(controller.toMarkdown(), '**Hello** world');

    controller.actions.toggleBold();
    expect(controller.actions.isBold, isFalse);
    expect(controller.toMarkdown(), 'Hello world');
  });

  test('every inline toggle', () {
    final controller = controllerFor('abcde');
    for (final (index, toggle) in [
      controller.actions.toggleItalic,
      controller.actions.toggleUnderline,
      controller.actions.toggleStrikethrough,
      controller.actions.toggleInlineCode,
      controller.actions.toggleSuperscript,
    ].indexed) {
      selectText(controller, 0, index, 0, index + 1);
      toggle();
    }
    expect(controller.toMarkdown(), '*a*<u>b</u>~~c~~`d`<sup>e</sup>');
  });

  test('with a caret, a toggle applies to the text typed next', () {
    final controller = controllerFor('Hello');
    placeCaret(controller, 0, 5);

    controller.actions.toggleBold();
    expect(controller.actions.isBold, isTrue);
    expect(controller.composer.preferences.currentAttributions, contains(boldAttribution));
    expect(controller.toMarkdown(), 'Hello', reason: 'nothing typed yet');
  });

  test('superscript and subscript replace each other instead of conflicting', () {
    final controller = controllerFor('x2');
    selectText(controller, 0, 1, 0, 2);

    controller.actions.toggleSuperscript();
    controller.actions.toggleSubscript();

    expect(controller.actions.isSubscript, isTrue);
    expect(controller.actions.isSuperscript, isFalse);
    expect(controller.toMarkdown(), 'x<sub>2</sub>');

    // Each toggle is one undo step.
    controller.actions.undo();
    expect(controller.toMarkdown(), 'x<sup>2</sup>');
    controller.actions.undo();
    expect(controller.toMarkdown(), 'x2');
  });

  test('replacing a color is one undo step', () {
    final controller = controllerFor('Hello');
    selectNode(controller, 0);

    controller.actions.setTextColor(const Color(0xFFFF0000));
    controller.actions.setTextColor(const Color(0xFF0000FF));
    controller.actions.undo();
    expect(controller.toMarkdown(), '<span style="color:#ff0000ff">Hello</span>');
  });

  test('colors replace the previous color; null removes', () {
    final controller = controllerFor('Hello');
    selectNode(controller, 0);

    controller.actions.setTextColor(const Color(0xFFFF0000));
    controller.actions.setTextColor(const Color(0xFF0000FF));
    expect(controller.actions.textColor, const Color(0xFF0000FF));

    controller.actions.setBackgroundColor(const Color(0xFFFFFF00));
    expect(controller.actions.backgroundColor, const Color(0xFFFFFF00));

    controller.actions.setTextColor(null);
    expect(controller.actions.textColor, isNull);
    expect(controller.toMarkdown(), '<mark style="background-color:#ffff00ff">Hello</mark>');
  });

  test('links: set, read back, replace, and remove -- across blocks too', () {
    final controller = controllerFor('one\n\ntwo');
    selectText(controller, 0, 0, 1, 3);

    controller.actions.setLink('https://a.com');
    expect(controller.actions.linkUrl, 'https://a.com');

    controller.actions.setLink('https://b.com');
    expect(controller.toMarkdown(), '[one](https://b.com)\n\n[two](https://b.com)');

    controller.actions.removeLink();
    expect(controller.actions.linkUrl, isNull);
    expect(controller.toMarkdown(), 'one\n\ntwo');
  });

  test('setLink does nothing for a caret', () {
    final controller = controllerFor('Hello');
    placeCaret(controller, 0, 1);
    controller.actions.setLink('https://a.com');
    expect(controller.toMarkdown(), 'Hello');
  });

  test('clearFormatting removes all inline formatting', () {
    final controller = controllerFor('**<u>Hello</u>** [x](https://a.com)');
    selectNode(controller, 0);

    controller.actions.clearFormatting();
    expect(controller.toMarkdown(), 'Hello x');
  });
}
