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
  id: json['id'] as String,
  label: json['label'] as String,
  type: $enumDecode(
    _$AppQuickActionTypeEnumMap,
    json['type'],
    unknownValue: AppQuickActionType.defaultAction,
  ),
  nativeIcon: json['native_icon'] as String?,
);

Map<String, dynamic> _$AppQuickActionObjectToJson(
  AppQuickActionObject instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'type': _$AppQuickActionTypeEnumMap[instance.type]!,
  'native_icon': instance.nativeIcon,
};

const _$AppQuickActionTypeEnumMap = {
  AppQuickActionType.defaultAction: 'defaultAction',
  AppQuickActionType.template: 'template',
  AppQuickActionType.tag: 'tag',
};
