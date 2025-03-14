import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class ShareAppService {
  static Future<void> call(BuildContext context) async {
    String message = '''
I'm using $kAppName to write my stories and diaries—good days, bad days, and everything in between.

Give it a try 📖✨
https://play.google.com/store/apps/details?id=${kPackageInfo.packageName}
''';

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useRootNavigator: true,
      builder: (context) {
        return SpSingleStateWidget(
          initialValue: message,
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
                    icon: Icon(Icons.share_outlined),
                    label: Text(tr("button.share")),
                    onPressed: () => Share.share(notifier.value.trim()),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom)
                ],
              ),
            );
          },
        );
      },
    );
  }
}
