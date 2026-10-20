import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/views/stories/local_widgets/story_app_bar_unfocus_area.dart';

void main() {
  late FocusNode bodyFocus;
  late FocusNode titleFocus;
  var actionTaps = 0;

  setUp(() {
    bodyFocus = FocusNode();
    titleFocus = FocusNode();
    actionTaps = 0;
  });

  Future<void> pump(WidgetTester tester) async {
    // After the tree goes (tear-downs run last-added first), not while the fields still hold them.
    addTearDown(() {
      bodyFocus.dispose();
      titleFocus.dispose();
    });
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            flexibleSpace: const StoryAppBarUnfocusArea(),
            leading: const CloseButton(),
            // As the template editor's name field; the story editor has no title.
            title: SizedBox(width: 120, child: TextField(focusNode: titleFocus)),
            centerTitle: false,
            actions: [IconButton(onPressed: () => actionTaps++, icon: const Icon(Icons.done))],
          ),
          body: TextField(focusNode: bodyFocus, autofocus: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final titleField = find.descendant(of: find.byType(AppBar), matching: find.byType(TextField));

  /// A point on the app bar between its title and its actions.
  Offset emptySpot(WidgetTester tester) {
    final appBar = tester.getRect(find.byType(AppBar));
    final title = tester.getRect(titleField);
    final action = tester.getRect(find.byType(IconButton).last);
    return Offset((title.right + action.left) / 2, appBar.center.dy);
  }

  testWidgets('a tap on the empty app bar hides the keyboard', (tester) async {
    await pump(tester);
    expect(bodyFocus.hasFocus, isTrue);

    await tester.tapAt(emptySpot(tester));
    await tester.pump();
    expect(bodyFocus.hasFocus, isFalse);
  });

  testWidgets('its buttons and title keep their taps', (tester) async {
    await pump(tester);

    await tester.tap(find.byType(IconButton).last);
    await tester.pump();
    expect(actionTaps, 1);
    expect(bodyFocus.hasFocus, isTrue, reason: 'a button doesn\'t hide the keyboard');

    await tester.tap(titleField);
    await tester.pump();
    expect(titleFocus.hasFocus, isTrue);
  });
}
