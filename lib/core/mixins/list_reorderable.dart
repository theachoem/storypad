extension ListReoderable<T> on List<T> {
  List<T> reorder({
    required int oldIndex,
    required int newIndex,
  }) {
    List<T> newItems = [...toList()];
    T oldItem = newItems.removeAt(oldIndex);

    newItems.insert(newIndex, oldItem);

    return newItems;
  }
}
