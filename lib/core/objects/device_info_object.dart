import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// Device information with Android API level detection.
/// See: https://developer.android.com/guide/topics/manifest/uses-sdk-element
class DeviceInfoObject {
  final String model;
  final String id;
  final int? androidApiLevel;

  DeviceInfoObject({
    required this.model,
    required this.id,
    this.androidApiLevel,
  });

  bool get isAndroid16BaklavaOrAbove => androidApiLevel != null && androidApiLevel! >= 36;
  bool get isAndroid15VanillaIceCreamOrAbove => androidApiLevel != null && androidApiLevel! >= 35;
  bool get isAndroid14UpsideDownCakeOrAbove => androidApiLevel != null && androidApiLevel! >= 34;
  bool get isAndroid13TiramisuOrAbove => androidApiLevel != null && androidApiLevel! >= 33;
  bool get isAndroid12SV2OrAbove => androidApiLevel != null && androidApiLevel! >= 32;
  bool get isAndroid11ROrAbove => androidApiLevel != null && androidApiLevel! >= 30;
  bool get isAndroid10QOrAbove => androidApiLevel != null && androidApiLevel! >= 29;
  bool get isAndroid9POrAbove => androidApiLevel != null && androidApiLevel! >= 28;
  bool get isAndroid9P => androidApiLevel != null && androidApiLevel! == 28;
  bool get isAndroid8OOrAbove => androidApiLevel != null && androidApiLevel! >= 26;
  bool get isAndroid8O => androidApiLevel != null && (androidApiLevel! == 26 || androidApiLevel! == 27);
  bool get isAndroid8OOrBelow => androidApiLevel != null && androidApiLevel! <= 25;
  bool get isAndroid7NOrAbove => androidApiLevel != null && androidApiLevel! >= 24;
  bool get isAndroid7N => androidApiLevel != null && (androidApiLevel! == 24 || androidApiLevel! == 25);
  bool get isAndroid6MOrAbove => androidApiLevel != null && androidApiLevel! >= 23;
  bool get isAndroid5LollipopOrAbove => androidApiLevel != null && androidApiLevel! >= 21;

  static Future<DeviceInfoObject> get() async {
    bool unitTesting = Platform.environment.containsKey('FLUTTER_TEST');
    if (unitTesting) {
      return DeviceInfoObject(
        model: "Device Model",
        id: "device_id",
      );
    }

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? device;
    String? id;
    int? androidApiLevel;

    if (Platform.isIOS) {
      IosDeviceInfo info = await deviceInfo.iosInfo;
      device = info.model;
      id = info.identifierForVendor;
    }

    if (Platform.isAndroid) {
      AndroidDeviceInfo info = await deviceInfo.androidInfo;
      device = info.model;
      id = info.id;
      androidApiLevel = info.version.sdkInt;
    }

    if (Platform.isMacOS) {
      MacOsDeviceInfo info = await deviceInfo.macOsInfo;
      device = info.model;
      id = info.systemGUID;
    }

    if (Platform.isWindows) {
      WindowsDeviceInfo info = await deviceInfo.windowsInfo;
      device = info.computerName;
      id = info.computerName;
    }

    if (Platform.isLinux) {
      LinuxDeviceInfo info = await deviceInfo.linuxInfo;
      device = info.name;
      id = info.machineId;
    }

    return DeviceInfoObject(
      model: device ?? "Unknown",
      id: id ?? "unknown_id",
      androidApiLevel: androidApiLevel,
    );
  }
}
