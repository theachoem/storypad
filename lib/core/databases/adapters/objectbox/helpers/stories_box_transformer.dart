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
    place: object.place != null ? PlaceDbModel.fromJson(jsonDecode(object.place!)) : null,
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

    // Set search metadata to null so that when open search view, it will be picked up for reindexing.
    searchMetadata: null,

    latestContent: story.latestContent != null ? StoryContentHelper.contentToString(story.latestContent!) : null,
    draftContent: story.draftContent != null ? StoryContentHelper.contentToString(story.draftContent!) : null,
    changes: [],
    eventId: story.eventId,
    wordCount: story.draftContent?.wordCount ?? story.latestContent?.wordCount,
    characterCount: story.draftContent?.characterCount ?? story.latestContent?.characterCount,
    permanentlyDeletedAt: story.permanentlyDeletedAt,
    preferences: jsonEncode(story.preferences.toNonNullJson()),
    latitude: story.place?.latitude,
    longitude: story.place?.longitude,
    placeName: story.place?.placeName,
    place: story.place != null ? jsonEncode(story.place!.toJson()) : null,
  );
}

String? _generateSearchMetadata(
  String? placeName,
  DateTime storyDate,
  StoryContentDbModel? content,
  List<String>? tagLabels,
) {
  if (content == null) return null;

  final tokens = <String>{};

  // Tags
  for (final tag in tagLabels ?? []) {
    final t = tag.trim().toLowerCase();
    if (t.isNotEmpty) tokens.add(t);
  }

  // Place
  if (placeName != null) {
    final p = placeName.trim().toLowerCase();
    if (p.isNotEmpty) tokens.add(p);
  }

  // Title
  if (content.title != null) {
    final t = content.title!.trim().toLowerCase();
    if (t.isNotEmpty) tokens.add(t);
  }

  // Body
  if (content.plainText != null) {
    final b = content.plainText!.trim().toLowerCase();
    if (b.isNotEmpty) tokens.add(b);
  }

  // ---- Extended date tokens ----
  final year = DateFormat('yyyy').format(storyDate); // 2024
  final monthPad = DateFormat('MM').format(storyDate); // 08
  final monthFull = DateFormat('MMMM').format(storyDate).toLowerCase(); // august
  final dayPad = DateFormat('dd').format(storyDate); // 05
  final weekday = DateFormat('EEEE').format(storyDate).toLowerCase(); // monday

  tokens.addAll([
    monthFull,
    weekday,
    '$year-$monthPad-$dayPad', // 2024-08-05 (safe ISO format)
  ]);

  return tokens.isEmpty ? null : tokens.join('\n');
}
