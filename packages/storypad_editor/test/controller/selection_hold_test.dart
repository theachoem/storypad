import 'package:flutter_test/flutter_test.dart';

import '../support/controller_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('holds are counted, and releasing twice is harmless', () {
    final controller = controllerFor('');

    final a = controller.holdSelection();
    final b = controller.holdSelection();
    expect(controller.isSelectionHeld.value, isTrue);
    expect(controller.isToolbarActive.value, isTrue);

    a.release();
    a.release();
    expect(controller.isSelectionHeld.value, isTrue, reason: 'b is still held');

    b.release();
    expect(controller.isSelectionHeld.value, isFalse);
    expect(controller.isToolbarActive.value, isFalse, reason: 'not focused either');
  });

  test('keepSelectionWhile holds for the duration, even if the body throws', () async {
    final controller = controllerFor('');

    final result = await controller.keepSelectionWhile(() async {
      expect(controller.isSelectionHeld.value, isTrue);
      return 42;
    });
    expect(result, 42);
    expect(controller.isSelectionHeld.value, isFalse);

    await expectLater(controller.keepSelectionWhile<void>(() async => throw StateError('x')), throwsStateError);
    expect(controller.isSelectionHeld.value, isFalse);
  });
}
