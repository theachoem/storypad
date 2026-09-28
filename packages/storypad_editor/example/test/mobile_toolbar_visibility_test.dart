import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/toolbar_harness.dart';

void main() {
  testWidgets(
    'the mobile toolbar shows while editing, survives its own taps and taps outside, and hides once unfocused',
    (tester) async {
      final controller = await pumpEditorWithToolbar(tester, 'Hello world');
      expect(find.byTooltip('Bold'), findsNothing);

      await focusEditor(tester);
      expect(find.byTooltip('Bold'), findsOneWidget);

      await tester.tap(find.byTooltip('Bold'));
      await tester.pumpAndSettle();
      expect(controller.focusNode.hasFocus, isTrue, reason: 'the toolbar is in the editor\'s tap region group');
      expect(find.byTooltip('Bold'), findsOneWidget);

      // Tapping outside doesn't unfocus (the keyboard's own key does).
      await tester.tap(find.text('Outside area'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Bold'), findsOneWidget);

      controller.focusNode.unfocus();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Bold'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
