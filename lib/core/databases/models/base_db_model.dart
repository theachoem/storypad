abstract class BaseDbModel {
  int get id;

  DateTime? get updatedAt;
  DateTime? get permanentlyDeletedAt => null;

  Map<String, dynamic> toJson();
}
