import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/minimum_execution_time_service.dart';

void main() {
  group('MinimumExecutionTimeService.call', () {
    test('waits if callback is faster than minimum duration', () async {
      const minDuration = Duration(milliseconds: 500);
      final startedAt = DateTime.now();

      final result = await MinimumExecutionTimeService.call(
        duration: minDuration,
        callback: () async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'done';
        },
      );

      final endedAt = DateTime.now();
      final totalDuration = endedAt.difference(startedAt);

      expect(result, equals('done'));
      expect(totalDuration >= minDuration, isTrue, reason: 'Expected at least $minDuration but got $totalDuration');
    });

    test('does not delay if callback is slower than minimum duration', () async {
      const minDuration = Duration(milliseconds: 300);

      final startedAt = DateTime.now();

      final result = await MinimumExecutionTimeService.call(
        duration: minDuration,
        callback: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          return 42;
        },
      );

      final endedAt = DateTime.now();
      final totalDuration = endedAt.difference(startedAt);

      expect(result, equals(42));
      expect(
        totalDuration >= const Duration(milliseconds: 500),
        isTrue,
        reason: 'Callback should not be delayed further',
      );
    });
  });
}
