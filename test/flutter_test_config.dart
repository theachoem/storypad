import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

// reference:
// https://stackoverflow.com/a/68834927/13989964
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final content = await File('translations/en.json').readAsString();
  final data = jsonDecode(content) as Map<String, dynamic>;

  Localization.load(
    const Locale('en'),
    translations: Translations(data),
  );

  SharedPreferences.setMockInitialValues({});
  await testMain();
}
