import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/testing.dart';

import '../../support/controller_helpers.dart';
import '../../support/test_embeds.dart';

void main() {
  testWidgets('an embed gets the first tap even while the editor is unfocused (the reorder overlay lets it through)', (
    tester,
  ) async {
    final controller = controllerFor('<sp-sticker name="cat"></sp-sticker>');
    await StoryEditorTester.pump(tester, controller);
    expect(controller.focusNode.hasFocus, isFalse);

    await tester.tap(find.text('sticker cat'));
    await tester.pumpAndSettle();

    expect(controller.embedsOf(const StickerEmbedCodec()).single.$2, 'cat!');
    expect(find.text('sticker cat!'), findsOneWidget);
  }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

  testWidgets('rapid taps each apply to the live value, not a stale snapshot', (tester) async {
    final controller = controllerFor('<sp-sticker name="cat"></sp-sticker>');
    await StoryEditorTester.pump(tester, controller);

    final sticker = find.byKey(ValueKey('sticker-${nodeAt(controller, 0).id}'));
    await tester.tap(sticker);
    await tester.tap(sticker, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(controller.embedsOf(const StickerEmbedCodec()).single.$2, 'cat!!');
  });

  testWidgets('the default unknown placeholder can remove itself', (tester) async {
    final controller = controllerFor('a\n\n<sp-future></sp-future>');
    await StoryEditorTester.pump(tester, controller);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();

    expect(controller.toMarkdown(), 'a');
  });
}
