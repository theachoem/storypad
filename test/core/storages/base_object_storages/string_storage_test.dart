import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypad/core/storages/base_object_storages/string_storage.dart';

class FakeStorage extends StringStorage {}

void main() {
  SharedPreferences.setMockInitialValues({});

  group("DefaultStorage", () {
    test("it write & return 'abc' from storage", () async {
      final fakeStorage = FakeStorage();

      const expectedStr = "abc";
      await fakeStorage.write(expectedStr);

      final strFromStorage = await fakeStorage.read();
      expect(strFromStorage, expectedStr);
    });

    test("it write & return 'cde' from storage", () async {
      final fakeStorage = FakeStorage();

      const expectedStr = "cde";
      await fakeStorage.write(expectedStr);

      final strFromStorage = await fakeStorage.read();
      expect(strFromStorage, expectedStr);
    });

    test("it remove value from storage", () async {
      final fakeStorage = FakeStorage();

      await fakeStorage.write('abc');
      await fakeStorage.remove();

      final strFromStorage = await fakeStorage.read();
      expect(strFromStorage, null);
    });
  });
}
