part of '../relax_sounds_view.dart';

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.relaxSound,
  });

  final RelaxSoundObject relaxSound;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RelaxSoundsProvider>(context);
    return Positioned(
      top: 2.0,
      left: 16.0,
      right: 16.0,
      child: Slider(
        divisions: 10,
        allowedInteraction: SliderInteraction.tapAndSlide,
        thumbColor: Theme.of(context).colorScheme.surface,
        value: provider.getVolume(relaxSound)!,
        padding: EdgeInsets.zero,
        onChanged: (value) => provider.setVolumn(relaxSound, value),
      ),
    );
  }
}
