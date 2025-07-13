part of '../relax_sound_mixes_box.dart';

List<RelaxSoundMixModel> _objectsToModels(Map<String, dynamic> options) {
  List<RelaxSoundMixBox> objects = options['objects'];
  return objects.map((object) => _objectToModel({'object': object})).toList();
}

List<RelaxSoundMixBox> _modelsToObjects(Map<String, dynamic> options) {
  List<RelaxSoundMixModel> models = options['models'];
  return models.map((model) => _modelToObject({'model': model})).toList();
}

RelaxSoundMixBox _modelToObject(Map<String, dynamic> options) {
  RelaxSoundMixModel model = options['model'];

  return RelaxSoundMixBox(
    id: model.id,
    index: model.index,
    name: model.name,
    sounds: jsonEncode(model.sounds.map((e) => e.toJson()).toList()),
    createdAt: model.createdAt,
    updatedAt: model.updatedAt,
    lastSavedDeviceId: model.lastSavedDeviceId,
    permanentlyDeletedAt: model.permanentlyDeletedAt,
  );
}

RelaxSoundMixModel _objectToModel(Map<String, dynamic> options) {
  RelaxSoundMixBox object = options['object'];

  List<RelaxSoundModel> sounds = [];
  dynamic result = jsonDecode(object.sounds);

  if (result is List) {
    for (var sound in result) {
      sounds.add(RelaxSoundModel.fromJson(sound as Map<String, dynamic>));
    }
  }

  return RelaxSoundMixModel(
    id: object.id,
    index: object.index,
    name: object.name,
    sounds: sounds,
    createdAt: object.createdAt,
    updatedAt: object.updatedAt,
    lastSavedDeviceId: object.lastSavedDeviceId,
    permanentlyDeletedAt: object.permanentlyDeletedAt,
  );
}
