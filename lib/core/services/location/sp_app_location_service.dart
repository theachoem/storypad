import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart' show tr;
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
            title: tr("dialog.location_access_needed.title"),
            message: tr("dialog.location_access_needed.message"),
            okLabel: tr("button.retry"),
            cancelLabel: tr("button.maybe_later"),
            defaultType: OkCancelAlertDefaultType.ok,
          );

          if (action != OkCancelResult.ok) return null;
          continue;
        case SpLocationFetchStatus.deniedForever:
          final action = await showOkCancelAlertDialog(
            context: context,
            title: tr("dialog.location_access_turned_off.title"),
            message: tr("dialog.location_access_turned_off.message"),
            okLabel: tr("button.open_settings"),
            cancelLabel: tr("button.maybe_later"),
            defaultType: OkCancelAlertDefaultType.ok,
          );

          if (action != OkCancelResult.ok) return null;
          await SpLocationService.openAppSettings();
          continue;
        case SpLocationFetchStatus.serviceDisabled:
          final action = await showOkCancelAlertDialog(
            context: context,
            title: tr("dialog.location_services_off.title"),
            message: tr("dialog.location_services_off.message"),
            okLabel: tr("button.open_location_settings"),
            cancelLabel: tr("button.maybe_later"),
            defaultType: OkCancelAlertDefaultType.ok,
          );

          if (action != OkCancelResult.ok) return null;
          await SpLocationService.openLocationSettings();
          continue;
        case SpLocationFetchStatus.failed:
          MessengerService.of(context).showSnackBar(
            tr("snack_bar.could_not_get_current_location"),
            success: false,
          );
          return null;
      }
    }

    return null;
  }
}
