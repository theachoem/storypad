import 'package:flutter/material.dart';
import 'package:storypad/core/services/cloud_storage/cloud_storage_service.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_demo_images.dart';

class SpDemoImagesSheet extends BaseBottomSheet {
  const SpDemoImagesSheet({
    required this.demoImages,
  });

  final List<String> demoImages;
  @override
  bool get fullScreen => false;

  double get height => 380.0;

  factory SpDemoImagesSheet.periodCalendarDemo() {
    return const SpDemoImagesSheet(
      demoImages: [
        "/feature_demos/period_calendar/period_calendar_1.jpg",
        "/feature_demos/period_calendar/period_calendar_2.jpg",
        "/feature_demos/period_calendar/period_calendar_3.jpg",
      ],
    );
  }

  factory SpDemoImagesSheet.relaxSoundDemo() {
    return const SpDemoImagesSheet(
      demoImages: [
        "/feature_demos/relax_sounds/relax_sound_1.jpg",
        "/feature_demos/relax_sounds/relax_sound_2.jpg",
        "/feature_demos/relax_sounds/relax_sound_3.jpg",
        "/feature_demos/relax_sounds/relax_sound_4.jpg",
      ],
    );
  }

  Future<List<String>> fetchDemoImageUrlsFor() async {
    List<String> urls = [];

    for (String urlPath in demoImages) {
      String? imageUrl = await CloudStorageService.instance.getDownloadURL(urlPath);
      if (imageUrl != null) urls.add(imageUrl);
    }

    return urls;
  }

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return FutureBuilder(
      future: fetchDemoImageUrlsFor(),
      builder: (context, asyncSnapshot) {
        return Column(
          mainAxisSize: .min,
          children: [
            SpDemoImages(
              demoImageUrls: asyncSnapshot.data,
              context: context,
              skeletonCount: demoImages.length,
            ),
            SizedBox(height: bottomPadding),
          ],
        );
      },
    );
  }
}
