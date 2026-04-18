part of '../tag_categories_box.dart';

List<TagCategoryDbModel> _objectsToModels(Map<String, dynamic> options) {
  List<TagCategoryObjectBox> objects = options['objects'];
  return objects.map((object) => _objectToModel({'object': object})).toList();
}

List<TagCategoryObjectBox> _modelsToObjects(Map<String, dynamic> options) {
  List<TagCategoryDbModel> models = options['models'];
  return models.map((model) => _modelToObject({'model': model})).toList();
}

TagCategoryObjectBox _modelToObject(Map<String, dynamic> options) {
  TagCategoryDbModel model = options['model'];

  return TagCategoryObjectBox(
    id: model.id,
    title: model.title,
    multiSelect: model.multiSelect,
    system: model.system,
    index: model.index,
    version: model.version,
    createdAt: model.createdAt,
    updatedAt: model.updatedAt,
    lastSavedDeviceId: model.lastSavedDeviceId,
    permanentlyDeletedAt: model.permanentlyDeletedAt,
  );
}

TagCategoryDbModel _objectToModel(Map<String, dynamic> options) {
  TagCategoryObjectBox object = options['object'];

  return TagCategoryDbModel(
    id: object.id,
    version: object.version,
    index: object.index,
    title: object.title,
    multiSelect: object.multiSelect,
    createdAt: object.createdAt,
    updatedAt: object.updatedAt,
    lastSavedDeviceId: object.lastSavedDeviceId,
    permanentlyDeletedAt: object.permanentlyDeletedAt,
  );
}
