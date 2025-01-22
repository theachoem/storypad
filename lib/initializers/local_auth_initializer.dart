import 'package:storypad/core/services/local_auth_service.dart';

class LocalAuthInitializer {
  static Future<void> call() async {
    await LocalAuthService.instance.load();
  }
}
