import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypad/core/storages/base_object_storages/enum_storage.dart';

enum FakeEnum {
  car,
  motor,
}

class FakeEnumStorage extends EnumStorage<FakeEnum> {
  @override
  List<FakeEnum> get values => FakeEnum.values;
}

void main() {
  SharedPreferences.setMockInitialValues({});

  group("FakeEnumStorage < EnumStorage", () {
    test("it return enum 'car' from storage", () async {
      final fakeStorage = FakeEnumStorage();

      const expectedEnum = FakeEnum.car;
      await fakeStorage.writeEnum(expectedEnum);

      final enumFromStorage = await fakeStorage.readEnum();
      expect(enumFromStorage, expectedEnum);
    });

    test("it return enum 'motor' from storage", () async {
      final fakeStorage = FakeEnumStorage();

      const expectedEnum = FakeEnum.motor;
      await fakeStorage.writeEnum(expectedEnum);

      final enumFromStorage = await fakeStorage.readEnum();
      expect(enumFromStorage, expectedEnum);
    });

    test("it remove enum value from storage", () async {
      final fakeStorage = FakeEnumStorage();

      await fakeStorage.writeEnum(FakeEnum.motor);
      await fakeStorage.remove();

      final enumFromStorage = await fakeStorage.read();
      expect(enumFromStorage, null);
    });
  });
}
