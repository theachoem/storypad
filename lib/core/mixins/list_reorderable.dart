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
}
