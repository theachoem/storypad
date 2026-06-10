import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/auto_sync_trigger_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutoSyncTriggerService', () {
    test('start triggers immediately', () {
      var triggerCount = 0;
      final service = AutoSyncTriggerService(onTrigger: () => triggerCount++);

      service.start();

      expect(triggerCount, 1);
      service.dispose();
    });

    test('resume before throttle duration does not re-trigger', () {
      var now = DateTime(2026, 1, 1, 12);
      var triggerCount = 0;

      final service = AutoSyncTriggerService(
        onTrigger: () => triggerCount++,
        throttleDuration: const Duration(minutes: 30),
        now: () => now,
      );

      service.start();
      expect(triggerCount, 1);

      now = now.add(const Duration(minutes: 10));
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(triggerCount, 1);
      service.dispose();
    });

    test('resume after throttle duration re-triggers', () {
      var now = DateTime(2026, 1, 1, 12);
      var triggerCount = 0;

      final service = AutoSyncTriggerService(
        onTrigger: () => triggerCount++,
        throttleDuration: const Duration(minutes: 30),
        now: () => now,
      );

      service.start();
      expect(triggerCount, 1);

      now = now.add(const Duration(minutes: 31));
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(triggerCount, 2);
      service.dispose();
    });

    test('non-resumed lifecycle states do not trigger', () {
      var triggerCount = 0;
      final service = AutoSyncTriggerService(onTrigger: () => triggerCount++);

      service.start();
      expect(triggerCount, 1);

      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      service.didChangeAppLifecycleState(AppLifecycleState.inactive);
      service.didChangeAppLifecycleState(AppLifecycleState.detached);
      service.didChangeAppLifecycleState(AppLifecycleState.hidden);

      expect(triggerCount, 1);
      service.dispose();
    });

    test('repeated resumes within throttle window each reset the window from last trigger', () {
      var now = DateTime(2026, 1, 1, 12);
      var triggerCount = 0;

      final service = AutoSyncTriggerService(
        onTrigger: () => triggerCount++,
        throttleDuration: const Duration(minutes: 30),
        now: () => now,
      );

      service.start();
      expect(triggerCount, 1);

      now = now.add(const Duration(minutes: 31));
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(triggerCount, 2);

      now = now.add(const Duration(minutes: 10));
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(triggerCount, 2);

      service.dispose();
    });
  });
}
