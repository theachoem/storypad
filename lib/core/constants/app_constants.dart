import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:storypad/core/objects/device_info_object.dart';
import 'package:storypad/core/services/analytics/adaptors/base_analytics_event_adaptor.dart';
import 'package:storypad/core/services/analytics/adaptors/base_analytics_user_property_adaptor.dart';
import 'package:storypad/core/services/cloud_storage/adaptors/base_cloud_storage_adaptor.dart';
import 'package:storypad/core/services/error_reporting/adaptors/base_error_reporting_adaptor.dart';
import 'package:storypad/core/services/remote_config/adaptors/base_remote_config_adaptor.dart';
import 'package:storypad/core/types/app_logo.dart';

const String kAppName = String.fromEnvironment('APP_NAME');
const String kRevenueCatAndroidApiKey = String.fromEnvironment('REVENUE_CAT_ANDROID_API_KEY');
const String kRevenueCatIosApiKey = String.fromEnvironment('REVENUE_CAT_IOS_API_KEY');
const String kEmailHasherSecreyKey = String.fromEnvironment('EMAIL_HASHER_SECRET_KEY');
const String kGoogleMapsAndroidApiKey = String.fromEnvironment('GOOGLE_MAPS_ANDROID_API_KEY');
const String kGoogleMapsIosApiKey = String.fromEnvironment('GOOGLE_MAPS_IOS_API_KEY');

const bool kIsCupertino = String.fromEnvironment('CUPERTINO') == 'yes';

const Color kDefaultColorSeed = Colors.black;
const String kDefaultFontFamily = 'Quicksand';
const FontWeight kDefaultFontWeight = FontWeight.normal;
const FontWeight kTitleDefaultFontWeight = FontWeight.w500;

final bool kIAPEnabled =
    (Platform.isAndroid && kRevenueCatAndroidApiKey.trim().isNotEmpty) ||
    (Platform.isIOS && kRevenueCatIosApiKey.trim().isNotEmpty);

final bool kSupportCamera = Platform.isAndroid || Platform.isIOS;
final bool kSupportQuickActions = Platform.isAndroid || Platform.isIOS;

final bool kSpooky = kPackageInfo.packageName == 'com.juniorise.spooky';
final bool kStoryPad = kPackageInfo.packageName == 'com.tc.writestory';
final bool kCommunity = kPackageInfo.packageName == 'com.juniorise.spooky.community';

late final Directory kSupportDirectory;
late final Directory kApplicationDirectory;
late final DeviceInfoObject kDeviceInfo;
late final PackageInfo kPackageInfo;
late final List<ProcessTextAction> kProcessTextActions;

AppLogo? kAppLogo;

final BaseAnalyticsEventAdaptor kAnalyticsService = BaseAnalyticsEventAdaptor.create();
final BaseAnalyticsUserPropertyAdaptor kAnalyticsUserPropertyService = BaseAnalyticsUserPropertyAdaptor.create();
final BaseErrorReportingAdaptor kErrorReportingService = BaseErrorReportingAdaptor.create();
final BaseRemoteConfigAdaptor kRemoteConfigAdaptor = BaseRemoteConfigAdaptor.create();
final BaseCloudStorageAdaptor kCloudStorageService = BaseCloudStorageAdaptor.create();

/// Maps a stable material color name (persisted in preferences) to its swatch.
/// Used to store user-picked day colors as readable strings (e.g. `red`, `deepPurple`)
/// and to resolve them back into shades (700 for light, 300 for dark).
const Map<String, MaterialColor> kMaterialColorsByName = <String, MaterialColor>{
  'red': Colors.red,
  'pink': Colors.pink,
  'purple': Colors.purple,
  'deepPurple': Colors.deepPurple,
  'indigo': Colors.indigo,
  'blue': Colors.blue,
  'lightBlue': Colors.lightBlue,
  'cyan': Colors.cyan,
  'teal': Colors.teal,
  'green': Colors.green,
  'lightGreen': Colors.lightGreen,
  'lime': Colors.lime,
  'yellow': Colors.yellow,
  'amber': Colors.amber,
  'orange': Colors.orange,
  'deepOrange': Colors.deepOrange,
  'brown': Colors.brown,
  'grey': Colors.grey,
  'blueGrey': Colors.blueGrey,
};

/// Special day-color name representing the monochrome swatch: black in light mode,
/// white in dark mode (matches the picker's black/white swatch and getForeground convention).
const String kBlackWhiteColorName = 'blackWhite';

/// Default color name for each weekday (DateTime.monday..sunday).
/// ref: http://fashioncambodia.blogspot.com/2015/11/7-colors-for-every-single-day-of-week.html
const Map<int, String> kDefaultColorNamesByDay = <int, String>{
  DateTime.monday: 'orange',
  DateTime.tuesday: 'purple',
  DateTime.wednesday: 'lime',
  DateTime.thursday: 'green',
  DateTime.friday: 'blue',
  DateTime.saturday: 'deepPurple',
  DateTime.sunday: 'red',
};

/// Swatches shown in the color picker, derived from [kMaterialColorsByName] to avoid duplication.
final List<ColorSwatch> kMaterialColors = List<ColorSwatch>.from(kMaterialColorsByName.values);
