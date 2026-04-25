import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/analytics/adaptors/none_analytics_event_adaptor.dart';

void main() {
  late NoneAnalyticsEventAdaptor adaptor;

  setUp(() => adaptor = NoneAnalyticsEventAdaptor());

  group('NoneAnalyticsEventAdaptor', () {
    test('logEvent completes without throwing', () async {
      await expectLater(adaptor.logEvent('test_event'), completes);
    });

    test('logEvent with parameters completes without throwing', () async {
      await expectLater(
        adaptor.logEvent('test_event', parameters: {'key': 'value'}),
        completes,
      );
    });

    test('logScreenView completes without throwing', () async {
      await expectLater(
        adaptor.logScreenView(screenClass: 'HomeView', screenName: 'Home'),
        completes,
      );
    });

    test('logLogin completes without throwing', () async {
      await expectLater(adaptor.logLogin(loginMethod: 'google'), completes);
    });

    test('logSearchEvent completes without throwing', () async {
      await expectLater(adaptor.logSearchEvent(searchTerm: 'query'), completes);
    });

    // High-level methods via primitives
    test('logSearch completes without throwing', () async {
      await expectLater(adaptor.logSearch(searchTerm: 'hello'), completes);
    });

    test('logSyncBackup completes without throwing', () async {
      await expectLater(adaptor.logSyncBackup(), completes);
    });

    test('logSignInWithGoogle completes without throwing', () async {
      await expectLater(adaptor.logSignInWithGoogle(), completes);
    });

    test('logSignOut completes without throwing', () async {
      await expectLater(adaptor.logSignOut(), completes);
    });

    test('logShareApp completes without throwing', () async {
      await expectLater(adaptor.logShareApp(), completes);
    });
  });
}
