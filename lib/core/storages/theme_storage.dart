import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/theme_object.dart';
import 'package:storypad/core/storages/base_object_storages/object_storage.dart';

@Deprecated('Use [DevicePreferencesStorage] instead')
class ThemeStorage extends ObjectStorage<ThemeObject> {
  ThemeObject get theme => _theme ?? ThemeObject.initial();
  ThemeObject? _theme;

  Future<void> load() async {
    _theme = await readObject();

    if (_theme == null) {
      // ignore: deprecated_member_use
      _theme = ThemeObject(colorSeedValue: kDefaultColorSeed.value);
      await writeObject(_theme!);
    }
  }

  @override
  ThemeObject decode(Map<String, dynamic> json) => ThemeObject.fromJson(json);

  @override
  Map<String, dynamic> encode(ThemeObject object) => object.toJson();
}
