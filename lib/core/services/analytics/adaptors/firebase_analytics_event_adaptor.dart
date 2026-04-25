import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:storypad/core/services/analytics/adaptors/base_analytics_event_adaptor.dart';

class FirebaseAnalyticsEventAdaptor extends BaseAnalyticsEventAdaptor {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) {
    return FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> logScreenView({
    required String screenClass,
    required String screenName,
    Map<String, Object>? parameters,
  }) {
    return FirebaseAnalytics.instance.logScreenView(
      screenClass: screenClass,
      screenName: screenName,
      parameters: parameters,
    );
  }

  @override
  Future<void> logLogin({required String loginMethod}) {
    return FirebaseAnalytics.instance.logLogin(loginMethod: loginMethod);
  }

  @override
  Future<void> logSearchEvent({required String searchTerm}) {
    return FirebaseAnalytics.instance.logSearch(searchTerm: searchTerm);
  }
}
