import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/email_hasher_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class SpShareLogsBottomSheet extends BaseBottomSheet {
  static bool? rcatAnonymous;
  static bool? isConfigured;
  static String? rcatAppUserID;
  static String? backupEmail;
  static String? emailHash;

  SpShareLogsBottomSheet();

  @override
  Future<T?> show<T>({
    required BuildContext context,
  }) async {
    backupEmail = context.read<BackupProvider>().currentUser?.email;
    emailHash = EmailHasherService(secretKey: kEmailHasherSecreyKey).hmacEmail(backupEmail ?? "");

    rcatAnonymous = await Purchases.isAnonymous;
    rcatAppUserID = await Purchases.appUserID;
    isConfigured = await Purchases.isConfigured;

    if (context.mounted) {
      return super.show(context: context);
    }

    return null;
  }

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SpSingleStateWidget(
      initialValue: [
        "=== StoryPad Debug Information ===",
        "App Name: $kAppName",
        "Cupertino Mode: $kIsCupertino",
        "IAP Enabled: $kIAPEnabled",
        "",
        "=== RevenueCAT ===",
        "Configured: $isConfigured",
        "Anonymous: $rcatAnonymous",
        "App User ID: $rcatAppUserID",
        "Backup Email: $backupEmail",
        "Email Hash: $emailHash",
        "",
        "=== Package Info ===",
        "Package: ${kPackageInfo.data}",
        "",
        "=== Device Info ===",
        "Device ID: ${kDeviceInfo.id}",
        "Device Model: ${kDeviceInfo.model}",
        "",
        "=== Application Logs ===",
        ...AppLogger.logs,
        "",
        "=== End Debug Info ===",
      ].join("\n"),
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
                onFieldSubmitted: (value) => SharePlus.instance.share(ShareParams(text: notifier.value.trim())),
              ),
              const SizedBox(height: 16.0),
              FilledButton.icon(
                icon: const Icon(SpIcons.share),
                label: Text(tr("button.share")),
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text: notifier.value.trim(),
                  ),
                ),
              ),
              buildBottomPadding(bottomPadding),
            ],
          ),
        );
      },
    );
  }
}
