import 'package:storypad/core/services/analytics/adaptors/base_analytics_user_property_adaptor.dart';

class NoneAnalyticsUserPropertyAdaptor extends BaseAnalyticsUserPropertyAdaptor {
  @override
  Future<void> setUserProperty(String name, String? value) => Future.value();
}
