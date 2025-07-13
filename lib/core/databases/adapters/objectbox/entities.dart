// ignore_for_file: overridden_fields

import 'package:objectbox/objectbox.dart';
import 'package:storypad/core/constants/app_constants.dart';

abstract class BaseObjectBox<T> {
  void toPermanentlyDeleted();
  void setDeviceId() {
    lastSavedDeviceId = kDeviceInfo.id;
  }

  void touch();

  DateTime? permanentlyDeletedAt;
  String? lastSavedDeviceId;
}

@Entity()
class StoryObjectBox extends BaseObjectBox {
  @Id(assignable: true)
  int id;
  int version;
  String type;

  int year;
  int month;
  int day;
  int? hour;
  int? minute;
  int? second;

  bool? starred;
  String? feeling;

  // deprecated
  // TODO: removed after May 2025
  bool? showDayCount;

  @Property(type: PropertyType.date)
  DateTime createdAt;

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
  // TODO: remove when possible
  List<String> changes;

  List<String>? tags;
  List<int>? assets;

  int? templateId;

  // for query
  String? metadata;
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
    required this.feeling,
    required this.showDayCount,
    required this.createdAt,
    required this.updatedAt,
    required this.movedToBinAt,
    required this.templateId,
    required this.latestContent,
    required this.draftContent,
    @Deprecated('deprecated') required this.changes,
    required this.tags,
    required this.assets,
    required this.metadata,
    required this.preferences,
    this.lastSavedDeviceId,
    this.permanentlyDeletedAt,
  });

  @override
  void toPermanentlyDeleted() {
    updatedAt = DateTime.now();
    permanentlyDeletedAt = DateTime.now();
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
  bool? starred;
  String? emoji;

  @Property(type: PropertyType.date)
  DateTime createdAt;

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
    required this.starred,
    required this.emoji,
    required this.createdAt,
    required this.updatedAt,
    this.lastSavedDeviceId,
    this.permanentlyDeletedAt,
  });

  @override
  void toPermanentlyDeleted() {
    updatedAt = DateTime.now();
    permanentlyDeletedAt = DateTime.now();
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

  @Property(type: PropertyType.date)
  DateTime createdAt;

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
    this.lastSavedDeviceId,
    this.permanentlyDeletedAt,
  });

  @override
  void toPermanentlyDeleted() {
    updatedAt = DateTime.now();
    permanentlyDeletedAt = DateTime.now();
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

  @Property(type: PropertyType.date)
  DateTime createdAt;

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
  void toPermanentlyDeleted() {
    updatedAt = DateTime.now();
    permanentlyDeletedAt = DateTime.now();
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
  String? content;
  String? preferences;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  @override
  @Property(type: PropertyType.date)
  DateTime? permanentlyDeletedAt;

  @override
  String? lastSavedDeviceId;

  TemplateObjectBox({
    required this.id,
    required this.index,
    required this.content,
    required this.preferences,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.lastSavedDeviceId,
    this.permanentlyDeletedAt,
  });

  @override
  void toPermanentlyDeleted() {
    updatedAt = DateTime.now();
    permanentlyDeletedAt = DateTime.now();
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

  @Property(type: PropertyType.date)
  DateTime createdAt;

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
    this.lastSavedDeviceId,
    this.permanentlyDeletedAt,
  });

  @override
  void toPermanentlyDeleted() {
    updatedAt = DateTime.now();
    permanentlyDeletedAt = DateTime.now();
  }

  @override
  void touch() {
    updatedAt = DateTime.now();
  }
}
