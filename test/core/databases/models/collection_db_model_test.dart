import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';

// Mock model for testing
class _MockDbModel extends BaseDbModel {
  @override
  final int id;
  final String name;
  final int value;
  final DateTime date;

  _MockDbModel({
    required this.id,
    required this.name,
    required this.value,
    required this.date,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'value': value,
      'date': date.toIso8601String(),
    };
  }

  @override
  DateTime? get updatedAt => date;
}

// Simulating StoryDbModel with displayPathDate
class _MockStory extends BaseDbModel {
  @override
  final int id;
  final DateTime displayPathDate;

  _MockStory({required this.id, required this.displayPathDate});

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayPathDate': displayPathDate.toIso8601String(),
    };
  }

  @override
  DateTime? get updatedAt => displayPathDate;
}

void main() {
  group('CollectionDbModel#deduplicateAndSort', () {
    test('returns same collection when empty', () {
      final collection = CollectionDbModel<_MockDbModel>(items: []);
      final result = collection.deduplicateAndSort(
        comparator: (a, b) => a.id.compareTo(b.id),
      );

      expect(result, equals(collection));
    });

    test('returns new collection with sorted items', () {
      final items = [
        _MockDbModel(id: 3, name: 'c', value: 30, date: DateTime(2024, 3)),
        _MockDbModel(id: 1, name: 'a', value: 10, date: DateTime(2024, 1)),
        _MockDbModel(id: 2, name: 'b', value: 20, date: DateTime(2024, 2)),
      ];
      final collection = CollectionDbModel<_MockDbModel>(items: items);

      final result = collection.deduplicateAndSort(
        comparator: (a, b) => a.id.compareTo(b.id),
      );

      expect(result!.items.length, 3);
      expect(result.items[0].id, 1);
      expect(result.items[1].id, 2);
      expect(result.items[2].id, 3);
    });

    test('removes duplicate items by id', () {
      final items = [
        _MockDbModel(id: 1, name: 'a', value: 10, date: DateTime(2024, 1)),
        _MockDbModel(id: 2, name: 'b', value: 20, date: DateTime(2024, 2)),
        _MockDbModel(id: 1, name: 'a-duplicate', value: 15, date: DateTime(2024, 1)),
        _MockDbModel(id: 3, name: 'c', value: 30, date: DateTime(2024, 3)),
      ];
      final collection = CollectionDbModel<_MockDbModel>(items: items);

      final result = collection.deduplicateAndSort(
        comparator: (a, b) => a.id.compareTo(b.id),
      );

      expect(result!.items.length, 3);
      expect(result.items.map((e) => e.id).toList(), [1, 2, 3]);
      // First occurrence should be kept
      expect(result.items[0].name, 'a');
    });

    test('keeps first occurrence when duplicates found', () {
      final items = [
        _MockDbModel(id: 1, name: 'first', value: 10, date: DateTime(2024, 1)),
        _MockDbModel(id: 2, name: 'b', value: 20, date: DateTime(2024, 2)),
        _MockDbModel(id: 1, name: 'second', value: 100, date: DateTime(2024, 1)),
      ];
      final collection = CollectionDbModel<_MockDbModel>(items: items);

      final result = collection.deduplicateAndSort(
        comparator: (a, b) => a.id.compareTo(b.id),
      );

      expect(result!.items.length, 2);
      expect(result.items[0].name, 'first');
      expect(result.items[0].value, 10);
    });

    test('calls onDuplicateFound callback for each duplicate', () {
      final duplicateIds = <int>[];
      final items = [
        _MockDbModel(id: 1, name: 'a', value: 10, date: DateTime(2024, 1)),
        _MockDbModel(id: 2, name: 'b', value: 20, date: DateTime(2024, 2)),
        _MockDbModel(id: 1, name: 'a-dup', value: 15, date: DateTime(2024, 1)),
        _MockDbModel(id: 3, name: 'c', value: 30, date: DateTime(2024, 3)),
        _MockDbModel(id: 2, name: 'b-dup', value: 25, date: DateTime(2024, 2)),
      ];
      final collection = CollectionDbModel<_MockDbModel>(items: items);

      collection.deduplicateAndSort(
        comparator: (a, b) => a.id.compareTo(b.id),
        onDuplicateFound: (id) => duplicateIds.add(id),
      );

      expect(duplicateIds, [1, 2]);
    });

    test('sorts by descending date', () {
      final items = [
        _MockDbModel(id: 1, name: 'a', value: 10, date: DateTime(2024, 1)),
        _MockDbModel(id: 2, name: 'b', value: 20, date: DateTime(2024, 3)),
        _MockDbModel(id: 3, name: 'c', value: 30, date: DateTime(2024, 2)),
      ];
      final collection = CollectionDbModel<_MockDbModel>(items: items);

      final result = collection.deduplicateAndSort(
        comparator: (a, b) => b.date.compareTo(a.date),
      );

      expect(result!.items.length, 3);
      expect(result.items[0].id, 2); // 2024-03
      expect(result.items[1].id, 3); // 2024-02
      expect(result.items[2].id, 1); // 2024-01
    });

    test('sorts by value in ascending order', () {
      final items = [
        _MockDbModel(id: 1, name: 'a', value: 30, date: DateTime(2024, 1)),
        _MockDbModel(id: 2, name: 'b', value: 10, date: DateTime(2024, 2)),
        _MockDbModel(id: 3, name: 'c', value: 20, date: DateTime(2024, 3)),
      ];
      final collection = CollectionDbModel<_MockDbModel>(items: items);

      final result = collection.deduplicateAndSort(
        comparator: (a, b) => a.value.compareTo(b.value),
      );

      expect(result!.items.length, 3);
      expect(result.items[0].value, 10);
      expect(result.items[1].value, 20);
      expect(result.items[2].value, 30);
    });

    test('handles complex deduplication and sorting together', () {
      final duplicateIds = <int>[];
      final items = [
        _MockDbModel(id: 1, name: 'a', value: 10, date: DateTime(2024, 3)),
        _MockDbModel(id: 2, name: 'b', value: 20, date: DateTime(2024, 1)),
        _MockDbModel(id: 1, name: 'a-dup', value: 15, date: DateTime(2024, 2)),
        _MockDbModel(id: 3, name: 'c', value: 30, date: DateTime(2024, 2)),
        _MockDbModel(id: 2, name: 'b-dup', value: 25, date: DateTime(2024, 3)),
      ];
      final collection = CollectionDbModel<_MockDbModel>(items: items);

      final result = collection.deduplicateAndSort(
        comparator: (a, b) => b.date.compareTo(a.date),
        onDuplicateFound: (id) => duplicateIds.add(id),
      );

      // Should remove duplicates
      expect(result!.items.length, 3);
      expect(duplicateIds, [1, 2]);

      // Should sort by date descending
      expect(result.items[0].date, DateTime(2024, 3)); // id: 1
      expect(result.items[1].date, DateTime(2024, 2)); // id: 3
      expect(result.items[2].date, DateTime(2024, 1)); // id: 2
    });

    test('returns collection instance', () {
      final items = [
        _MockDbModel(id: 1, name: 'a', value: 10, date: DateTime(2024, 1)),
      ];
      final collection = CollectionDbModel<_MockDbModel>(items: items);

      final result = collection.deduplicateAndSort(
        comparator: (a, b) => a.id.compareTo(b.id),
      );

      expect(result, isA<CollectionDbModel<_MockDbModel>>());
    });
  });

  group('CollectionDbModel#deduplicateAndSort with StoryDbModel-like sorting', () {
    test('sorts stories by displayPathDate descending (newest first)', () {
      final items = [
        _MockStory(id: 1, displayPathDate: DateTime(2024, 1, 15)),
        _MockStory(id: 2, displayPathDate: DateTime(2024, 1, 25)),
        _MockStory(id: 3, displayPathDate: DateTime(2024, 1, 5)),
      ];
      final collection = CollectionDbModel<_MockStory>(items: items);

      final result = collection.deduplicateAndSort(
        comparator: (a, b) => b.displayPathDate.compareTo(a.displayPathDate),
      );

      expect(result!.items.length, 3);
      expect(result.items[0].id, 2); // 2024-01-25
      expect(result.items[1].id, 1); // 2024-01-15
      expect(result.items[2].id, 3); // 2024-01-05
    });

    test('removes duplicate stories while maintaining sort order', () {
      final duplicateIds = <int>[];
      final items = [
        _MockStory(id: 1, displayPathDate: DateTime(2024, 1, 25)),
        _MockStory(id: 2, displayPathDate: DateTime(2024, 1, 15)),
        _MockStory(id: 1, displayPathDate: DateTime(2024, 1, 10)), // duplicate
        _MockStory(id: 3, displayPathDate: DateTime(2024, 1, 20)),
      ];
      final collection = CollectionDbModel<_MockStory>(items: items);

      final result = collection.deduplicateAndSort(
        comparator: (a, b) => b.displayPathDate.compareTo(a.displayPathDate),
        onDuplicateFound: (id) => duplicateIds.add(id),
      );

      expect(result!.items.length, 3);
      expect(duplicateIds, [1]);
      expect(result.items[0].id, 1); // 2024-01-25
      expect(result.items[1].id, 3); // 2024-01-20
      expect(result.items[2].id, 2); // 2024-01-15
    });
  });
}
