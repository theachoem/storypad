import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/services/location/sp_location_service.dart';
import 'package:storypad/core/services/messenger_service.dart';

/// App-level (UI) location flow for user-triggered actions.
///
/// This service is responsible for permission-recovery UX (dialogs/snackbar),
/// while [SpLocationService] remains a core data/service layer with no UI.
class SpAppLocationService {
  const SpAppLocationService._();

  /// Requests current place with retry/settings UX and returns a resolved place.
  ///
  /// Returns `null` when the user cancels recovery or location still cannot be resolved.
  static Future<PlaceDbModel?> fetchCurrentPlaceWithRecovery(BuildContext context) async {
    while (context.mounted) {
      final result = await SpLocationService.fetchCurrentPlaceResult();
      if (!context.mounted) return null;

      switch (result.status) {
        case SpLocationFetchStatus.success:
          return result.place;
        case SpLocationFetchStatus.denied:
          final action = await showOkCancelAlertDialog(
            context: context,
            title: 'Location access needed',
            message: 'We need location permission to move the map to your current location.',
            okLabel: 'Retry',
            cancelLabel: 'Not now',
            defaultType: OkCancelAlertDefaultType.ok,
          );

          if (action != OkCancelResult.ok) return null;
          continue;
        case SpLocationFetchStatus.deniedForever:
          final action = await showOkCancelAlertDialog(
            context: context,
            title: 'Location access is turned off',
            message: 'Enable location permission in Settings to use current location.',
            okLabel: 'Open Settings',
            cancelLabel: 'Not now',
            defaultType: OkCancelAlertDefaultType.ok,
          );

          if (action != OkCancelResult.ok) return null;
          await SpLocationService.openAppSettings();
          continue;
        case SpLocationFetchStatus.serviceDisabled:
          final action = await showOkCancelAlertDialog(
            context: context,
            title: 'Location services are off',
            message: 'Turn on location services to use current location.',
            okLabel: 'Open Location Settings',
            cancelLabel: 'Not now',
            defaultType: OkCancelAlertDefaultType.ok,
          );

          if (action != OkCancelResult.ok) return null;
          await SpLocationService.openLocationSettings();
          continue;
        case SpLocationFetchStatus.failed:
          MessengerService.of(context).showSnackBar(
            'Could not get current location. Please try again.',
            success: false,
          );
          return null;
      }
    }

    return null;
  }
}
