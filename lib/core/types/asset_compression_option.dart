import 'package:easy_localization/easy_localization.dart';

enum AssetCompressionOption {
  standard,
  none,
  ;

  static const defaultValue = AssetCompressionOption.standard;
  static const standardQuality = 80;

  bool get defaultCompression => this == .standard;

  int? get imagePickerQuality {
    switch (this) {
      case AssetCompressionOption.none:
        return null;
      case AssetCompressionOption.standard:
        return standardQuality;
    }
  }

  int get filePickerCompressionQuality {
    switch (this) {
      case AssetCompressionOption.none:
        return 0;
      case AssetCompressionOption.standard:
        return standardQuality;
    }
  }

  String get label {
    switch (this) {
      case AssetCompressionOption.none:
        return tr('general.asset_compression.none');
      case AssetCompressionOption.standard:
        return tr('general.asset_compression.standard');
    }
  }

  String get labelWithDefault {
    if (defaultCompression) {
      return '$label (${tr('general.default')})';
    } else {
      return label;
    }
  }
}
