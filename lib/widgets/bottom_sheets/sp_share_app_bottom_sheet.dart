import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storypad/core/constants/app_constants.dart';
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
          'URL': 'https://play.google.com/store/apps/details?id=${kPackageInfo.packageName}'
        },
      ),
      builder: (context, notifier) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                maxLength: null,
                maxLines: null,
                decoration: InputDecoration(hintText: "..."),
                initialValue: notifier.value,
                onChanged: (value) => notifier.value = value,
                onFieldSubmitted: (value) => Share.share(notifier.value.trim()),
              ),
              SizedBox(height: 16.0),
              FilledButton.icon(
                icon: Icon(SpIcons.of(context).share),
                label: Text(tr("button.share")),
                onPressed: () => Share.share(notifier.value.trim()),
              ),
              buildBottomPadding(bottomPadding),
            ],
          ),
        );
      },
    );
  }
}
