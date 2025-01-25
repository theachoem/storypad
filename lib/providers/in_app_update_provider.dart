import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/core/types/in_app_update_status.dart';
import 'package:storypad/widgets/packages/new_version_plus.dart';

class InAppUpdateProvider extends ChangeNotifier {
  InAppUpdateProvider() {
    _load();
  }

  InAppUpdateStatus? get displayStatus => _displayStatus;
  InAppUpdateStatus? _displayStatus;

  void setDisplayStatus(InAppUpdateStatus? value) {
    _displayStatus = value;
    notifyListeners();
  }

  VersionStatus? _versionStatus;
  AppUpdateInfo? _androidInAppUpdateInfo;

  Future<void> _load() async {
    _versionStatus = await NewVersionPlus().getVersionStatus();
    _androidInAppUpdateInfo = await _checkForUpdate();
    debugPrint("💫 App Update Status: ${_versionStatus?.canUpdate} ${_versionStatus?.originalStoreVersion}");

    if (_versionStatus?.canUpdate == true || _androidInAppUpdateInfo?.canUpdate == true) {
      setDisplayStatus(InAppUpdateStatus.updateAvailable);
      if (Platform.isAndroid && _androidInAppUpdateInfo != null) _listenToInAppUpdateStatus();
    }
  }

  Future<void> update() async {
    bool supportInAppUpdate = _androidInAppUpdateInfo != null;

    if (supportInAppUpdate) {
      await _updateDireclyInApp();
    } else {
      await _openApplicationStore();
    }
  }

  Future<void> _openApplicationStore() async {
    // try open possible store on android.
    if (Platform.isAndroid) {
      String deeplink = 'market://details?id=PACKAGE_NAME';
      bool launched = await UrlOpenerService.launchUrlString(deeplink);
      if (launched) return;
    }

    String appStoreLink = _versionStatus!.appStoreLink;
    await UrlOpenerService.launchUrlString(appStoreLink);
  }

  Future<void> _updateDireclyInApp() async {
    _androidInAppUpdateInfo = await _checkForUpdate();

    switch (_androidInAppUpdateInfo!.installStatus) {
      case InstallStatus.pending:
      case InstallStatus.downloading:
      case InstallStatus.installing:
      case InstallStatus.installed:
        break;
      case InstallStatus.unknown:
      case InstallStatus.failed:
      case InstallStatus.canceled:
        if (_androidInAppUpdateInfo!.flexibleUpdateAllowed) {
          InAppUpdate.startFlexibleUpdate().catchError((e) => AppUpdateResult.inAppUpdateFailed);
        } else if (_androidInAppUpdateInfo!.immediateUpdateAllowed) {
          InAppUpdate.performImmediateUpdate().catchError((e) => AppUpdateResult.inAppUpdateFailed);
        }
        break;
      case InstallStatus.downloaded:
        InAppUpdate.completeFlexibleUpdate();
        break;
    }
  }

  void _listenToInAppUpdateStatus() {
    InAppUpdate.installUpdateListener.listen((status) {
      switch (status) {
        case InstallStatus.unknown:
        case InstallStatus.installed:
          setDisplayStatus(null);
          break;
        case InstallStatus.pending:
        case InstallStatus.downloading:
        case InstallStatus.installing:
          setDisplayStatus(InAppUpdateStatus.downloading);
        case InstallStatus.failed:
        case InstallStatus.canceled:
          setDisplayStatus(InAppUpdateStatus.updateAvailable);
          break;
        case InstallStatus.downloaded:
          setDisplayStatus(InAppUpdateStatus.installAvailable);
          break;
      }
    });
  }

  Future<AppUpdateInfo?> _checkForUpdate() async {
    if (!Platform.isAndroid) return null;

    try {
      return InAppUpdate.checkForUpdate();
    } on PlatformException catch (e) {
      debugPrint("🪲 ${e.message}");
      return null;
    }
  }
}

extension on AppUpdateInfo {
  bool get canUpdate => updateAvailability == UpdateAvailability.updateAvailable;
}
