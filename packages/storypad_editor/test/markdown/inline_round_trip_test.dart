import 'dart:math';

import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/src/markdown/inline_markdown_reader.dart';
import 'package:storypad_editor/src/markdown/inline_markdown_writer.dart';
import 'package:super_editor/super_editor.dart';

/// Randomized round-trip: any text with any combination of supported attributions must read back exactly, and
/// writing is a fixed point. Seeded, so failures reproduce.
void main() {
  const alphabet = 'ab c(). ,!?-_*~`#[]<>&\\\'"|:1\n\t';
  final attributions = <Attribution>[
    boldAttribution,
    italicsAttribution,
    strikethroughAttribution,
    underlineAttribution,
    codeAttribution,
    const LinkAttribution('https://example.com/a_b'),
    const LinkAttribution('a b)'),
    const ColorAttribution(Color(0xFF336699)),
    const BackgroundColorAttribution(Color(0x80FFCC00)),
    const ScriptAttribution.superscript(),
  ];

  AttributedText randomText(Random random) {
    final length = 1 + random.nextInt(14);
    final text = AttributedText(List.generate(length, (_) => alphabet[random.nextInt(alphabet.length)]).join());
    for (var i = random.nextInt(4); i > 0; i--) {
      final start = random.nextInt(length);
      final end = start + random.nextInt(length - start);
      final attribution = attributions[random.nextInt(attributions.length)];
      // Mirror the editor: conflicting attributions (two links, two colors) can't overlap.
      final conflicts = text.getAttributionSpansInRange(
        attributionFilter: (candidate) => candidate.id == attribution.id && candidate != attribution,
        range: SpanRange(start, end),
      );
      if (conflicts.isEmpty) text.addAttribution(attribution, SpanRange(start, end));
    }
    return text;
  }

  for (var seed = 0; seed < 2000; seed++) {
    test('seed $seed', () {
      final text = randomText(Random(seed));
      final markdown = const InlineMarkdownWriter().write(text);
      final parsed = const InlineMarkdownReader().read(markdown);

      expect(markdown, isNot(contains('\n')), reason: 'one line');
      expect(inlineTextEquals(parsed, text), isTrue, reason: 'markdown: $markdown\nparsed: $parsed\noriginal: $text');
      expect(const InlineMarkdownWriter().write(parsed), markdown, reason: 'fixed point');
    });
  }
}
