import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/device_preferences_object.dart';
import 'package:storypad/core/types/media_sync_option.dart';

void main() {
  group('MediaSyncOption', () {
    test('has wifiAndCellular and wifiOnly', () {
      expect(MediaSyncOption.values, hasLength(2));
      expect(MediaSyncOption.values, contains(MediaSyncOption.wifiAndCellular));
      expect(MediaSyncOption.values, contains(MediaSyncOption.wifiOnly));
    });

    // Upgrading users must keep uploading media exactly as before; Wi-Fi-only
    // has to be an explicit opt-in, never a silent behavior change.
    test('defaults to wifiAndCellular', () {
      expect(MediaSyncOption.defaultValue, MediaSyncOption.wifiAndCellular);
      expect(DevicePreferencesObject.initial().mediaSync, MediaSyncOption.wifiAndCellular);
    });

    test('only the default option is labelled as default', () {
      expect(MediaSyncOption.wifiAndCellular.defaultOption, isTrue);
      expect(MediaSyncOption.wifiOnly.defaultOption, isFalse);

      expect(MediaSyncOption.wifiAndCellular.labelWithDefault, contains('Default'));
      expect(MediaSyncOption.wifiOnly.labelWithDefault, isNot(contains('Default')));
    });

    test('serializes through DevicePreferencesObject json round-trip', () {
      final preferences = DevicePreferencesObject(mediaSync: MediaSyncOption.wifiOnly);
      final restored = DevicePreferencesObject.fromJson(preferences.toJson());

      expect(restored.mediaSync, MediaSyncOption.wifiOnly);
    });

    // Preferences written before this setting existed have no media_sync key.
    test('falls back to the default when absent from stored json', () {
      final json = DevicePreferencesObject.initial().toJson()..remove('media_sync');

      expect(DevicePreferencesObject.fromJson(json).mediaSync, MediaSyncOption.wifiAndCellular);
    });
  });
}
