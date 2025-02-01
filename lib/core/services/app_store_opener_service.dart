import 'package:in_app_review/in_app_review.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/initializers/package_info_initializer.dart';

class AppStoreOpenerService {
  static Future<void> call() async {
    final InAppReview inAppReview = InAppReview.instance;

    Future<void> openStore() async {
      String deeplink = 'market://details?id=${kPackageInfo.packageName}';
      bool launched = await UrlOpenerService.launchUrlString(deeplink);
      if (launched) return;
      await inAppReview.openStoreListing();
    }

    await openStore();
  }
}
