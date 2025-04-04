part of 'app_locks_view.dart';

class _AppLocksContent extends StatelessWidget {
  const _AppLocksContent(this.viewModel);

  final AppLocksViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppLockProvider>(context);
    final biometricTile = buildBiometricTile(context: context, provider: provider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: Text(tr("page.app_lock.title")),
          ),
          SliverList.list(children: [
            const SizedBox(height: 8.0),
            SwitchListTile.adaptive(
              secondary: const Icon(SpIcons.lock),
              title: Text(tr('general.pin')),
              subtitle: provider.appLock.pin != null
                  ? Text(List.generate(provider.appLock.pin!.length, (e) => "*").join())
                  : null,
              value: provider.appLock.pin != null,
              onChanged: (value) => provider.togglePIN(context),
            ),
            if (biometricTile != null) biometricTile,
            const Divider(),
            ListTile(
              enabled: provider.appLock.pin != null,
              title: Text(tr("page.security_questions.title")),
              subtitle: Text(tr("page.security_questions.info")),
              leading: Icon(SpIcons.lockQuestion),
              trailing: const Icon(SpIcons.keyboardRight),
              onTap: () => SecurityQuestionsRoute().push(context),
            ),
          ])
        ],
      ),
    );
  }

  Widget? buildBiometricTile({
    required BuildContext context,
    required AppLockProvider provider,
  }) {
    if (provider.localAuth.enrolledBothFingerprintAndFace) {
      return SwitchListTile.adaptive(
        secondary: const Icon(SpIcons.biometrics),
        title: Text(tr("general.biometrics_lock")),
        value: provider.appLock.enabledBiometric == true,
        onChanged: (value) => provider.toggleBiometrics(context),
      );
    } else if (provider.localAuth.enrolledFace) {
      return SwitchListTile.adaptive(
        secondary: const Icon(SpIcons.faceUnlock),
        title: Text(tr("general.face_unlock")),
        value: provider.appLock.enabledBiometric == true,
        onChanged: (value) => provider.toggleBiometrics(context),
      );
    } else if (provider.localAuth.enrolledFingerprint) {
      return SwitchListTile.adaptive(
        secondary: const Icon(SpIcons.fingerprint),
        title: Text(tr("general.fingerprint")),
        value: provider.appLock.enabledBiometric == true,
        onChanged: (value) => provider.toggleBiometrics(context),
      );
    } else if (provider.localAuth.enrolledOtherBiometrics) {
      return SwitchListTile.adaptive(
        secondary: const Icon(SpIcons.fingerprint),
        title: Text(tr("general.biometrics_lock")),
        value: provider.appLock.enabledBiometric == true,
        onChanged: (value) => provider.toggleBiometrics(context),
      );
    }
    return null;
  }
}
