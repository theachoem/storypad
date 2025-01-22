import 'package:local_auth/local_auth.dart';
import 'package:storypad/core/storages/local_auth_enabled_storage.dart';

class LocalAuthService {
  LocalAuthService._();

  static final LocalAuthService instance = LocalAuthService._();
  final LocalAuthentication auth = LocalAuthentication();

  bool? _localAuthEnabled;
  bool? _canCheckBiometrics;

  bool get localAuthEnabled => _localAuthEnabled!;
  bool get canCheckBiometrics => _canCheckBiometrics!;

  Future<void> setEnable(bool value) async {
    await LocalAuthEnabledStorage().write(value);
    await load();
  }

  Future<void> load() async {
    bool isDeviceSupported = await auth.isDeviceSupported();

    _canCheckBiometrics = isDeviceSupported && await auth.canCheckBiometrics;
    _localAuthEnabled = await LocalAuthEnabledStorage().read() == true;
  }

  Future<bool> authenticate() async {
    await auth.stopAuthentication();
    return auth.authenticate(
      localizedReason: 'Unlock to open the app',
      options: const AuthenticationOptions(
        stickyAuth: true,
      ),
    );
  }
}
