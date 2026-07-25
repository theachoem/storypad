import 'package:easy_localization/easy_localization.dart';

/// Controls which networks media assets (images, video, voice notes) may be
/// uploaded over during cloud sync. Entry/text sync is never gated — it costs
/// almost no bandwidth and is the data users actually can't afford to lose.
enum MediaSyncOption {
  wifiAndCellular,
  wifiOnly,
  ;

  /// Wi-Fi + cellular, so upgrading users keep the pre-gating behavior and
  /// Wi-Fi-only is strictly opt-in.
  static const defaultValue = MediaSyncOption.wifiAndCellular;

  bool get defaultOption => this == .wifiAndCellular;

  String get label {
    switch (this) {
      case MediaSyncOption.wifiAndCellular:
        return tr('general.media_sync.wifi_and_cellular');
      case MediaSyncOption.wifiOnly:
        return tr('general.media_sync.wifi_only');
    }
  }

  String get labelWithDefault {
    if (defaultOption) {
      return '$label (${tr('general.default')})';
    } else {
      return label;
    }
  }
}
