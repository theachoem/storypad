import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor_example/demo_content.dart';
import 'package:storypad_editor_example/embeds/demo_embeds.dart';
import 'package:storypad_editor_example/pages/raw_editor_page.dart';
import 'package:storypad_editor/storypad_editor.dart';

void main() {
  test('the demo story is canonical Markdown', () {
    final codec = StoryCodec(embeds: demoEmbeds);
    expect(codec.canonicalize(demoMarkdown), demoMarkdown);
  });

  testWidgets('the raw editor page renders the demo embeds and inserts new ones', (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RawEditorPage()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('media-tile-images/lake-1.jpg')), findsOneWidget);
    expect(find.text('birds.m4a'), findsOneWidget);

    await tester.tap(find.byTooltip('Insert'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voice note'));
    await tester.pumpAndSettle();

    expect(find.text('new.m4a'), findsOneWidget);
  });
}
