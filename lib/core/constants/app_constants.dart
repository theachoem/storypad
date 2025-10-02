import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:storypad/core/objects/device_info_object.dart';

const String kAppName = String.fromEnvironment('APP_NAME');
const String kRevenueCatAndroidApiKey = String.fromEnvironment('REVENUE_CAT_ANDROID_API_KEY');
const String kRevenueCatIosApiKey = String.fromEnvironment('REVENUE_CAT_IOS_API_KEY');
const String kEmailHasherSecreyKey = String.fromEnvironment('EMAIL_HASHER_SECRET_KEY');

const bool kIsCupertino = String.fromEnvironment('CUPERTINO') == 'yes';
final bool kRedeemCodeEnabled = Platform.isAndroid;

const Color kSplashColor = Colors.transparent;
const Color kDefaultColorSeed = Colors.black;

const String kDefaultFontFamily = 'Quicksand';
const FontWeight kDefaultFontWeight = FontWeight.normal;
const FontWeight kTitleDefaultFontWeight = FontWeight.w500;

final bool kIAPEnabled = (Platform.isAndroid && kRevenueCatAndroidApiKey.trim().isNotEmpty) ||
    (Platform.isIOS && kRevenueCatIosApiKey.trim().isNotEmpty);

final bool kSpooky = kPackageInfo.packageName == 'com.juniorise.spooky';
final bool kStoryPad = kPackageInfo.packageName == 'com.tc.writestory';
final bool kCommunity = kPackageInfo.packageName == 'com.juniorise.spooky.community';

late final Directory kSupportDirectory;
late final Directory kApplicationDirectory;
late final DeviceInfoObject kDeviceInfo;
late final PackageInfo kPackageInfo;
late final List<ProcessTextAction> kProcessTextActions;

/// ref: http://fashioncambodia.blogspot.com/2015/11/7-colors-for-every-single-day-of-week.html
const Map<int, Color> kColorsByDayLight = {
  DateTime.monday: Color(0xFFE38A41),
  DateTime.tuesday: Color(0xFF9341B1),
  DateTime.wednesday: Color(0xFFA3AA49),
  DateTime.thursday: Color(0xFF397C2D),
  DateTime.friday: Color(0xFF5080D7),
  DateTime.saturday: Color(0xFF6E183B),
  DateTime.sunday: Color(0xFFE5333A),
};

/// generated m3 color from https://material-foundation.github.io/material-theme-builder/#/dynamic
const Map<int, Color> kColorsByDayDark = {
  DateTime.monday: Color(0xFFFFB780),
  DateTime.tuesday: Color(0xFFF0AFFF),
  DateTime.wednesday: Color(0xFFC5CE5B),
  DateTime.thursday: Color(0xFF90D87D),
  DateTime.friday: Color(0xFFACC7FF),
  DateTime.saturday: Color(0xFFFFB0C8),
  DateTime.sunday: Color(0xFFFFB3AC),
};

const List<ColorSwatch> kMaterialColors = <ColorSwatch>[
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
  Colors.brown,
  Colors.grey,
  Colors.blueGrey,
];
