import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypad/core/storages/base_object_storages/list_storage.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  group("ListStorage", () {
    test("it write & return list of STRING from storage", () async {
      ListStorage<String> fakeStorage = ListStorage<String>();
      List<String> expectedStrList = ["abc", "cde"];

      await fakeStorage.writeList(expectedStrList);
      List<String> listFromStorage = await fakeStorage.readList() ?? [];

      expect(listFromStorage[0], "abc");
      expect(listFromStorage[1], "cde");
      expect(listFromStorage, expectedStrList);
    });

    test("it write & return list of INT from storage", () async {
      ListStorage<int> fakeStorage = ListStorage<int>();
      List<int> expectedIntList = [1, 2];

      await fakeStorage.writeList(expectedIntList);
      List<int>? listFromStorage = await fakeStorage.readList() ?? [];

      expect(listFromStorage[0], 1);
      expect(listFromStorage[1], 2);
      expect(listFromStorage, expectedIntList);
    });

    test("it write & return list of BOOLEAN from storage", () async {
      ListStorage<bool> fakeStorage = ListStorage<bool>();

      List<bool> expectedBoolList = [false, true];
      await fakeStorage.writeList(expectedBoolList);

      List<bool>? listFromStorage = await fakeStorage.readList();
      expect(listFromStorage, expectedBoolList);
    });

    test("it remove value from storage", () async {
      ListStorage<String> fakeStorage = ListStorage<String>();

      await fakeStorage.writeList(['a', 'b']);
      await fakeStorage.remove();

      List<String>? listFromStorage = await fakeStorage.readList();
      expect(listFromStorage, null);
    });

    test("it throw assert exception when element is not int, string, bool", () async {
      ListStorage<Map> fakeStorage = ListStorage<Map>();
      Object? error;

      try {
        await fakeStorage.writeList([
          {'a': 1},
          {'b': 1},
        ]);
      } catch (e) {
        error = e;
      }

      expect(
        error.toString().contains('element is int || element is String || element is bool'),
        true,
      );
    });
  });
}
