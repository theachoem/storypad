part of '../discover_relax_sounds_content.dart';

class _SoundIconCard extends StatelessWidget {
  const _SoundIconCard({
    required this.relaxSound,
    required this.selected,
    required this.settingUp,
  });

  final RelaxSoundObject relaxSound;
  final bool selected;
  final bool settingUp;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      curve: Curves.ease,
      duration: Durations.short2,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: selected ? ColorScheme.of(context).readOnly.surface2 : null,
        border: Border.all(
          color: selected ? ColorScheme.of(context).primary : Theme.of(context).dividerColor,
        ),
      ),
      child: SpFirestoreStorageDownloaderBuilder(
        filePath: relaxSound.svgIconUrlPath,
        builder: (context, file, failed) {
          if (file == null) {
            return SpLoopAnimationBuilder(
              duration: const Duration(seconds: 1),
              reverseDuration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return SizedBox(
                  height: 48,
                  child: Icon(
                    SpIcons.musicNote,
                    color: Color.lerp(
                      ColorScheme.of(context).onSurface.withValues(alpha: 0.1),
                      ColorScheme.of(context).onSurface.withValues(alpha: 0.3),
                      value,
                    ),
                  ),
                );
              },
            );
          }

          return SpAnimatedIcons.fadeScale(
            showFirst: !settingUp,
            duration: Durations.medium1,
            secondChild: Container(
              height: 48,
              alignment: Alignment.center,
              child: const SizedBox.square(
                dimension: 16.0,
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
            firstChild: buildSvgIcon(file, context),
          );
        },
      ),
    );
  }

  Widget buildSvgIcon(
    File file,
    BuildContext context,
  ) {
    Widget child = SvgPicture.file(
      file,
      semanticsLabel: relaxSound.label,
      height: 48,
      colorFilter: ColorFilter.mode(
        selected ? ColorScheme.of(context).primary : ColorScheme.of(context).onSurface,
        BlendMode.srcIn,
      ),
    );

    if (selected && relaxSound.translationKey.contains('heartbeat')) {
      child = SpLoopAnimationBuilder(
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
        child: child,
        builder: (context, value, child) {
          return Transform.scale(
            scale: lerpDouble(1, 0.9, value),
            child: child!,
          );
        },
      );
    }

    return child;
  }
}
