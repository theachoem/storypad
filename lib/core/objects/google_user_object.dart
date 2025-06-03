import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'google_user_object.g.dart';

@CopyWith()
@JsonSerializable()
class GoogleUserObject {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? accessToken;
  final DateTime? refreshedAt;

  GoogleUserObject({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.accessToken,
    required this.refreshedAt,
  });

  String? get bigImageUrl => _maximizeImage(photoUrl);

  String? _maximizeImage(String? imageUrl) {
    if (imageUrl == null) return null;
    String lowQuality = "s96-c";
    String highQuality = "s0";
    return imageUrl.replaceAll(lowQuality, highQuality);
  }

  Map<String, dynamic> toJson() => _$GoogleUserObjectToJson(this);
  factory GoogleUserObject.fromJson(Map<String, dynamic> json) => _$GoogleUserObjectFromJson(json);
}
