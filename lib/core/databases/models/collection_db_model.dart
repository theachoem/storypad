import 'package:storypad/core/databases/models/base_db_model.dart';

class CollectionDbModel<T extends BaseDbModel> {
  final List<T> items;

  CollectionDbModel({
    required this.items,
  });

  CollectionDbModel<T> replaceElement(T item) {
    if (!items.map((e) => e.id).contains(item.id)) return this;
    List<T> newItems = items.toList();

    int index = newItems.indexWhere((e) => e.id == item.id);
    newItems[index] = item;

    return CollectionDbModel(
      items: newItems,
    );
  }

  CollectionDbModel<T> addElement(T item, int index) {
    List<T> newItems = items.toList();
    newItems.insert(index, item);

    return CollectionDbModel(
      items: newItems,
    );
  }

  T? find(int id) => items.where((e) => e.id == id).firstOrNull;

  CollectionDbModel<T>? removeElement(T item) {
    if (!items.map((e) => e.id).contains(item.id)) return this;

    List<T> newItems = items.toList()..removeWhere((e) => e.id == item.id);
    return CollectionDbModel(items: newItems);
  }

  CollectionDbModel<T>? reorder({
    required int oldIndex,
    required int newIndex,
  }) {
    if (oldIndex < newIndex) newIndex -= 1;

    if (newIndex > items.length - 1) return this;
    if (oldIndex > items.length - 1) return this;

    List<T> newItems = items.toList();
    T oldItem = newItems.removeAt(oldIndex);

    newItems.insert(newIndex, oldItem);

    return CollectionDbModel(items: newItems);
  }
}
