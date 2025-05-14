part of '../stories_box.dart';

// TODO: remove this method when ready.
// This is a low level method to make sure view get rich pages instead of pages when using.
StoryContentDbModel _convertPagesToRichPages(StoryContentDbModel content) {
  // ignore: deprecated_member_use_from_same_package
  if (content.pages != null) {
    final now = DateTime.now().millisecondsSinceEpoch;
    content = content.copyWith(
      pages: null,
      richPages: List.generate(
        // ignore: deprecated_member_use_from_same_package
        content.pages?.length ?? 0,
        (index) => StoryPageDbModel(
          id: now + index,
          title: index == 0 ? content.title : null,
          // ignore: deprecated_member_use_from_same_package
          body: content.pages![index],
        ),
      ),
    );
  }

  return content;
}

StoryContentDbModel _stringToContent(String str) {
  String decoded = HtmlCharacterEntities.decode(str);
  dynamic json = jsonDecode(decoded);

  StoryContentDbModel content = StoryContentDbModel.fromJson(json);
  return _convertPagesToRichPages(content);
}

String _contentToString(StoryContentDbModel content) {
  Map<String, dynamic> json = content.toJson();
  String encoded = jsonEncode(json);
  return HtmlCharacterEntities.encode(encoded);
}

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
    preferences: decodePreferences(object),
    latestContent: object.latestContent != null ? _stringToContent(object.latestContent!) : null,
    draftContent: object.draftContent != null ? _stringToContent(object.draftContent!) : null,
    movedToBinAt: object.movedToBinAt,
    lastSavedDeviceId: object.lastSavedDeviceId,
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
    metadata: story.latestContent?.safeMetadata,
    latestContent: story.latestContent != null ? _contentToString(story.latestContent!) : null,
    draftContent: story.draftContent != null ? _contentToString(story.draftContent!) : null,
    changes: [],
    permanentlyDeletedAt: null,
    preferences: jsonEncode(story.preferences.toNonNullJson()),
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
