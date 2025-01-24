import 'package:package_info_plus/package_info_plus.dart';

late final PackageInfo kPackageInfo;

final bool kSpooky = kPackageInfo.packageName == 'com.juniorise.spooky';
final bool kStoryPad = kPackageInfo.packageName == 'com.tc.writestory';
final bool kCommunity = kPackageInfo.packageName == 'com.juniorise.spooky.community';

class PackageInfoInitializer {
  static Future<void> call() async {
    kPackageInfo = await PackageInfo.fromPlatform();
  }
}
