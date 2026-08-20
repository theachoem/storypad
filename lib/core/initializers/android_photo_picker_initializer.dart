import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Opts image_picker into the native Android Photo Picker instead of its
/// default fallback, the generic system file/document picker (`ACTION_GET_CONTENT`).
/// See https://pub.dev/packages/image_picker_android#android-13-photo-picker.
class AndroidPhotoPickerInitializer {
  static void call() {
    final platform = ImagePickerPlatform.instance;
    if (platform is ImagePickerAndroid) {
      platform.useAndroidPhotoPicker = true;
    }
  }
}
