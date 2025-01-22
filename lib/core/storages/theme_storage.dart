import 'package:storypad/core/objects/theme_object.dart';
import 'package:storypad/core/storages/base_object_storages/object_storage.dart';

class ThemeStorage extends ObjectStorage<ThemeObject> {
  ThemeStorage._();
  static final ThemeStorage instance = ThemeStorage._();

  ThemeObject get theme => _theme ?? ThemeObject.initial();
  ThemeObject? _theme;

  Future<void> load() async {
    _theme = await readObject();
  }

  @override
  ThemeObject decode(Map<String, dynamic> json) => ThemeObject.fromJson(json);

  @override
  Map<String, dynamic> encode(ThemeObject object) => object.toJson();
}
