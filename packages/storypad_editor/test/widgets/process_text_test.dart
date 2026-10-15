import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// Android's "Process Text" apps in the selection menus, from the package's Android side: queried afresh as each
/// selection starts (as a native TextView does), in the system's order.
void main() {
  const channel = MethodChannel('storypad_editor/process_text');
  late List<List<Map<String, String>>> answers;
  late int queries;
  late List<Map<Object?, Object?>> processed;
  late String? returnedText;

  setUp(() {
    answers = [];
    queries = 0;
    processed = [];
    returnedText = null;
  });

  Future<void> mockAndroidSide(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'queryTextActions':
          final answer = answers[queries < answers.length ? queries : answers.length - 1];
          queries++;
          return answer;
        case 'processTextAction':
          processed.add(call.arguments as Map<Object?, Object?>);
          return returnedText;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
  }

  Future<void> selectWord(WidgetTester tester, {bool focusFirst = false}) async {
    final word = tester.getTopLeft(find.byType(TextComponent)) + const Offset(12, 8);
    if (focusFirst) {
      // Unfocused, a long-press in the editor reorders blocks.
      await tester.tapAt(word);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
    }
    await tester.longPressAt(word);
    await tester.pumpAndSettle();
  }

  Future<void> openOverflow(WidgetTester tester) async {
    if (find.byIcon(Icons.more_vert).evaluate().isEmpty) return;
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
  }

  testWidgets('read-only: the apps in the system\'s order; one gets the text, read-only', (tester) async {
    answers = [
      [
        {'id': 'com.example.claude/.Ask', 'label': 'Ask Claude'},
        {'id': 'com.example.translate/.Translate', 'label': 'Translate'},
        {'id': 'com.example.chat/.Ask', 'label': 'Ask ChatGPT'},
      ],
    ];
    await mockAndroidSide(tester);
    final controller = controllerFor('Hello world', readOnly: true);
    await pumpStoryEditor(tester, controller, editor: RawEditor(controller: controller));
    await selectWord(tester);
    await openOverflow(tester);

    final labels = ['Ask Claude', 'Translate', 'Ask ChatGPT'];
    final tops = [for (final label in labels) tester.getTopLeft(find.text(label))];
    for (var i = 1; i < tops.length; i++) {
      final before = tops[i - 1];
      expect(tops[i].dy > before.dy || (tops[i].dy == before.dy && tops[i].dx > before.dx), isTrue, reason: labels[i]);
    }

    await tester.tap(find.text('Translate'));
    await tester.pumpAndSettle();
    expect(processed, [
      {'id': 'com.example.translate/.Translate', 'text': 'Hello', 'readOnly': true},
    ]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('queried again as a selection starts: an app updated meanwhile shows as it is now', (tester) async {
    answers = [
      [
        {'id': 'com.example.claude/.Ask', 'label': 'com.example.claude.Ask'},
      ],
      [
        {'id': 'com.example.claude/.Ask', 'label': 'Ask Claude'},
      ],
    ];
    await mockAndroidSide(tester);
    final controller = controllerFor('Hello world', readOnly: true);
    await pumpStoryEditor(tester, controller, editor: RawEditor(controller: controller));
    expect(queries, 1, reason: 'up front');

    await selectWord(tester);
    expect(queries, 2, reason: 'as the selection started');
    await openOverflow(tester);
    expect(find.text('Ask Claude'), findsOneWidget);
    expect(find.text('com.example.claude.Ask'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('editing: the text an app returns replaces the selection', (tester) async {
    answers = [
      [
        {'id': 'com.example.translate/.Translate', 'label': 'Translate'},
      ],
    ];
    returnedText = 'Bonjour';
    await mockAndroidSide(tester);
    final controller = controllerFor('Hello world');
    await pumpStoryEditor(tester, controller, editor: RawEditor(controller: controller));
    await selectWord(tester, focusFirst: true);
    await openOverflow(tester);

    await tester.tap(find.text('Translate'));
    await tester.pumpAndSettle();
    expect(processed.single['readOnly'], isFalse);
    expect(controller.toMarkdown(), 'Bonjour world');
    controller.actions.undo();
    expect(controller.toMarkdown(), 'Hello world', reason: 'one undo step');
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
