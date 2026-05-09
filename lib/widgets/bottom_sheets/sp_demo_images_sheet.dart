import 'package:flutter/material.dart';
import 'package:storypad/core/services/cloud_storage/cloud_storage_service.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_demo_images.dart';

class SpDemoImagesSheet extends BaseBottomSheet {
  const SpDemoImagesSheet({
    required this.demoImages,
  });

  static const List<String> periodCalendarDemoImages = [
    "/feature_demos/period_calendar/period_calendar_1.jpg",
    "/feature_demos/period_calendar/period_calendar_2.jpg",
    "/feature_demos/period_calendar/period_calendar_3.jpg",
  ];

  static const List<String> relaxSoundDemoImages = [
    "/feature_demos/relax_sounds/relax_sound_1.jpg",
    "/feature_demos/relax_sounds/relax_sound_2.jpg",
    "/feature_demos/relax_sounds/relax_sound_3.jpg",
    "/feature_demos/relax_sounds/relax_sound_4.jpg",
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

  final List<String> demoImages;
  @override
  bool get fullScreen => false;

  double get height => 380.0;

  factory SpDemoImagesSheet.periodCalendarDemo() {
    return const SpDemoImagesSheet(demoImages: periodCalendarDemoImages);
  }

  factory SpDemoImagesSheet.relaxSoundDemo() {
    return const SpDemoImagesSheet(demoImages: relaxSoundDemoImages);
  }

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return Column(
      mainAxisSize: .min,
      children: [
        SpDemoImages(
          demoImageUrlPaths: demoImages,
          skeletonCount: demoImages.length,
        ),
        SizedBox(height: bottomPadding),
      ],
    );
  }
}
