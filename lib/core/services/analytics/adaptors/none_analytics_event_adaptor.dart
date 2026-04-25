import 'package:storypad/core/services/analytics/adaptors/base_analytics_event_adaptor.dart';

class NoneAnalyticsEventAdaptor extends BaseAnalyticsEventAdaptor {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) => Future.value();

  @override
  Future<void> logScreenView({
    required String screenClass,
    required String screenName,
    Map<String, Object>? parameters,
  }) => Future.value();

  @override
  Future<void> logLogin({required String loginMethod}) => Future.value();

  @override
  Future<void> logSearchEvent({required String searchTerm}) => Future.value();
}
