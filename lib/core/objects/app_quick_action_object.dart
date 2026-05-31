import 'package:json_annotation/json_annotation.dart';

part 'app_quick_action_object.g.dart';

enum AppDefaultQuickActionType {
  newStory('new_story'),
  takePhoto('take_photo'),
  recordVoice('record_voice'),
  ;

  const AppDefaultQuickActionType(this.id);

  final String id;

  String get nativeIcon => switch (this) {
    AppDefaultQuickActionType.newStory => 'qa_new_story',
    AppDefaultQuickActionType.takePhoto => 'qa_take_photo',
    AppDefaultQuickActionType.recordVoice => 'qa_record_voice',
  };

  static AppDefaultQuickActionType? fromId(String id) {
    for (final action in values) {
      if (action.id == id) return action;
    }

    return null;
  }
}

enum AppQuickActionType { defaultAction, template, tag }

enum AppQuickActionTemplateType { custom, gallery }

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

@JsonSerializable()
class AppQuickActionObject {
  const AppQuickActionObject({
    required this.id,
    required this.label,
    required this.type,
    this.nativeIcon,
  });

  final String id;
  final String label;

  @JsonKey(unknownEnumValue: AppQuickActionType.defaultAction)
  final AppQuickActionType type;
  final String? nativeIcon;

  static String templateId({
    required AppQuickActionTemplateType type,
    required String id,
  }) => 'template:${type.name}:$id';

  static String tagActionId(int tagId) => 'tag:$tagId';

  static const String templateNativeIcon = 'qa_template';
  static const String tagNativeIcon = 'qa_tag';

  static String? nativeIconFor({required AppQuickActionType type, required String id}) {
    return switch (type) {
      AppQuickActionType.defaultAction => AppDefaultQuickActionType.fromId(id)?.nativeIcon,
      AppQuickActionType.template => templateNativeIcon,
      AppQuickActionType.tag => tagNativeIcon,
    };
  }

  AppQuickActionTemplateReference? get templateReference {
    final parts = id.split(':');
    if (parts.length != 3 || parts[0] != 'template') return null;

    try {
      return AppQuickActionTemplateReference.fromJson({
        'type': parts[1],
        'id': parts[2],
      });
    } catch (_) {
      return null;
    }
  }

  int? get tagId {
    if (!id.startsWith('tag:')) return null;
    return int.tryParse(id.replaceFirst('tag:', ''));
  }

  factory AppQuickActionObject.fromJson(Map<String, dynamic> json) => _$AppQuickActionObjectFromJson(json);
  Map<String, dynamic> toJson() => _$AppQuickActionObjectToJson(this);
}
