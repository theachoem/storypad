part of '../stories_box.dart';

StoryDbModel _objectToModel(Map<String, dynamic> map) {
  StoryObjectBox object = map['object'];
  Map<String, dynamic>? options = map['options'];

  Iterable<PathType> types = PathType.values.where((e) => e.name == object.type);
  Map<int, EventDbModel> events = options != null && options.containsKey('events') ? options['events'] : {};

  StoryDbModel story = StoryDbModel(
    version: object.version,
    type: types.isNotEmpty ? types.first : PathType.docs,
    id: object.id,
    starred: object.starred,
    pinned: object.pinned,
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
    preferences: StoryContentHelper.decodePreferences(object.preferences),
    latestContent: object.latestContent != null ? StoryContentHelper.stringToContent(object.latestContent!) : null,
    draftContent: object.draftContent != null ? StoryContentHelper.stringToContent(object.draftContent!) : null,
    movedToBinAt: object.movedToBinAt,
    lastSavedDeviceId: object.lastSavedDeviceId,
    permanentlyDeletedAt: object.permanentlyDeletedAt,
    galleryTemplateId: object.galleryTemplateId,
    templateId: object.templateId,
    eventId: object.eventId,
    wordCount: object.wordCount,
    characterCount: object.characterCount,
  );

  return story.copyWith(
    event: events.containsKey(object.eventId) ? events[object.eventId] : null,
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
    pinned: story.pinned,
    feeling: story.feeling,
    galleryTemplateId: story.galleryTemplateId,
    templateId: story.templateId,
    createdAt: story.createdAt,
    updatedAt: story.updatedAt,
    movedToBinAt: story.movedToBinAt,
    searchMetadata: _generateSearchMetadata(story.draftContent ?? story.latestContent),
    latestContent: story.latestContent != null ? StoryContentHelper.contentToString(story.latestContent!) : null,
    draftContent: story.draftContent != null ? StoryContentHelper.contentToString(story.draftContent!) : null,
    changes: [],
    eventId: story.eventId,
    wordCount: story.draftContent?.wordCount ?? story.latestContent?.wordCount,
    characterCount: story.draftContent?.characterCount ?? story.latestContent?.characterCount,
    permanentlyDeletedAt: story.permanentlyDeletedAt,
    preferences: jsonEncode(story.preferences.toNonNullJson()),
  );
}

String? _generateSearchMetadata(StoryContentDbModel? content) {
  if (content == null) return null;

  // This combine first page title, and plain text for other pages.
  // Check StoryContentDbModel#generateBodyPlainText for more details.
  return [
    if (content.title != null) content.title,
    if (content.plainText != null) content.plainText,
  ].join('\n');
}
