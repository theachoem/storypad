import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../../support/controller_helpers.dart';

void main() {
  testWidgets('an embed inside an expanded selection is painted selected, and told so', (tester) async {
    final controller = controllerFor('a\n\n<sp-sticker name="cat"></sp-sticker>\n\nb');
    await StoryEditorTester.pump(tester, controller);

    selectText(controller, 0, 0, 2, 1);
    await tester.pumpAndSettle();

    expect(find.text('sticker cat (selected)'), findsOneWidget);
    expect(find.byKey(ValueKey('story-embed-selection-${nodeAt(controller, 1).id}')), findsOneWidget);
  });

  testWidgets('selecting across unknown content does not crash', (tester) async {
    final controller = controllerFor('a\n\n<sp-future></sp-future>\n\nb');
    await StoryEditorTester.pump(tester, controller);

    selectText(controller, 0, 0, 2, 1);
    await tester.pumpAndSettle();
    controller.composer.setSelectionWithReason(
      DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: nodeAt(controller, 1).id,
          nodePosition: const UpstreamDownstreamNodePosition.downstream(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
