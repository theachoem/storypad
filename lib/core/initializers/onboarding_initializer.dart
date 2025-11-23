import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/storages/onboarded_storage.dart';

// initialize after database.
class OnboardingInitializer {
  static bool? _onboarded;
  static bool _isNewUser = true;

  static bool get isNewUser => _isNewUser;
  static bool? get onboarded => _onboarded;

  static Future<void> call() async {
    final storage = OnboardedStorage();
    _onboarded = await storage.read();

    String? nickname = PreferenceDbModel.db.nickname.get();
    _isNewUser = nickname == null || nickname.trim().isEmpty;
  }
}
