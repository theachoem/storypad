// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_quick_action_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppQuickActionTemplateReference _$AppQuickActionTemplateReferenceFromJson(
  Map<String, dynamic> json,
) => AppQuickActionTemplateReference(
  type: $enumDecode(_$AppQuickActionTemplateTypeEnumMap, json['type']),
  id: json['id'] as String,
);

Map<String, dynamic> _$AppQuickActionTemplateReferenceToJson(
  AppQuickActionTemplateReference instance,
) => <String, dynamic>{
  'type': _$AppQuickActionTemplateTypeEnumMap[instance.type]!,
  'id': instance.id,
};

const _$AppQuickActionTemplateTypeEnumMap = {
  AppQuickActionTemplateType.custom: 'custom',
  AppQuickActionTemplateType.gallery: 'gallery',
};

AppQuickActionObject _$AppQuickActionObjectFromJson(
  Map<String, dynamic> json,
) => AppQuickActionObject(
  label: json['label'] as String,
  type: $enumDecode(
    _$AppQuickActionTypeEnumMap,
    json['type'],
    unknownValue: AppQuickActionType.defaultAction,
  ),
  nativeIcon: json['native_icon'] as String?,
  defaultActionType: $enumDecodeNullable(
    _$AppDefaultQuickActionTypeEnumMap,
    json['default_action_type'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  templateReference: json['template_reference'] == null
      ? null
      : AppQuickActionTemplateReference.fromJson(
          json['template_reference'] as Map<String, dynamic>,
        ),
  tagId: (json['tag_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$AppQuickActionObjectToJson(
  AppQuickActionObject instance,
) => <String, dynamic>{
  'label': instance.label,
  'type': _$AppQuickActionTypeEnumMap[instance.type]!,
  'native_icon': instance.nativeIcon,
  'default_action_type':
      _$AppDefaultQuickActionTypeEnumMap[instance.defaultActionType],
  'template_reference': instance.templateReference?.toJson(),
  'tag_id': instance.tagId,
};

const _$AppQuickActionTypeEnumMap = {
  AppQuickActionType.defaultAction: 'defaultAction',
  AppQuickActionType.template: 'template',
  AppQuickActionType.tag: 'tag',
};

const _$AppDefaultQuickActionTypeEnumMap = {
  AppDefaultQuickActionType.newStory: 'newStory',
  AppDefaultQuickActionType.takePhoto: 'takePhoto',
  AppDefaultQuickActionType.recordVoice: 'recordVoice',
  AppDefaultQuickActionType.editShortcuts: 'editShortcuts',
};
