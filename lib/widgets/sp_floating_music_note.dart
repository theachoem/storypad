import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:storypad/providers/relax_sounds_provider.dart';

class SpFloatingMusicNote extends StatefulWidget {
  const SpFloatingMusicNote._({
    required this.child,
  });

  final Widget child;

  static Widget wrapIfPlaying({
    required Widget child,
  }) {
    return Consumer<RelaxSoundsProvider>(
      child: child,
      builder: (context, provider, child) {
        bool notPlaying =
            provider.audioPlayersService.playingStates.keys.isEmpty ||
            provider.audioPlayersService.playingStates.values.every(
              (p) => p.processingState == ProcessingState.idle || p.processingState == ProcessingState.loading,
            );

        if (notPlaying) return child!;
        return SpFloatingMusicNote._(child: child!);
      },
    );
  }

  @override
  State<SpFloatingMusicNote> createState() => _SpFloatingMusicNoteState();
}

class _SpFloatingMusicNoteState extends State<SpFloatingMusicNote> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  // Configuration: Floating paths
  final List<_FloatingPath> _floatingPaths = [
    // Path 1: Right side
    const _FloatingPath(
      startX: 48,
      startY: 8,
      endX: 60,
      endY: -50,
      icon: CupertinoIcons.music_note,
    ),
    // Path 2: Center
    const _FloatingPath(
      startX: 28,
      startY: 10,
      endX: 35,
      endY: -45,
      icon: CupertinoIcons.double_music_note,
    ),
  ];

  // Animation timing configuration
  final Duration _animationDuration = const Duration(milliseconds: 3500);
  final List<int> _delayMilliseconds = [0, 1400]; // Staggered delays

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _floatingPaths.length,
      (index) => AnimationController(
        vsync: this,
        duration: _animationDuration,
      ),
    );

    _animations = _controllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      );
    }).toList();

    // Start animations with delays
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: _delayMilliseconds[i]), () {
        if (mounted) {
          _controllers[i].repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        ..._floatingPaths.asMap().entries.map((entry) {
          int index = entry.key;
          _FloatingPath path = entry.value;

          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              double progress = _animations[index].value;

              // Calculate position along the path with smooth easing
              double easedProgress = Curves.easeOut.transform(progress);
              double x = path.startX + (path.endX - path.startX) * progress;
              double y = path.startY + (path.endY - path.startY) * easedProgress;

              // Add subtle horizontal drift for natural movement
              double drift = math.sin(progress * math.pi * 2) * 3;
              x += drift;

              // Calculate opacity: fade in first 20%, fade out last 30%
              double opacity;
              if (progress < 0.2) {
                opacity = progress / 0.2;
              } else if (progress > 0.7) {
                opacity = 1.0 - ((progress - 0.7) / 0.3);
              } else {
                opacity = 1.0;
              }

              return Positioned(
                left: x + 8,
                top: y - 12,
                child: Opacity(
                  opacity: opacity,
                  child: Icon(
                    path.icon,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

// Configuration class for floating paths
class _FloatingPath {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final IconData icon;

  const _FloatingPath({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.icon,
  });
}
