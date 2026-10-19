import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypad/core/storages/older_app_last_seen_storage.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nothing seen: deleted records are purged as usual', () async {
    final storage = OlderAppLastSeenStorage();
    expect(await storage.readDate(), isNull);
    expect(await storage.seenWithin(OlderAppLastSeenStorage.keepDeletedRecordsFor), isFalse);
  });

  test('keeps the newest time seen', () async {
    final storage = OlderAppLastSeenStorage();
    final newer = DateTime.now().subtract(const Duration(days: 10));

    await storage.recordSeen(newer);
    await storage.recordSeen(newer.subtract(const Duration(days: 5)));
    expect(await storage.readDate(), newer.toUtc());
  });

  test('seen within the window, then not', () async {
    final storage = OlderAppLastSeenStorage();

    await storage.recordSeen(DateTime.now().subtract(const Duration(days: 89)));
    expect(await storage.seenWithin(OlderAppLastSeenStorage.keepDeletedRecordsFor), isTrue);

    SharedPreferences.setMockInitialValues({});
    await storage.recordSeen(DateTime.now().subtract(const Duration(days: 91)));
    expect(await OlderAppLastSeenStorage().seenWithin(OlderAppLastSeenStorage.keepDeletedRecordsFor), isFalse);
  });
}
