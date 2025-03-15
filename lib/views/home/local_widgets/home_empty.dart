part of '../home_view.dart';

class _HomeEmpty extends StatelessWidget {
  const _HomeEmpty({
    required this.viewModel,
  });

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    String message = tr('page.home.empty_message', namedArgs: {
      "YEAR": viewModel.year.toString(),
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SpTapEffect(
          effects: [
            SpTapEffectType.touchableOpacity,
            SpTapEffectType.scaleDown,
          ],
          onTap: () => ThemeRoute().push(context),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: SpLoopAnimationBuilder(
              loopCount: 2,
              reverse: false,
              duration: Duration(seconds: 6),
              reverseDuration: Duration(seconds: 6),
              builder: (context, value, child) {
                IconData iconData;

                if (value <= 0.25) {
                  iconData = Icons.color_lens_outlined;
                } else if (value <= 0.5) {
                  iconData = Icons.dark_mode_outlined;
                } else if (value <= 0.75) {
                  iconData = Icons.light_mode_outlined;
                } else {
                  iconData = MdiIcons.formatFont;
                }

                return AnimatedSwitcher(
                  switchInCurve: Curves.easeInOutQuad,
                  switchOutCurve: Curves.easeInOutQuad,
                  duration: Durations.long1,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    iconData,
                    key: ValueKey(iconData),
                    size: 32.0,
                    color: Color.lerp(ColorScheme.of(context).bootstrap.info.color,
                        ColorScheme.of(context).bootstrap.danger.color, value),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(maxWidth: 200),
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + kToolbarHeight),
          child: RichText(
            textAlign: TextAlign.center,
            textScaler: MediaQuery.textScalerOf(context),
            text: TextSpan(
              style: TextTheme.of(context).bodyLarge,
              children: [
                TextSpan(text: message.split("{EDIT_BUTTON}").first),
                const WidgetSpan(
                  child: Icon(Icons.edit, size: 16.0),
                  alignment: PlaceholderAlignment.middle,
                ),
                TextSpan(text: message.split("{EDIT_BUTTON}").last),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
