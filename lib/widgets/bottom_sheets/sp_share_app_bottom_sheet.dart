import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class SpShareAppBottomSheet extends BaseBottomSheet {
  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SpSingleStateWidget(
      initialValue: tr(
        'general.share_app_sample_text',
        namedArgs: {
          'APP_NAME': kAppName,
          'URL': 'https://storypad.me',
        },
      ),
      builder: (context, notifier) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                maxLength: null,
                maxLines: null,
                decoration: const InputDecoration(hintText: "..."),
                initialValue: notifier.value,
                onChanged: (value) => notifier.value = value,
              ),
              const SizedBox(height: 16.0),
              Builder(
                builder: (context) {
                  return FilledButton.icon(
                    icon: const Icon(SpIcons.share),
                    label: Text(tr("button.share")),
                    onPressed: () => shareApp(context, notifier),
                  );
                },
              ),
              buildBottomPadding(bottomPadding),
            ],
          ),
        );
      },
    );
  }

  void shareApp(BuildContext context, ValueNotifier<String> notifier) {
    AnalyticsService.instance.logShareApp();

    RenderBox? box = context.findRenderObject() as RenderBox?;
    SharePlus.instance.share(
      ShareParams(
        text: notifier.value.trim(),

        // iPad requires sharePositionOrigin for proper share sheet positioning
        // Ensure passing correct button context to have proper positioning.
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ),
    );
  }
}
