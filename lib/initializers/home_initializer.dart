// ignore_for_file: library_private_types_in_public_api

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/legacy/storypad_legacy_database.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart' show PreferenceDbModel;
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/types/path_type.dart';

class HomeInitializer {
  static HomeInitializerData? _initializedData;
  static HomeInitializerData? get initializedData => _initializedData;

  static Future<void> call() async {
    final storypadResponse = kStoryPad ? await _loadFromLegacyStorypadIfShould() : null;

    final int year = DateTime.now().year;
    final nickname = PreferenceDbModel.db.nickname.get();

    final stories = await StoryDbModel.db.where(filters: {
      'year': year,
      'types': [PathType.docs.name],
    });

    _initializedData = HomeInitializerData(
      nickname: nickname,
      year: year,
      stories: stories,
      legacyStorypadMigrationResponse: storypadResponse,
    );
  }

  static Future<_LegacyStorypadMigrationResponse> _loadFromLegacyStorypadIfShould() async {
    (bool, String) result = await StorypadLegacyDatabase().transferToObjectBoxIfNotYet();

    bool success = result.$1;
    String message = result.$2;

    return _LegacyStorypadMigrationResponse(
      success: success,
      message: message,
    );
  }

  static HomeInitializerData? getAndClear() {
    HomeInitializerData? tmp = initializedData;
    _initializedData = null;
    return tmp;
  }
}

class HomeInitializerData {
  final String? nickname;
  final int year;
  final CollectionDbModel<StoryDbModel>? stories;
  final _LegacyStorypadMigrationResponse? legacyStorypadMigrationResponse;

  HomeInitializerData({
    required this.nickname,
    required this.year,
    required this.stories,
    required this.legacyStorypadMigrationResponse,
  });
}

class _LegacyStorypadMigrationResponse {
  final bool success;
  final String message;

  _LegacyStorypadMigrationResponse({
    required this.success,
    required this.message,
  });

  Future<void> showPendingMessage(BuildContext context) async {
    if (success) {
      if (!context.mounted) return;
      // if (kDebugMode) MessengerService.of(context).showSnackBar(message);
    } else {
      if (!context.mounted) return;

      OkCancelResult userAction = await showOkAlertDialog(
        context: context,
        title: tr("dialog.error_importing_data_from_legacy_storypad.title"),
        message: tr("dialog.error_importing_data_from_legacy_storypad.message"),
      );

      if (userAction == OkCancelResult.ok && context.mounted) {
        Clipboard.setData(ClipboardData(text: message));
        MessengerService.of(context).showSnackBar(tr("snack_bar.copy_error_to_clipboard_success"));
      }
    }
  }
}
