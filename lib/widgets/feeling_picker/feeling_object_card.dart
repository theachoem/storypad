part of './sp_feeling_picker.dart';

class _FeelingObjectCard extends StatelessWidget {
  const _FeelingObjectCard({
    required this.name,
    required this.selected,
    required this.icon,
    required this.showSuffixIcon,
    required this.onTap,
  });

  final bool selected;
  final String name;
  final Widget icon;
  final bool showSuffixIcon;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Material(
        color: selected ? ColorScheme.of(context).readOnly.surface1 : Colors.transparent,
        child: SpTapEffect(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          scaleActive: 0.95,
          effects: [
            SpTapEffectType.scaleDown,
            SpTapEffectType.touchableOpacity,
          ],
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Wrap(
              direction: Axis.vertical,
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                icon,
                const SizedBox(height: 8.0),
                buildName(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildName(BuildContext context) {
    return SizedBox(
      width: 100 - 4,
      child: RichText(
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          style: Theme.of(context).textTheme.labelSmall,
          text: name,
          children: [
            if (showSuffixIcon)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(
                  Icons.expand_more_outlined,
                  size: 16.0,
                  color: ColorScheme.of(context).onSurface.withValues(alpha: 0.3),
                ),
              )
          ],
        ),
      ),
    );
  }
}
