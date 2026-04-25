import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/analytics/adaptors/base_analytics_user_property_adaptor.dart';

// Logging user property analytics without user-identifiable information.
// All high-level methods live in [BaseAnalyticsUserPropertyAdaptor]. This class
// preserves the existing call-site API: AnalyticsUserProperyService.instance.logXxx().
class AnalyticsUserProperyService {
  AnalyticsUserProperyService._();

  static BaseAnalyticsUserPropertyAdaptor get instance => kAnalyticsUserPropertyService;
}
