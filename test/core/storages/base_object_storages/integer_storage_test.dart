import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypad/core/storages/base_object_storages/integer_storage.dart';

class FakeStorage extends IntegerStorage {}

void main() {
  SharedPreferences.setMockInitialValues({});

  group("FakeStorage < IntegerStorage", () {
    test("it write & return 12345 from storage", () async {
      final fakeStorage = FakeStorage();

      const expectedInt = 12345;
      await fakeStorage.write(expectedInt);

      final intFromStorage = await fakeStorage.read();
      expect(intFromStorage, expectedInt);
    });

    test("it remove value from storage", () async {
      final fakeStorage = FakeStorage();

      await fakeStorage.write(12345);
      await fakeStorage.remove();

      final intFromStorage = await fakeStorage.read();
      expect(intFromStorage, null);
    });
  });
}
