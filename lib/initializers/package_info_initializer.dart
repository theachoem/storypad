import 'package:package_info_plus/package_info_plus.dart';
import 'package:storypad/core/constants/app_constants.dart';

class PackageInfoInitializer {
  static Future<void> call() async {
    kPackageInfo = await PackageInfo.fromPlatform();
  }
}
