import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/analytics/adaptors/base_analytics_event_adaptor.dart';

// Logging analytics events without user-identifiable information: never user-typed
// text (search queries, tag/person names), coordinates, an entry's date, or which
// links were opened (only our own storypad.me domain is named — see urlAnalyticParameters).
// All high-level methods live in [BaseAnalyticsEventAdaptor]. This class
// preserves the existing call-site API: AnalyticsService.instance.logXxx().
class AnalyticsService {
  AnalyticsService._();

  static BaseAnalyticsEventAdaptor get instance => kAnalyticsService;
}
