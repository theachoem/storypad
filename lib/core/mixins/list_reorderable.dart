extension ListReoderable<T> on List<T> {
  List<T> swap({
    required int oldIndex,
    required int newIndex,
  }) {
    List<T> newItems = [...this];
    final temp = newItems[oldIndex];

    newItems[oldIndex] = newItems[newIndex];
    newItems[newIndex] = temp;

    return newItems;
  }

  List<T> reorder({
    required int oldIndex,
    required int newIndex,
  }) {
    if (oldIndex < 0 || oldIndex >= length) return this;
    if (newIndex < 0 || newIndex > length) return this;

    final items = toList();
    final item = items.removeAt(oldIndex);

    final insertIndex = (oldIndex < newIndex && oldIndex != newIndex - 1) ? newIndex - 1 : newIndex;

    items.insert(insertIndex, item);
    return items;
  }
}
