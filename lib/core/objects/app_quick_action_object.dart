import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_quick_action_object.g.dart';

enum AppQuickActionType { defaultAction, template, tag }

enum AppQuickActionTemplateType { custom, gallery }

enum AppDefaultQuickActionType {
  newStory('new_story'),
  takePhoto('take_photo'),
  recordVoice('record_voice'),
  editShortcuts('edit_shortcuts'),
  ;

  const AppDefaultQuickActionType(this.id);

  final String id;

  String get nativeIcon => switch (this) {
    AppDefaultQuickActionType.newStory => 'qa_new_story',
    AppDefaultQuickActionType.takePhoto => 'qa_take_photo',
    AppDefaultQuickActionType.recordVoice => 'qa_record_voice',
    AppDefaultQuickActionType.editShortcuts => 'qa_new_story',
  };

  static AppDefaultQuickActionType? fromId(String id) {
    for (final action in values) {
      if (action.id == id) return action;
    }
    return null;
  }
}

@JsonSerializable()
class AppQuickActionTemplateReference {
  const AppQuickActionTemplateReference({
    required this.type,
    required this.id,
  });

  final AppQuickActionTemplateType type;
  final String id;

  factory AppQuickActionTemplateReference.fromJson(Map<String, dynamic> json) =>
      _$AppQuickActionTemplateReferenceFromJson(json);
  Map<String, dynamic> toJson() => _$AppQuickActionTemplateReferenceToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AppQuickActionObject {
  static const String templateNativeIcon = 'qa_template';
  static const String tagNativeIcon = 'qa_tag';

  const AppQuickActionObject({
    required this.label,
    required this.type,
    this.nativeIcon,
    this.defaultActionType,
    this.templateReference,
    this.tagId,
  });

  final String label;

  @JsonKey(unknownEnumValue: AppQuickActionType.defaultAction)
  final AppQuickActionType type;
  final String? nativeIcon;

  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final AppDefaultQuickActionType? defaultActionType;
  final AppQuickActionTemplateReference? templateReference;
  final int? tagId;

  /// OS shortcut key — base64Url-encoded JSON of the full object including label.
  String toId() => base64Url.encode(utf8.encode(jsonEncode(toJson())));

  /// Logical identity used for dedup and equality — not stored in JSON.
  String get key => switch (type) {
    AppQuickActionType.defaultAction => defaultActionType?.id ?? '',
    AppQuickActionType.template =>
      templateReference != null ? 'template:${templateReference!.type.name}:${templateReference!.id}' : '',
    AppQuickActionType.tag => tagId != null ? 'tag:$tagId' : '',
  };

  static AppQuickActionObject? tryFromId(String id) {
    try {
      final json = jsonDecode(utf8.decode(base64Url.decode(id))) as Map<String, dynamic>;
      return AppQuickActionObject.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // Predefined default action for editing shortcuts, used when no user-defined shortcuts exist.
  factory AppQuickActionObject.editShortcuts() {
    return AppQuickActionObject(
      label: tr('button.edit_app_shortcuts'),
      type: AppQuickActionType.defaultAction,
      nativeIcon: AppDefaultQuickActionType.editShortcuts.nativeIcon,
      defaultActionType: AppDefaultQuickActionType.editShortcuts,
    );
  }

  factory AppQuickActionObject.fromJson(Map<String, dynamic> json) => _$AppQuickActionObjectFromJson(json);
  Map<String, dynamic> toJson() => _$AppQuickActionObjectToJson(this);
}
