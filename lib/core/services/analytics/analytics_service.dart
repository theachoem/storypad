import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/analytics/adaptors/base_analytics_event_adaptor.dart';

// Logging analytics events without user-identifiable information.
// All high-level methods live in [BaseAnalyticsEventAdaptor]. This class
// preserves the existing call-site API: AnalyticsService.instance.logXxx().
class AnalyticsService {
  AnalyticsService._();

  static BaseAnalyticsEventAdaptor get instance => kAnalyticsService;
}
