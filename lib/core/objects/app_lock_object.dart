import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/types/app_lock_question.dart' show AppLockQuestion;

part 'app_lock_object.g.dart';

@CopyWith()
@JsonSerializable()
class AppLockObject {
  final String? pin;
  final bool? enabledBiometric;
  final Map<AppLockQuestion, String>? securityAnswers;

  AppLockObject({
    required this.pin,
    required this.enabledBiometric,
    required this.securityAnswers,
  });

  factory AppLockObject.init() {
    return AppLockObject(
      pin: null,
      enabledBiometric: false,
      securityAnswers: null,
    );
  }

  Map<String, dynamic> toJson() => _$AppLockObjectToJson(this);
  factory AppLockObject.fromJson(Map<String, dynamic> json) => _$AppLockObjectFromJson(json);
}
