import 'package:flutter/material.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_firestore_storage_downloader_builder.dart';
import 'package:storypad/widgets/sp_gradient_loading.dart';
import 'package:storypad/widgets/sp_image.dart';

class SpAndroidRedemptionSheet extends BaseBottomSheet {
  @override
  bool get fullScreen => false;

  static const double imageWidth = 175.1;
  static const double imageHeight = 360.0;
  static const double imageAspectRatio = imageWidth / imageHeight;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTitle(context),
          const SizedBox(height: 16.0),
          buildStepsCarousel(context),
          buildBottomPadding(bottomPadding),
        ],
      ),
    );
  }

  Widget buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        "How to Redeem Promo Code?",
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget buildStepsCarousel(BuildContext context) {
    final steps = [
      (
        title: 'Tap "Purchase" on any add-on',
        imagePath: '/android_redemption_flow/1_purchase_dialog.png',
      ),
      (
        title: 'Select "Redeem code" from payment methods',
        imagePath: '/android_redemption_flow/2_list_all_methods.png',
      ),
      (title: 'Enter and apply the promo code', imagePath: '/android_redemption_flow/3_apply_promo.png'),
    ];

    // Calculate card height: title row (40) + spacing (12) + image height (360) + padding
    const double cardHeight = 40.0 + 12.0 + imageHeight + 16.0;

    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          return buildStepCard(context, steps[index], index + 1);
        },
      ),
    );
  }

  Widget buildStepCard(
    BuildContext context,
    ({String imagePath, String title}) step,
    int stepNumber,
  ) {
    return Container(
      width: imageWidth + 24.0,
      margin: const EdgeInsets.only(right: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          buildStepTitle(context, stepNumber, step),
          const SizedBox(height: 12.0),
          buildStepDemoImage(step),
        ],
      ),
    );
  }

  Widget buildStepTitle(BuildContext context, int stepNumber, ({String imagePath, String title}) step) {
    return SizedBox(
      height: 40.0,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              step.title,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStepDemoImage(
    ({String imagePath, String title}) step,
  ) {
    return Material(
      clipBehavior: Clip.hardEdge,
      elevation: 1.0,
      borderRadius: BorderRadius.circular(8.0),
      child: SizedBox(
        width: imageWidth,
        height: imageHeight,
        child: SpFirestoreStorageDownloaderBuilder(
          filePath: step.imagePath,
          builder: (context, file, failed) {
            if (failed) {
              return SpImage.buildImageError(
                imageWidth,
                imageHeight,
                context,
                'Failed to load',
              );
            }

            if (file == null) {
              return const SpGradientLoading(
                width: imageWidth,
                height: imageHeight,
              );
            }

            return Image.file(
              file,
              width: imageWidth,
              height: imageHeight,
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }
}
