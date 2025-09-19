part of '../templates_box.dart';

List<TemplateDbModel> _objectsToModels(Map<String, dynamic> options) {
  List<TemplateObjectBox> objects = options['objects'];
  return objects.map((object) => _objectToModel({'object': object})).toList();
}

List<TemplateObjectBox> _modelsToObjects(Map<String, dynamic> options) {
  List<TemplateDbModel> models = options['models'];
  return models.map((model) => _modelToObject({'model': model})).toList();
}

TemplateObjectBox _modelToObject(Map<String, dynamic> options) {
  TemplateDbModel model = options['model'];

  return TemplateObjectBox(
    id: model.id,
    content: model.content != null ? StoryContentHelper.contentToString(model.content!) : null,
    index: model.index,
    tags: model.tags?.isNotEmpty == true ? model.tags : null,
    createdAt: model.createdAt,
    updatedAt: model.updatedAt,
    archivedAt: model.archivedAt,
    lastSavedDeviceId: model.lastSavedDeviceId,
    permanentlyDeletedAt: model.permanentlyDeletedAt,
    preferences: jsonEncode(model.preferences.toNonNullJson()),
  );
}

TemplateDbModel _objectToModel(Map<String, dynamic> options) {
  TemplateObjectBox object = options['object'];

  return TemplateDbModel(
    id: object.id,
    content: object.content != null ? StoryContentHelper.stringToContent(object.content!) : null,
    index: object.index,
    tags: object.tags?.isNotEmpty == true ? object.tags : null,
    createdAt: object.createdAt,
    updatedAt: object.updatedAt,
    archivedAt: object.archivedAt,
    lastSavedDeviceId: object.lastSavedDeviceId,
    permanentlyDeletedAt: object.permanentlyDeletedAt,
    preferences: StoryContentHelper.decodePreferences(object.preferences),
  );
}
