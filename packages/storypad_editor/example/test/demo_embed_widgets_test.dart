import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:storypad_editor_example/embeds/demo_embeds.dart';

void main() {
  testWidgets('media controls update the embed through its context; tapping the same alignment turns it off', (
    tester,
  ) async {
    final controller = StoryEditorController(
      embeds: demoEmbeds,
      markdown: '<sp-album><img src="images/a.jpg"><img src="images/b.jpg"></sp-album>',
    );
    addTearDown(controller.dispose);
    await pumpStoryEditor(tester, controller);

    MediaValue value() => controller.embedsOf(const MediaEmbed()).single.$2;

    await tester.tap(find.byTooltip('Align center'));
    await tester.pumpAndSettle();
    expect(value().alignment, EmbedAlignment.center);

    await tester.tap(find.byTooltip('Align center'));
    await tester.pumpAndSettle();
    expect(value().alignment, EmbedAlignment.none);

    await tester.tap(find.byTooltip('Toggle size'));
    await tester.pumpAndSettle();
    expect(value().size, EmbedSize.max);
    expect(controller.toMarkdown(), contains('data-size="max"'));

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    expect(controller.embedsOf(const MediaEmbed()), isEmpty);
  });

  testWidgets('read-only hides the controls', (tester) async {
    final controller = StoryEditorController(
      embeds: demoEmbeds,
      markdown: '![](images/a.jpg)\n\n<audio controls src="audio/a.m4a"></audio>',
      readOnly: true,
    );
    addTearDown(controller.dispose);
    await pumpStoryEditor(tester, controller);

    expect(find.byTooltip('Remove'), findsNothing);
    expect(find.byTooltip('Toggle size'), findsNothing);
  });
}
