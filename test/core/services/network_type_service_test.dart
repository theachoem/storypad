import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/network_type_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void mockConnectivity(List<String>? Function() handler) {
    messenger.setMockMethodCallHandler(channel, (call) async => handler());
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('NetworkTypeService', () {
    test('wifi is unmetered', () async {
      mockConnectivity(() => ['wifi']);

      expect(await const NetworkTypeService().isUnmetered(), isTrue);
    });

    test('mobile alone is metered', () async {
      mockConnectivity(() => ['mobile']);

      expect(await const NetworkTypeService().isUnmetered(), isFalse);
    });

    // A device can report several interfaces at once; only "mobile is the sole
    // way out" should defer media.
    test('mobile alongside wifi is unmetered', () async {
      mockConnectivity(() => ['mobile', 'wifi']);

      expect(await const NetworkTypeService().isUnmetered(), isTrue);
    });

    test('ethernet is unmetered', () async {
      mockConnectivity(() => ['ethernet']);

      expect(await const NetworkTypeService().isUnmetered(), isTrue);
    });

    // Fails open on purpose: being wrong this way costs one unexpected upload,
    // the other way it silently stops media from ever backing up.
    test('fails open when the platform throws', () async {
      mockConnectivity(() => throw PlatformException(code: 'boom'));

      expect(await const NetworkTypeService().isUnmetered(), isTrue);
    });

    test('fails open when the platform reports nothing', () async {
      mockConnectivity(() => []);

      expect(await const NetworkTypeService().isUnmetered(), isTrue);
    });
  });
}
