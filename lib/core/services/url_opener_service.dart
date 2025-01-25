// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as custom_tab;
import 'package:storypad/core/services/analytics_service.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

class UrlOpenerService {
  static Future<bool> launchUrlString(String url) {
    final uri = Uri.parse(url);
    return launchUrl(uri);
  }

  static Future<bool> launchUrl(Uri uri) async {
    if (await launcher.canLaunchUrl(uri)) {
      AnalyticsService.instance.logLaunchUrl(
        url: uri.toString(),
      );

      return launcher.launchUrl(uri);
    } else {
      return false;
    }
  }

  static Future<void> openInCustomTab(
    BuildContext context,
    String url,
  ) async {
    Color? toolbarColor = Theme.of(context).appBarTheme.backgroundColor;
    Color? foregroundColor = Theme.of(context).appBarTheme.foregroundColor;

    AnalyticsService.instance.logOpenLinkInCustomTab(
      url: url,
    );

    await custom_tab.launchUrl(
      Uri.parse(url),
      customTabsOptions: custom_tab.CustomTabsOptions(
        colorSchemes: custom_tab.CustomTabsColorSchemes.defaults(
          toolbarColor: toolbarColor,
        ),
      ),
      safariVCOptions: custom_tab.SafariViewControllerOptions(
        preferredBarTintColor: toolbarColor,
        preferredControlTintColor: foregroundColor,
        dismissButtonStyle: custom_tab.SafariViewControllerDismissButtonStyle.close,
      ),
    );
  }
}
