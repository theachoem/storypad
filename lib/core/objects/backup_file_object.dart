import 'package:flutter/foundation.dart';
import 'package:storypad/core/objects/device_info_object.dart';

class BackupFileObject {
  static const String prefix = "Backup";
  static const String splitBy = "::";

  final DateTime createdAt;
  final String version;
  final DeviceInfoObject device;
  final int? year; // For v3 yearly backups

  bool sameDayAs(BackupFileObject fileInfo) {
    return [createdAt.year, createdAt.month, createdAt.day].join("-") ==
        [fileInfo.createdAt.year, fileInfo.createdAt.month, fileInfo.createdAt.day].join("-");
  }

  BackupFileObject({
    required this.createdAt,
    required this.device,
    String? version,
    this.year,
  }) : version = version ?? (year != null ? '3' : '2');

  bool? get hasCompression => version == '2' || version == '3';

  // v3: Backup::3::2025::1734350000000::iPhone 15 Pro::iPhone123.zip (year-based)
  // v2: Backup::2::1731680400000::iPhone 15 Pro::ABC123.zip (legacy)
  // v1: Backup::v1::2022-06-14T17:44:47.097469::Pixel 5.json (legacy)
  String get fileName {
    if (version == '3') {
      if (year == null) {
        throw ArgumentError('Year is required for v3 backups');
      }

      return <String>[
        prefix,
        version,
        year.toString(),
        createdAt.millisecondsSinceEpoch.toString(),
        device.model,
        device.id,
      ].join(splitBy);
    }

    // Legacy v1/v2 format
    return <String>[
      prefix,
      version,
      createdAt.millisecondsSinceEpoch.toString(),
      device.model,
      device.id,
    ].join(splitBy);
  }

  String get fileNameWithExtention {
    if (version == '1') {
      return "$fileName.json";
    } else {
      return "$fileName.zip";
    }
  }

  static BackupFileObject? fromFileName(String fileName) {
    if (fileName.endsWith(".zip")) fileName = fileName.replaceAll(".zip", "");
    if (fileName.endsWith(".json")) fileName = fileName.replaceAll(".json", "");

    List<String> value = fileName.trim().split(splitBy);

    if (value.isNotEmpty) {
      String? version = value.length > 1 ? value[1] : null;

      switch (version) {
        case "3":
          // v3: Backup::3::2025::1734350000000::iPhone 15 Pro::iPhone123
          try {
            int year = int.parse(value[2]);
            int millisecondsEpoch = int.parse(value[3]);
            DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(millisecondsEpoch);
            String deviceModel = value[4];
            String deviceId = value[5];

            return BackupFileObject(
              createdAt: createdAt,
              device: DeviceInfoObject(model: deviceModel, id: deviceId),
              version: version!,
              year: year,
            );
          } catch (e) {
            debugPrint("ERROR: fromFileName v3 parse error: $e");
          }
          break;
        case "2":
        case "1":
          // v2: Backup::2::1731680400000::iPhone 15 Pro::ABC123
          // v1: Backup::1::1731680400000::Pixel 5::ABC123
          try {
            int millisecondsEpoch = int.parse(value[2]);
            DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(millisecondsEpoch);
            String deviceModel = value[3];
            String deviceId = value[4];
            return BackupFileObject(
              createdAt: createdAt,
              device: DeviceInfoObject(model: deviceModel, id: deviceId),
              version: version!,
            );
          } catch (e) {
            debugPrint("ERROR: fromFileName $e");
          }
          break;
        default:
          return null;
      }
    }
    return null;
  }
}
