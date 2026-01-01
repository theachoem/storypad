import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/services/logger/app_logger.dart';

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
  bool exists(int id) => items.map((e) => e.id).contains(id);

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

  /// Deduplicates items by id and sorts them using the provided comparator.
  /// Returns a new CollectionDbModel with unique, sorted items.
  ///
  /// If the collection is empty or null, returns the original collection.
  /// Keeps the first occurrence of each id when duplicates are found.
  CollectionDbModel<T>? deduplicateAndSort({
    required int Function(T a, T b) comparator,
    void Function(int id)? onDuplicateFound,
  }) {
    if (items.isEmpty) return this;

    final seenIds = <int>{};
    final uniqueItems = items.where((item) {
      if (seenIds.contains(item.id)) {
        AppLogger.debug('Deduplicate: Skipping duplicate ${item.runtimeType}:${item.id}');
        onDuplicateFound?.call(item.id);
        return false;
      }
      seenIds.add(item.id);
      return true;
    }).toList();

    uniqueItems.sort(comparator);
    return CollectionDbModel(items: uniqueItems);
  }
}
