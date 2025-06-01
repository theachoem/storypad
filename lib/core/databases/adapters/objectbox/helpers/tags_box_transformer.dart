part of '../tags_box.dart';

List<TagDbModel> _objectsToModels(Map<String, dynamic> options) {
  List<TagObjectBox> objects = options['objects'];
  return objects.map((object) => _objectToModel({'object': object})).toList();
}

List<TagObjectBox> _modelsToObjects(Map<String, dynamic> options) {
  List<TagDbModel> models = options['models'];
  return models.map((model) => _modelToObject({'model': model})).toList();
}

TagObjectBox _modelToObject(Map<String, dynamic> options) {
  TagDbModel model = options['model'];

  return TagObjectBox(
    id: model.id,
    title: model.title,
    index: model.index,
    version: model.version,
    starred: model.starred,
    emoji: model.emoji,
    createdAt: model.createdAt,
    updatedAt: model.updatedAt,
    lastSavedDeviceId: model.lastSavedDeviceId,
    permanentlyDeletedAt: model.permanentlyDeletedAt,
  );
}

TagDbModel _objectToModel(Map<String, dynamic> options) {
  TagObjectBox object = options['object'];

  return TagDbModel(
    id: object.id,
    version: object.version,
    index: object.index,
    title: object.title,
    starred: object.starred,
    emoji: object.emoji,
    createdAt: object.createdAt,
    updatedAt: object.updatedAt,
    lastSavedDeviceId: object.lastSavedDeviceId,
    permanentlyDeletedAt: object.permanentlyDeletedAt,
  );
}
