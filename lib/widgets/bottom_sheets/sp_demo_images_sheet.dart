import 'package:flutter/material.dart';
import 'package:storypad/core/services/cloud_storage/cloud_storage_service.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_demo_images.dart';

/// Generic "preview a feature" sheet: an optional [header] (e.g. an enable
/// switch) above, and an optional [bottom] (e.g. an action button) below, a
/// horizontal carousel of demo screenshots. Callers own what either looks
/// like and does — this sheet only lays them out.
class SpDemoImagesSheet extends BaseBottomSheet {
  const SpDemoImagesSheet({
    required this.demoImages,
    this.header,
    this.bottom,
  });

  final List<String> demoImages;
  final Widget? header;
  final Widget? bottom;

  static const List<String> periodCalendarDemoImages = [
    "/feature_demos/period_calendar/period_calendar_1__1080x2400.jpg",
    "/feature_demos/period_calendar/period_calendar_2__1080x2400.jpg",
    "/feature_demos/period_calendar/period_calendar_3__1080x2400.jpg",
  ];

  static const List<String> relaxSoundDemoImages = [
    "/feature_demos/relax_sounds/relax_sound_1__1080x2400.jpg",
    "/feature_demos/relax_sounds/relax_sound_2__1080x2400.jpg",
    "/feature_demos/relax_sounds/relax_sound_3__1080x2400.jpg",
    "/feature_demos/relax_sounds/relax_sound_4__1080x2400.jpg",
  ];

  static const List<String> icloudSettingsDemoImages = [
    "/feature_demos/icloud/icloud_1__1206x2622.jpg",
    "/feature_demos/icloud/icloud_2__1206x2622.jpg",
    "/feature_demos/icloud/icloud_3__1206x2622.jpg",
  ];

  static const List<String> allDemoImages = [
    ...periodCalendarDemoImages,
    ...relaxSoundDemoImages,
    ...icloudSettingsDemoImages,
  ];

  static void preloadDemoImages() {
    // downloadFile deduplicates requests via completers, so repeated calls are safe.
    for (final urlPath in allDemoImages) {
      CloudStorageService.instance.downloadFile(urlPath);
    }
  }

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return Column(
      mainAxisSize: .min,
      children: [
        if (header case final header?) ...[
          const SizedBox(height: 8),
          header,
          const SizedBox(height: 8),
        ],
        SpDemoImages(
          demoImageUrlPaths: demoImages,
          skeletonCount: demoImages.length,
        ),
        if (bottom case final bottom?) ...[
          const SizedBox(height: 8),
          bottom,
        ],
        SizedBox(height: bottomPadding + 16.0),
      ],
    );
  }
}
