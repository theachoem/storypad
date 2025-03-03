part of '../stories_box.dart';

StoryDbModel _objectToModel(Map<String, dynamic> map) {
  StoryObjectBox object = map['object'];
  Map<String, dynamic>? options = map['options'];

  Iterable<PathType> types = PathType.values.where((e) => e.name == object.type);

  return StoryDbModel(
    type: types.isNotEmpty ? types.first : PathType.docs,
    id: object.id,
    starred: object.starred,
    feeling: object.feeling,
    year: object.year,
    month: object.month,
    day: object.day,
    hour: object.hour ?? object.createdAt.hour,
    minute: object.minute ?? object.createdAt.minute,
    second: object.second ?? object.createdAt.second,
    updatedAt: object.updatedAt,
    createdAt: object.createdAt,
    tags: object.tags,
    assets: object.assets,
    preferences: decodePreferences(object),
    rawChanges: object.changes,
    movedToBinAt: object.movedToBinAt,
    lastSavedDeviceId: object.lastSavedDeviceId,
    latestChange: object.changes.isNotEmpty ? StoryRawToChangesService.call([object.changes.last]).first : null,
    allChanges: options?['all_changes'] == true ? StoryRawToChangesService.call(object.changes) : null,
  );
}

List<StoryDbModel> _objectsToModels(Map<String, dynamic> map) {
  List<StoryObjectBox> objects = map['objects'];
  Map<String, dynamic>? options = map['options'];

  List<StoryDbModel> docs = [];
  for (StoryObjectBox object in objects) {
    StoryDbModel json = _objectToModel({
      'object': object,
      'options': options,
    });

    docs.add(json);
  }

  return docs;
}

List<StoryObjectBox> _modelsToObjects(Map<String, dynamic> map) {
  List<StoryDbModel> models = map['models'];
  Map<String, dynamic>? options = map['options'];

  List<StoryObjectBox> docs = [];
  for (StoryDbModel model in models) {
    StoryObjectBox json = _modelToObject({
      'model': model,
      'options': options,
    });

    docs.add(json);
  }

  return docs;
}

StoryObjectBox _modelToObject(Map<String, dynamic> map) {
  StoryDbModel story = map['model'];

  return StoryObjectBox(
    id: story.id,
    version: story.version,
    type: story.type.name,
    year: story.year,
    month: story.month,
    day: story.day,
    hour: story.hour ?? story.createdAt.hour,
    minute: story.minute ?? story.createdAt.minute,
    second: story.second ?? story.createdAt.second,
    tags: story.tags?.map((e) => e.toString()).toList(),
    assets: story.assets?.toSet().toList(),
    starred: story.starred,
    feeling: story.feeling,
    showDayCount: null,
    createdAt: story.createdAt,
    updatedAt: story.updatedAt,
    movedToBinAt: story.movedToBinAt,
    metadata: story.latestChange?.safeMetadata,
    changes: StoryChangesToRawService.call(story),
    permanentlyDeletedAt: null,
    preferences: story.preferences != null ? jsonEncode(story.preferences?.toJson()) : null,
  );
}

StoryPreferencesDbModel decodePreferences(StoryObjectBox object) {
  StoryPreferencesDbModel? preferences;

  if (object.preferences != null) {
    try {
      preferences = StoryPreferencesDbModel.fromJson(jsonDecode(object.preferences!));
    } catch (e) {
      debugPrint(".decodePreferences error: $e");
    }
  }

  preferences ??= StoryPreferencesDbModel.create();
  if (object.showDayCount != null) preferences = preferences.copyWith(showDayCount: object.showDayCount);
  return preferences;
}
