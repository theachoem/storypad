import 'dart:io' show Platform;

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/widgets/sp_icons.dart';

/// Opens a spot in a maps app: Apple Maps or Google Maps (asks which on iOS/macOS),
/// Google Maps elsewhere.
class MapAppOpenerService {
  const MapAppOpenerService._();

  static Future<void> open(BuildContext context, SpLatLng latLng) async {
    final actions = [
      if (Platform.isIOS || Platform.isMacOS)
        SheetAction(
          label: tr("button.open_in_args", namedArgs: {"OPENEE_NAME": "Apple Maps"}),
          icon: SpIcons.apple,
          key: "apple",
        ),
      SheetAction(
        label: tr("button.open_in_args", namedArgs: {"OPENEE_NAME": "Google Maps"}),
        icon: SpIcons.googleMaps,
        key: "google",
      ),
    ];

    final result = actions.length == 1
        ? actions.first.key
        : await showModalActionSheet(context: context, actions: actions);
    if (!context.mounted) return;

    final latitude = latLng.latitude;
    final longitude = latLng.longitude;

    switch (result) {
      case "apple":
        UrlOpenerService.openInCustomTab(
          context,
          "https://maps.apple.com/?ll=$latitude,$longitude",
          prefersDeepLink: Platform.isIOS,
        );
      case "google":
        UrlOpenerService.openInCustomTab(
          context,
          "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude",
          prefersDeepLink: Platform.isAndroid,
        );
    }
  }
}
