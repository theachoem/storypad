part of '../community_view.dart';

class _CommunityCard extends StatelessWidget {
  const _CommunityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0).copyWith(bottom: 8.0, top: 8.0),
      padding: const EdgeInsets.all(16.0).copyWith(bottom: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        spacing: 12.0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('general.reach_us_description')),
          Container(
            transform: Matrix4.identity()..translate(-4.0, 0.0),
            child: Wrap(
              spacing: Platform.isMacOS ? 8.0 : 0.0,
              runSpacing: Platform.isMacOS ? 8.0 : 0.0,
              children: [
                const SizedBox(height: 48.0),
                SpFadeIn.fromBottom(
                  delay: Durations.medium1,
                  duration: Durations.medium4,
                  child: IconButton.filled(
                    icon: Icon(MdiIcons.reddit),
                    onPressed: () => UrlOpenerService.openInCustomTab(context, "https://www.reddit.com/r/StoryPad"),
                  ),
                ),
                SpFadeIn.fromBottom(
                  delay: Durations.medium2,
                  duration: Durations.medium4,
                  child: IconButton.filledTonal(
                    icon: Icon(MdiIcons.twitter),
                    onPressed: () => UrlOpenerService.openInCustomTab(context, "https://x.com/storypadapp"),
                  ),
                ),
                SpFadeIn.fromBottom(
                  delay: Durations.medium3,
                  duration: Durations.medium4,
                  child: IconButton.filledTonal(
                    icon: Icon(MdiIcons.bug),
                    onPressed: () => UrlOpenerService.openInCustomTab(context, "https://storypad.me#footer"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
