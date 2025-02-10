import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypad/core/storages/base_object_storages/object_storage.dart';

class FakeStorage extends ObjectStorage<FakeObject> {
  @override
  FakeObject decode(Map<String, dynamic> json) {
    return FakeObject.fromJson(json);
  }

  @override
  Map<String, dynamic> encode(FakeObject object) {
    return object.toJson();
  }
}

void main() {
  SharedPreferences.setMockInitialValues({});

  group("FakeStorage < ObjectStorage", () {
    test("it write & return 'chheng' object from storage", () async {
      FakeStorage fakeStorage = FakeStorage();
      FakeObject expectedObject = const FakeObject("chheng", 12);

      await fakeStorage.writeObject(expectedObject);
      FakeObject? objectFromStorage = await fakeStorage.readObject();

      expect(objectFromStorage?.name, expectedObject.name);
      expect(objectFromStorage?.value, expectedObject.value);
    });

    test("it remove value from storage", () async {
      final fakeStorage = FakeStorage();

      await fakeStorage.writeObject(const FakeObject("chheng", 12));
      await fakeStorage.remove();

      final objectFromStorage = await fakeStorage.readObject();
      expect(objectFromStorage, null);
    });
  });
}

class FakeObject {
  final String name;
  final int value;

  const FakeObject(
    this.name,
    this.value,
  );

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }

  factory FakeObject.fromJson(Map<String, dynamic> json) {
    return FakeObject(
      json['name']!,
      json['value']!,
    );
  }
}
