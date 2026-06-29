part of '../stats_view.dart';

/// Branding footer pinned to the bottom of each stats tab. Its purpose is to
/// advertise the app when a user shares a screenshot of their stats: app logo on
/// the left, app name (with "Pro" when the user is a Pro subscriber), and the
/// untranslated tagline beneath it.
class _StatsShareFooter extends StatelessWidget {
  const _StatsShareFooter();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.of(context);
    final TextTheme textTheme = TextTheme.of(context);
    final bool isProUser = context.watch<InAppPurchaseProvider>().isProUser;

    return Column(
      children: [
        const SizedBox(height: 16.0),
        SpTapEffect(
          onTap: () => UrlOpenerService.openInCustomTab(context, RemoteConfigService.websiteUrl.get()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisSize: .min,
              mainAxisAlignment: .center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  clipBehavior: .hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Theme.of(context).dividerColor, width: 1.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppLogo.storypad_1_0.asset.image(width: 40, height: 40, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12.0),
                Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  children: [
                    Text.rich(
                      strutStyle: const StrutStyle(forceStrutHeight: true),
                      TextSpan(
                        style: textTheme.titleMedium,
                        children: [
                          const TextSpan(text: 'StoryPad'),
                          if (isProUser)
                            TextSpan(
                              text: ' Pro',
                              style: TextStyle(color: colorScheme.primary),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      'My Diary Journal',
                      strutStyle: const StrutStyle(forceStrutHeight: true),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
