import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_quick_action_object.g.dart';

enum AppQuickActionType { defaultAction, template, tag }

enum AppQuickActionTemplateType { custom, gallery }

enum AppDefaultQuickActionType {
  newStory('new_story'),
  takePhoto('take_photo'),
  recordVideo('record_video'),
  recordVoice('record_voice'),
  editShortcuts('edit_shortcuts'),
  ;

  const AppDefaultQuickActionType(this.id);

  final String id;

  // Android: drawable name from Android Studio's Vector Asset picker (Clip art, default name).
  String get _androidIcon => switch (this) {
    AppDefaultQuickActionType.newStory => 'outline_edit_24',
    AppDefaultQuickActionType.takePhoto => 'outline_photo_camera_24',
    AppDefaultQuickActionType.recordVideo => 'outline_videocam_24',
    AppDefaultQuickActionType.recordVoice => 'outline_keyboard_voice_24',
    AppDefaultQuickActionType.editShortcuts => 'outline_edit_24',
  };

  // iOS: SF Symbol name, matching the imageset folder in Assets.xcassets.
  String get _iosIcon => switch (this) {
    AppDefaultQuickActionType.newStory => 'pencil.and.outline',
    AppDefaultQuickActionType.takePhoto => 'camera',
    AppDefaultQuickActionType.recordVideo => 'video',
    AppDefaultQuickActionType.recordVoice => 'microphone',
    AppDefaultQuickActionType.editShortcuts => 'pencil.and.outline',
  };

  String get nativeIcon => Platform.isIOS ? _iosIcon : _androidIcon;

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
  static String get templateNativeIcon => Platform.isIOS ? 'lightbulb' : 'outline_lightbulb_24';
  static String get tagNativeIcon => Platform.isIOS ? 'tag' : 'outline_sell_24';

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
