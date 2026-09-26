import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';

import '../support/controller_helpers.dart';
import '../support/test_embeds.dart';

void main() {
  testWidgets('text and embeds render; each embed through its own build', (tester) async {
    final controller = controllerFor('Hello\n\n<sp-sticker name="cat"></sp-sticker>\n\n![](a.jpg)');
    await pumpStoryEditor(tester, controller);

    expect(find.text('Hello', findRichText: true), findsOneWidget);
    expect(find.text('sticker cat'), findsOneWidget);
    expect(find.text('gallery a.jpg'), findsOneWidget);
  });

  testWidgets('unknown content gets the default placeholder', (tester) async {
    final controller = controllerFor('<sp-future x="1"></sp-future>');
    await pumpStoryEditor(tester, controller);

    expect(find.text('Unsupported content'), findsOneWidget);
  });

  testWidgets('the controller can draw unknown content its own way', (tester) async {
    final controller = StoryEditorController(
      embeds: testEmbeds,
      markdown: '<sp-future x="1"></sp-future>',
      unknownBuilder: (context, embed) => Text('custom: ${(embed.value as UnknownHtmlEmbed).tag}'),
    );
    addTearDown(controller.dispose);
    await pumpStoryEditor(tester, controller);

    expect(find.text('custom: sp-future'), findsOneWidget);
  });

  testWidgets('a node of an unregistered embed type shows a placeholder instead of crashing', (tester) async {
    final controller = controllerFor('a');
    controller.document.insertNodeAt(0, StoryEmbedNode(id: 'x', type: 'poll', value: 'q'));
    await pumpStoryEditor(tester, controller);

    expect(find.text('No embed registered for "poll"'), findsOneWidget);
  });

  testWidgets('embeds rebuild when read-only changes', (tester) async {
    final controller = controllerFor('<sp-sticker name="cat"></sp-sticker>');
    await pumpStoryEditor(tester, controller);
    expect(find.text('sticker cat'), findsOneWidget);

    controller.readOnly = true;
    await tester.pump();
    expect(find.text('sticker cat (read-only)'), findsOneWidget);
  });
}
