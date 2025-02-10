import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypad/core/storages/preference_storages/default_storage.dart';
import 'package:storypad/core/storages/storage_adapters/base_storage_adapter.dart';
import 'package:storypad/core/storages/storage_adapters/memory_storage_adapter.dart';

class FakeStorage<T> extends DefaultStorage<T> {
  @override
  Future<BaseStorageAdapter<T>> get adapter async => MemoryStorageAdapter<T>();
}

void main() {
  SharedPreferences.setMockInitialValues({});

  group("MemoryStorageAdapter", () {
    test("it write & return int = 98765 from memory", () async {
      final fakeStorage = FakeStorage<int>();

      const expectedInt = 98765;
      await fakeStorage.write(expectedInt);

      final intFromStorage = await fakeStorage.read();
      expect(intFromStorage, expectedInt);
    });

    test("it write & return str = '98765' from memory", () async {
      final fakeStorage = FakeStorage<String>();

      const expectedStr = "chheng";
      await fakeStorage.write(expectedStr);

      final strFromStorage = await fakeStorage.read();
      expect(strFromStorage, expectedStr);
    });

    test("it remove value from memory", () async {
      final fakeStorage = FakeStorage();

      await fakeStorage.write(12345);
      await fakeStorage.remove();

      final intFromStorage = await fakeStorage.read();
      expect(intFromStorage, null);
    });
  });
}
