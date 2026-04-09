import 'package:storypad/core/storages/base_object_storages/integer_storage.dart';

class PreviouslyVisitedTemplateTabIndexStorage extends IntegerStorage {
  static PreviouslyVisitedTemplateTabIndexStorage appInstance = PreviouslyVisitedTemplateTabIndexStorage();

  int? currentIndex;
  Future<void> ensureInitialized() async {
    currentIndex ??= await read();
  }

  @override
  Future<void> write(int? value) {
    currentIndex = value;
    return super.write(value);
  }
}
