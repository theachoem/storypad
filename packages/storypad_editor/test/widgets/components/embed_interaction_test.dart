import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

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

  testWidgets('an embed can put the caret before or after itself, focusing the editor', (tester) async {
    final controller = controllerFor('<img src="a.png">\n\nhello');
    await StoryEditorTester.pump(tester, controller);
    final embed = StoryEmbedContext<GalleryValue>(
      nodeId: nodeAt(controller, 0).id,
      value: const GalleryValue(['a.png']),
      isSelected: false,
      controller: controller,
      embed: const GalleryEmbedCodec(),
    );

    embed.placeCaret(before: true);
    await tester.pumpAndSettle();
    expect(controller.focusNode.hasFocus, isTrue);
    expect(controller.selection.value!.extent.nodePosition, const UpstreamDownstreamNodePosition.upstream());

    embed.placeCaret(before: false);
    expect(controller.selection.value!.extent.nodePosition, const UpstreamDownstreamNodePosition.downstream());
  });

  testWidgets('the default unknown placeholder can remove itself', (tester) async {
    final controller = controllerFor('a\n\n<sp-future></sp-future>');
    await StoryEditorTester.pump(tester, controller);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();

    expect(controller.toMarkdown(), 'a');
  });
}
