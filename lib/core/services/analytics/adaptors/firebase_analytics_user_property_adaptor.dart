import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:storypad/core/services/analytics/adaptors/base_analytics_user_property_adaptor.dart';

class FirebaseAnalyticsUserPropertyAdaptor extends BaseAnalyticsUserPropertyAdaptor {
  @override
  Future<void> setUserProperty(String name, String? value) {
    return FirebaseAnalytics.instance.setUserProperty(name: name, value: value);
  }
}
