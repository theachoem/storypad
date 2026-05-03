import 'dart:io' show Platform;

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';

class SpStoriesBottomSheet extends BaseBottomSheet {
  const SpStoriesBottomSheet({
    required this.filter,
    required this.storyLocation,
  });

  final SearchFilterObject filter;
  final SpLatLng? storyLocation;

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: Scaffold(
        floatingActionButton: storyLocation != null ? _MapAppOpenerButton(storyLocation: storyLocation!) : null,
        body: SpStoryList.withQuery(
          filter: filter,
          disableMultiEdit: true,
        ),
      ),
    );
  }
}

class _MapAppOpenerButton extends StatelessWidget {
  const _MapAppOpenerButton({
    required this.storyLocation,
  });

  final SpLatLng storyLocation;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(CupertinoIcons.map),
      onPressed: () async {
        final actions = [
          if (Platform.isIOS || Platform.isMacOS) ...[
            SheetAction(
              label: tr("button.open_in_args", namedArgs: {"OPENEE_NAME": "Apple Maps"}),
              icon: MdiIcons.apple,
              key: "apple",
            ),
          ],
          SheetAction(
            label: tr("button.open_in_args", namedArgs: {"OPENEE_NAME": "Google Maps"}),
            icon: MdiIcons.googleMaps,
            key: "google",
          ),
        ];

        final result = actions.length == 1
            ? actions.first.key
            : await showModalActionSheet(
                context: context,
                actions: [
                  if (Platform.isIOS || Platform.isMacOS) ...[
                    SheetAction(
                      label: tr("button.open_in_args", namedArgs: {"OPENEE_NAME": "Apple Maps"}),
                      icon: MdiIcons.apple,
                      key: "apple",
                    ),
                  ],
                  SheetAction(
                    label: tr("button.open_in_args", namedArgs: {"OPENEE_NAME": "Google Maps"}),
                    icon: MdiIcons.googleMaps,
                    key: "google",
                  ),
                ],
              );

        if (!context.mounted) return;

        String? url;
        double latitude = storyLocation.latitude;
        double longitude = storyLocation.longitude;

        bool prefersDeepLink = false;

        if (result == "apple") {
          prefersDeepLink = Platform.isIOS;
          url = "https://maps.apple.com/?ll=$latitude,$longitude";
        } else if (result == "google") {
          prefersDeepLink = Platform.isAndroid;
          url = "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
        }

        if (url != null) {
          UrlOpenerService.openInCustomTab(context, url, prefersDeepLink: prefersDeepLink);
        }
      },
    );
  }
}
