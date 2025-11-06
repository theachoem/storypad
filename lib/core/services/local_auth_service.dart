import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  final LocalAuthentication auth = LocalAuthentication();

  bool? _isDeviceSupported;
  bool? _canCheckBiometrics;
  List<BiometricType>? enrolledBiometrics;

  bool? get canCheckBiometrics => _canCheckBiometrics;
  bool get enrolledBothFingerprintAndFace => enrolledFingerprint && enrolledFace;
  bool get enrolledFingerprint => enrolledBiometrics?.contains(BiometricType.fingerprint) == true;
  bool get enrolledFace => enrolledBiometrics?.contains(BiometricType.face) == true;
  bool get enrolledOtherBiometrics => _canCheckBiometrics == true;

  Future<void> load() async {
    _isDeviceSupported = await auth.isDeviceSupported();
    _canCheckBiometrics = await auth.canCheckBiometrics;
    if (_isDeviceSupported!) enrolledBiometrics = await auth.getAvailableBiometrics();
  }

  Future<bool> authenticate({
    required String title,
  }) async {
    await auth.stopAuthentication();
    return auth.authenticate(localizedReason: title, persistAcrossBackgrounding: true).catchError(
      (e) {
        debugPrint('$runtimeType#authenticate failed: ${e.toString()}');
        return false;
      },
    );
  }
}
