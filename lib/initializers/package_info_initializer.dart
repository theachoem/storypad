import 'package:package_info_plus/package_info_plus.dart';

late final PackageInfo kPackageInfo;

class PackageInfoInitializer {
  static Future<void> call() async {
    kPackageInfo = await PackageInfo.fromPlatform();
  }
}
