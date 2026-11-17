import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_markdown_body.dart';

void main() {
  group('withoutLooseLists', () {
    String fix(String markdown) => SpMarkdownBody.withoutLooseLists(markdown);

    test('tasks an empty line apart become two lists, the empty line kept as &nbsp;', () {
      expect(fix('- [ ] Line a\n\n- [ ] Line b'), '- [ ] Line a\n\n&nbsp;\n\n- [ ] Line b');
    });

    test('several blank (or whitespace-only) lines are one empty line', () {
      expect(fix('- [ ] a\n\n \n\t\n- [x] b'), '- [ ] a\n\n&nbsp;\n\n- [x] b');
    });

    test('bullets and numbered items too', () {
      expect(fix('- a\n\n- b'), '- a\n\n&nbsp;\n\n- b');
      expect(fix('1. a\n\n2. b'), '1. a\n\n&nbsp;\n\n2. b');
    });

    test('before a nested item the blank line is dropped (after &nbsp; it would read as code)', () {
      expect(fix('- [ ] a\n\n\t- [ ] b'), '- [ ] a\n\t- [ ] b');
    });

    test('left alone: tight lists, a list next to text, text, code', () {
      for (final markdown in [
        '- [ ] a\n- [ ] b',
        '- [ ] a\n\nText',
        'Text\n\n- [ ] a',
        'One\n\nTwo',
        '```\n- a\n\n- b\n```',
        '- [ ] a\n\n',
        // A ``` line inside a ```` block, and tilde fences, are still code.
        '````\n```\n- a\n\n- b\n````',
        '~~~\n- a\n\n- b\n~~~',
        // Closed only by a fence of the same kind, at least as long, with nothing after it.
        '````\n- a\n```\n\n- b\n````',
        '```\n- a\n``` x\n\n- b\n```',
        '~~~\n- a\n```\n\n- b\n~~~',
      ]) {
        expect(fix(markdown), markdown, reason: markdown);
      }
    });

    test('lists after a closed fence are fixed again', () {
      expect(fix('~~~~\ncode\n~~~~\n- [ ] a\n\n- [ ] b'), '~~~~\ncode\n~~~~\n- [ ] a\n\n&nbsp;\n\n- [ ] b');
      expect(fix('```\ncode\n`````\n- [ ] a\n\n- [ ] b'), '```\ncode\n`````\n- [ ] a\n\n&nbsp;\n\n- [ ] b');
    });
  });

  testWidgets('tasks an empty line apart both show a checkbox, not a bullet', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SpMarkdownBody(body: '- [ ] Line a\n\n- [x] Line b')),
      ),
    );

    expect(find.byIcon(SpIcons.checkboxBlank), findsOneWidget);
    expect(find.byIcon(SpIcons.checkbox), findsOneWidget);
    expect(find.text('•'), findsNothing);
  });
}
