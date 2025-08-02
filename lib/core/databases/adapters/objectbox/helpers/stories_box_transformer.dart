part of '../stories_box.dart';

StoryDbModel _objectToModel(Map<String, dynamic> map) {
  StoryObjectBox object = map['object'];
  // Map<String, dynamic>? options = map['options'];

  Iterable<PathType> types = PathType.values.where((e) => e.name == object.type);

  return StoryDbModel(
    version: object.version,
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
    preferences: StoryContentHelper.decodePreferences(object.preferences, showDayCount: object.showDayCount),
    latestContent: object.latestContent != null ? StoryContentHelper.stringToContent(object.latestContent!) : null,
    draftContent: object.draftContent != null ? StoryContentHelper.stringToContent(object.draftContent!) : null,
    movedToBinAt: object.movedToBinAt,
    lastSavedDeviceId: object.lastSavedDeviceId,
    permanentlyDeletedAt: object.permanentlyDeletedAt,
    templateId: object.templateId,
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

  final content = story.draftContent ?? story.latestContent;
  String? searchMetadata = content?.richPages?.map((e) {
    return [e.title, e.plainText].join("\n");
  }).join("\n");

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
    templateId: story.templateId,
    createdAt: story.createdAt,
    updatedAt: story.updatedAt,
    movedToBinAt: story.movedToBinAt,
    metadata: searchMetadata,
    latestContent: story.latestContent != null ? StoryContentHelper.contentToString(story.latestContent!) : null,
    draftContent: story.draftContent != null ? StoryContentHelper.contentToString(story.draftContent!) : null,
    changes: [],
    permanentlyDeletedAt: story.permanentlyDeletedAt,
    preferences: jsonEncode(story.preferences.toNonNullJson()),
  );
}
