import 'package:flutter/material.dart';
import 'package:storypad/core/services/cloud_storage/cloud_storage_service.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_demo_images.dart';

/// Generic "preview a feature" sheet: an optional [header] (e.g. an enable
/// switch) above a horizontal carousel of demo screenshots. Callers own what
/// the header looks like and what it toggles — this sheet only lays it out.
class SpDemoImagesSheet extends BaseBottomSheet {
  const SpDemoImagesSheet({
    required this.demoImages,
    this.header,
  });

  final List<String> demoImages;
  final Widget? header;

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

  static const List<String> allDemoImages = [
    ...periodCalendarDemoImages,
    ...relaxSoundDemoImages,
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
        SizedBox(height: bottomPadding),
      ],
    );
  }
}
