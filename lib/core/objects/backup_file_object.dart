import 'package:flutter/foundation.dart';
import 'package:storypad/core/objects/device_info_object.dart';

class BackupFileObject {
  static const String prefix = "Backup";
  static const String splitBy = "::";

  final DateTime createdAt;
  final String version;
  final DeviceInfoObject device;

  bool sameDayAs(BackupFileObject fileInfo) {
    return [createdAt.year, createdAt.month, createdAt.day].join("-") ==
        [fileInfo.createdAt.year, fileInfo.createdAt.month, fileInfo.createdAt.day].join("-");
  }

  BackupFileObject({
    required this.createdAt,
    required this.device,
    this.version = '2',
  });

  bool? get hasCompression => version == '2';

  // v1: Backup::v1::2022-06-14T17:44:47.097469::Pixel 5.json
  String get fileName {
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
        case "1":
        case "2":
          try {
            int millisecondsEpoch = int.parse(value[2]);
            DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(millisecondsEpoch);
            String deviceModel = value[3];
            String deviceId = value[4];
            return BackupFileObject(
              createdAt: createdAt,
              device: DeviceInfoObject(deviceModel, deviceId),
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
