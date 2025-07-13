part of '../relax_sounds_view.dart';

class _SoundIconLoading extends StatelessWidget {
  const _SoundIconLoading();

  @override
  Widget build(BuildContext context) {
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
}
