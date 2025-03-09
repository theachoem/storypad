part of 'onboarding_template.dart';

class _PrivacyPolicyText extends StatelessWidget {
  const _PrivacyPolicyText({
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return SpTapEffect(
      onTap: () => UrlOpenerService.openInCustomTab(context, RemoteConfigService.policyPrivacyUrl.get()),
      child: Text(
        "Read our Privacy & Policy",
        style: TextTheme.of(context).bodyMedium?.copyWith(
              decoration: TextDecoration.underline,
            ),
      ),
    );
  }
}
