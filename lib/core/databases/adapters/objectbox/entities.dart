// ignore_for_file: overridden_fields

import 'package:objectbox/objectbox.dart';
import 'package:storypad/core/constants/app_constants.dart';

abstract class BaseObjectBox<T> {
  void toPermanentlyDeleted({
    DateTime? deletedAt,
  });

  void setDeviceId() {
    lastSavedDeviceId = kDeviceInfo.id;
  }

  void touch();

  DateTime get createdAt;
  DateTime get updatedAt;
  DateTime? permanentlyDeletedAt;
  String? lastSavedDeviceId;
}

@Entity()
class StoryObjectBox extends BaseObjectBox {
  @Id(assignable: true)
  int id;
  int version;

  @Index()
  String type;

  @Index()
  int year;

  @Index()
  int month;

  @Index()
  int day;
  int? hour;
  int? minute;
  int? second;

  @Index()
  bool? starred;

  @Index()
  bool? pinned;
  String? feeling;

  @override
  @Property(type: PropertyType.date)
  DateTime createdAt;

  @override
  @Property(type: PropertyType.date)
  DateTime updatedAt;

  @Property(type: PropertyType.date)
  DateTime? movedToBinAt;

  @override
  @Property(type: PropertyType.date)
  DateTime? permanentlyDeletedAt;

  String? latestContent;
  String? draftContent;

  // deprecated
  // this is for v1 data. We keep it for migration purpose only.
  List<String> changes;

  List<String>? tags;
  List<int>? assets;

  @Index()
  int? templateId;

  @Index()
  String? galleryTemplateId;

  @Index()
  int? eventId;
  int? wordCount;
  int? characterCount;

  // location — unpacked from PlaceDbModel on write for range queries
  double? latitude;
  double? longitude;
  String? placeName;

  /// JSON-encoded PlaceDbModel (placeName, locality, country, address, lat, lon).
  String? place;

  // for query
  String? searchMetadata;

  String? preferences;

  @override
  String? lastSavedDeviceId;

  StoryObjectBox({
    required this.id,
    required this.version,
    required this.type,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.second,
    required this.starred,
    required this.pinned,
    required this.feeling,
    required this.createdAt,
    required this.updatedAt,
    required this.movedToBinAt,
    required this.galleryTemplateId,
    required this.templateId,
    required this.latestContent,
    required this.draftContent,
    @Deprecated('deprecated') required this.changes,
    required this.tags,
    required this.assets,
    required this.eventId,
    required this.wordCount,
    required this.characterCount,
    required this.searchMetadata,
    required this.preferences,
    required this.permanentlyDeletedAt,
    required this.latitude,
    required this.longitude,
    required this.placeName,
    required this.place,
    this.lastSavedDeviceId,
  });

  @override
  void toPermanentlyDeleted({
    DateTime? deletedAt,
  }) {
    updatedAt = DateTime.now();
    permanentlyDeletedAt = deletedAt ?? DateTime.now();
  }

  @override
  void touch() {
    updatedAt = DateTime.now();
  }
}

@Entity()
class TagCategoryObjectBox extends BaseObjectBox {
  @Id(assignable: true)
  int id;

  String title;
  bool multiSelect;
  bool system;

  int? index;
  int version;

  @override
  @Property(type: PropertyType.date)
  DateTime createdAt;

  @override
  @Property(type: PropertyType.date)
  DateTime updatedAt;

  @override
  @Property(type: PropertyType.date)
  DateTime? permanentlyDeletedAt;

  @override
  String? lastSavedDeviceId;

  TagCategoryObjectBox({
    required this.id,
    required this.title,
    required this.multiSelect,
    required this.system,
    required this.index,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.permanentlyDeletedAt,
    this.lastSavedDeviceId,
  });

  @override
  void toPermanentlyDeleted({
    DateTime? deletedAt,
  }) {
    updatedAt = DateTime.now();
    permanentlyDeletedAt = deletedAt ?? DateTime.now();
  }

  @override
  void touch() {
    updatedAt = DateTime.now();
  }
}

@Entity()
class TagObjectBox extends BaseObjectBox {
  @Id(assignable: true)
  int id;
  String title;

  int? index;
  int version;
  String? emoji;

  int? categoryId;

  @override
  @Property(type: PropertyType.date)
  DateTime createdAt;

  @override
  @Property(type: PropertyType.date)
  DateTime updatedAt;

  @override
  @Property(type: PropertyType.date)
  DateTime? permanentlyDeletedAt;

  @override
  String? lastSavedDeviceId;

  TagObjectBox({
    required this.id,
    required this.title,
    required this.index,
    required this.version,
    required this.emoji,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    required this.permanentlyDeletedAt,
    this.lastSavedDeviceId,
  });

  @override
  void toPermanentlyDeleted({
    DateTime? deletedAt,
  }) {
    updatedAt = DateTime.now();
    permanentlyDeletedAt = deletedAt ?? DateTime.now();
  }

  @override
  void touch() {
    updatedAt = DateTime.now();
  }
}

@Entity()
class AssetObjectBox extends BaseObjectBox {
  @Id(assignable: true)
  int id;
  String originalSource;
  String cloudDestinations;

  @Index()
  int? version;

  // 'image', 'audio', etc.
  @Index()
  String? type;

  // JSON metadata for flexible storage (duration, transcription, etc.)
  String? metadata;

  List<int>? tags;

  @override
  @Property(type: PropertyType.date)
  DateTime createdAt;

  @override
  @Property(type: PropertyType.date)
  DateTime updatedAt;

  @override
  @Property(type: PropertyType.date)
  DateTime? permanentlyDeletedAt;

  @override
  String? lastSavedDeviceId;

  AssetObjectBox({
    required this.id,
    required this.originalSource,
    required this.cloudDestinations,
    required this.createdAt,
    required this.updatedAt,
    required this.permanentlyDeletedAt,
    required this.type,
    required this.metadata,
    required this.tags,
    required this.version,
    this.lastSavedDeviceId,
  });

  @override
  void toPermanentlyDeleted({
    DateTime? deletedAt,
  }) {
    updatedAt = DateTime.now();
    permanentlyDeletedAt = deletedAt ?? DateTime.now();
  }

  @override
  void touch() {
    updatedAt = DateTime.now();
  }
}

@Entity()
class EventObjectBox extends BaseObjectBox {
  @Id(assignable: true)
  int id;

  @Index()
  int year;

  @Index()
  int month;
  int day;

  @Index()
  String eventType; // "period"

  @override
  @Property(type: PropertyType.date)
  DateTime createdAt;

  @override
  @Property(type: PropertyType.date)
  DateTime updatedAt;

  @override
  @Property(type: PropertyType.date)
  DateTime? permanentlyDeletedAt;

  @override
  String? lastSavedDeviceId;

  EventObjectBox({
    required this.id,
    required this.year,
    required this.month,
    required this.day,
    required this.eventType,
    required this.createdAt,
    required this.updatedAt,
    required this.permanentlyDeletedAt,
    this.lastSavedDeviceId,
  });

  @override
  void toPermanentlyDeleted({
    DateTime? deletedAt,
  }) {
    updatedAt = DateTime.now();
    permanentlyDeletedAt = deletedAt ?? DateTime.now();
  }

  @override
  void touch() {
    updatedAt = DateTime.now();
  }
}

@Entity()
class PreferenceObjectBox extends BaseObjectBox {
  @Id(assignable: true)
  int id;
  String key;
  String value;

  @override
  @Property(type: PropertyType.date)
  DateTime createdAt;

  @override
  @Property(type: PropertyType.date)
  DateTime updatedAt;

  @override
  @Property(type: PropertyType.date)
  DateTime? permanentlyDeletedAt;

  @override
  String? lastSavedDeviceId;

  PreferenceObjectBox({
    required this.id,
    required this.key,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
    this.lastSavedDeviceId,
    this.permanentlyDeletedAt,
  });

  @override
  void toPermanentlyDeleted({
    DateTime? deletedAt,
  }) {
    updatedAt = DateTime.now();
    permanentlyDeletedAt = deletedAt ?? DateTime.now();
  }

  @override
  void touch() {
    updatedAt = DateTime.now();
  }
}

@Entity()
class TemplateObjectBox extends BaseObjectBox {
  @Id(assignable: true)
  int id;
  int index;
  List<int>? tags;
  String? name;
  String? content;
  String? note;

  @Index()
  String? galleryTemplateId;
  String? preferences;

  @override
  @Property(type: PropertyType.date)
  DateTime createdAt;

  @override
  @Property(type: PropertyType.date)
  DateTime updatedAt;

  @Property(type: PropertyType.date)
  @Index()
  DateTime? archivedAt;

  @override
  @Property(type: PropertyType.date)
  DateTime? permanentlyDeletedAt;

  @override
  String? lastSavedDeviceId;

  TemplateObjectBox({
    required this.id,
    required this.index,
    required this.name,
    required this.content,
    required this.note,
    required this.galleryTemplateId,
    required this.preferences,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
    required this.permanentlyDeletedAt,
    this.lastSavedDeviceId,
  });

  @override
  void toPermanentlyDeleted({
    DateTime? deletedAt,
  }) {
    updatedAt = DateTime.now();
    permanentlyDeletedAt = deletedAt ?? DateTime.now();
  }

  @override
  void touch() {
    updatedAt = DateTime.now();
  }
}

@Entity()
class RelaxSoundMixBox extends BaseObjectBox {
  @Id(assignable: true)
  int id;
  int index;

  String name;
  String sounds;

  @override
  @Property(type: PropertyType.date)
  DateTime createdAt;

  @override
  @Property(type: PropertyType.date)
  DateTime updatedAt;

  @override
  @Property(type: PropertyType.date)
  DateTime? permanentlyDeletedAt;

  @override
  String? lastSavedDeviceId;

  RelaxSoundMixBox({
    required this.id,
    required this.index,
    required this.name,
    required this.sounds,
    required this.createdAt,
    required this.updatedAt,
    required this.permanentlyDeletedAt,
    this.lastSavedDeviceId,
  });

  @override
  void toPermanentlyDeleted({
    DateTime? deletedAt,
  }) {
    updatedAt = DateTime.now();
    permanentlyDeletedAt = deletedAt ?? DateTime.now();
  }

  @override
  void touch() {
    updatedAt = DateTime.now();
  }
}
