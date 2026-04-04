import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_firestore_storage_downloader_builder.dart';

class SpPeriodCalendarDemoSheet extends BaseBottomSheet {
  const SpPeriodCalendarDemoSheet();

  @override
  bool get fullScreen => false;

  double get height => 380.0;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    final demoImages = [
      "/feature_demos/period_calendar/period_calendar_1.jpg",
      "/feature_demos/period_calendar/period_calendar_2.jpg",
      "/feature_demos/period_calendar/period_calendar_3.jpg",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              spacing: 16.0,
              children: List.generate(demoImages.length, (index) {
                return SpFirestoreStorageDownloaderBuilder(
                  filePath: demoImages[index],
                  builder: (context, file, failed) {
                    if (file == null) {
                      return Container(
                        width: height * 0.45,
                        decoration: BoxDecoration(
                          color: ColorScheme.of(context).readOnly.surface1,
                          borderRadius: BorderRadiusGeometry.circular(8.0),
                        ),
                      );
                    }

                    return SpFadeIn(
                      child: GestureDetector(
                        child: Material(
                          clipBehavior: Clip.hardEdge,
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8.0)),
                          child: Image.file(
                            file,
                            height: height,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}
