import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:storypad/core/services/logger/app_logger.dart';

/// Tells whether the current connection is metered, for `MediaSyncOption` gating.
///
/// The app's only `connectivity_plus` caller — swap the package here and nowhere
/// else. Deliberately does not answer "is there internet at all": that's
/// `InternetCheckerService`'s job, and `connectivity_plus` only reports the
/// interface type, not actual reachability.
class NetworkTypeService {
  const NetworkTypeService();

  /// Wi-Fi, ethernet and vpn count as unmetered; mobile does not.
  ///
  /// Fails open — an unknown or errored result returns true, so a detection
  /// failure can never silently stop media from ever backing up. The cost of
  /// being wrong this way is one unexpected upload; the other way is permanent
  /// silent data loss.
  Future<bool> isUnmetered() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.isEmpty) return true;

      // A device can report several interfaces at once (e.g. wifi + vpn).
      // Metered only when mobile is the sole way out.
      return !results.every((result) => result == ConnectivityResult.mobile);
    } catch (e) {
      AppLogger.d('$runtimeType#isUnmetered failed, assuming unmetered: $e');
      return true;
    }
  }
}
