import 'dart:convert';

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/objects/cloud_service_user.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';

part 'nextcloud_user_object.g.dart';

@CopyWith()
@JsonSerializable()
class NextcloudUserObject extends CloudServiceUser {
  /// Kept here (rather than only in `NextcloudCloudService`) since
  /// [destinationKey] needs it too, without an object → service dependency.
  static const String defaultFolderName = 'StoryPad';

  final String serverUrl;
  final String username;
  final String appPassword;

  /// Relative path under the account's WebDAV root where StoryPad stores its
  /// data — defaults to [defaultFolderName] when null, so existing connected
  /// users are unaffected. Only settable at initial connect; sanitized in
  /// `NextcloudCloudService.connect`.
  final String? folderName;

  @override
  String? get displayName => identifier;

  @override
  String? get photoUrl => null;

  @override
  final bool? autoBackupEnabled;

  @override
  BackupServiceType get serviceType => BackupServiceType.nextcloud;

  NextcloudUserObject({
    required this.serverUrl,
    required this.username,
    required this.appPassword,
    required this.autoBackupEnabled,
    this.folderName,
  });

  /// Host (with port, if any) but no scheme — e.g. `example.com`,
  /// `192.168.1.5:8080`. Falls back to the raw [serverUrl] if it doesn't
  /// parse as a URL with an authority (shouldn't happen in practice: the
  /// connect flow always requires a full URL to actually reach the server).
  String get _hostWithPort {
    final uri = Uri.tryParse(serverUrl);
    if (uri == null || uri.host.isEmpty) return serverUrl;
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }

  /// `localhost` or a bare IP isn't a stable, globally-unique host the way a
  /// real domain is — a different self-hosted install could reuse the same
  /// LAN IP or `localhost`, so [globalId] must not treat it as one.
  bool get _isLocalOrIpHost {
    final host = Uri.tryParse(serverUrl)?.host ?? '';
    if (host.isEmpty) return false;
    if (host == 'localhost') return true;
    if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host)) return true; // IPv4
    if (host.contains(':')) return true; // IPv6 literal
    return false;
  }

  /// Host[:port] only, no scheme — e.g. `admin@example.com`,
  /// `admin@192.168.1.5:8080`. The port is kept (unlike the scheme) because
  /// cloudDestinations/import-history are keyed by this value, and two
  /// distinct self-hosted instances can share a LAN IP on different ports.
  @override
  String get identifier => '$username@$_hostWithPort';

  /// Self-hosted instances aren't a single globally-unique account space the way
  /// Google's is, so this is scoped to serviceType+identifier rather than a bare
  /// account ID — and null entirely for a localhost/bare-IP host, which isn't
  /// unique across different installs at all.
  @override
  String? get globalId {
    if (!serviceType.hasGlobalUserId || _isLocalOrIpHost) return null;
    return "${serviceType.id}_$identifier";
  }

  /// [identifier] alone can't distinguish two different storage folders under
  /// the *same* account — e.g. disconnecting and reconnecting to fold assets
  /// into a different folder. Always folds in the effective folder (falling
  /// back to [defaultFolderName]) so every account has one consistent key
  /// format, rather than branching on whether it happens to match the
  /// default.
  @override
  String get destinationKey => '$identifier/${folderName ?? defaultFolderName}';

  /// Deliberately excludes [appPassword] — this is rendered as plain text on
  /// the service's detail screen, never a place for secrets.
  @override
  List<({String label, String value})> get configuration => [
    (label: tr("input.nextcloud_folder_name.hint"), value: "~/${folderName ?? defaultFolderName}"),
  ];

  Map<String, String> get authHeaders {
    final credentials = base64Encode(utf8.encode('$username:$appPassword'));
    return <String, String>{
      'Authorization': 'Basic $credentials',
    };
  }

  Map<String, dynamic> toJson() => _$NextcloudUserObjectToJson(this);
  factory NextcloudUserObject.fromJson(Map<String, dynamic> json) => _$NextcloudUserObjectFromJson(json);
}
