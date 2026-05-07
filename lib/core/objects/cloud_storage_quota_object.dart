import 'dart:convert';

class CloudStorageQuotaObject {
  final int appUsageInBytes; // App-only usage (backups folder)
  final int? accountUsageInBytes; // Total account usage (null if not supported)
  final int? limitInBytes; // Account quota limit

  const CloudStorageQuotaObject({
    required this.appUsageInBytes,
    this.accountUsageInBytes,
    this.limitInBytes,
  });

  /// Fraction of app storage used relative to account limit (0.0 – 1.0), or null if limit is unknown.
  double? get appFraction => limitInBytes != null && limitInBytes! > 0 ? appUsageInBytes / limitInBytes! : null;

  /// Fraction of total account storage used (0.0 – 1.0), or null if account usage is unknown.
  double? get accountFraction => accountUsageInBytes != null && limitInBytes != null && limitInBytes! > 0
      ? accountUsageInBytes! / limitInBytes!
      : null;

  factory CloudStorageQuotaObject.fromJson(Map<String, dynamic> json) {
    return CloudStorageQuotaObject(
      appUsageInBytes: (json['appUsageInBytes'] as num).toInt(),
      accountUsageInBytes: json['accountUsageInBytes'] != null ? (json['accountUsageInBytes'] as num).toInt() : null,
      limitInBytes: json['limitInBytes'] != null ? (json['limitInBytes'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appUsageInBytes': appUsageInBytes,
      if (accountUsageInBytes != null) 'accountUsageInBytes': accountUsageInBytes,
      if (limitInBytes != null) 'limitInBytes': limitInBytes,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static CloudStorageQuotaObject? tryParseJsonString(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return CloudStorageQuotaObject.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
