import 'dart:math';
import 'package:flutter/material.dart';

class SpWaveAnimation extends StatefulWidget {
  final Color? color;
  final double height;
  final double width;
  final int numberOfBars;
  final Duration animationDuration;
  final double waveSpeed;
  final double waveHeight;

  const SpWaveAnimation({
    super.key,
    this.color,
    this.height = 60.0,
    this.width = double.infinity,
    this.numberOfBars = 7,
    this.animationDuration = const Duration(milliseconds: 2000),
    this.waveSpeed = 1.5,
    this.waveHeight = 0.8,
  });

  @override
  State<SpWaveAnimation> createState() => _SpWaveAnimationState();
}

class _SpWaveAnimationState extends State<SpWaveAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<double> _waveOffsets;
  final Random _random = Random();

  // Constants for wave calculations
  static const double _waveLength = 2 * pi; // One full wave cycle
  static const double _waveSpeed = 2.0; // Speed multiplier for the wave

  @override
  void initState() {
    super.initState();

    // Initialize wave offsets with random values for variation
    _waveOffsets = List.generate(
      widget.numberOfBars,
      (_) => _random.nextDouble() * 2 * pi, // Random phase offset
    );

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // Create a curved animation for smoother motion
    _animation =
        Tween<double>(
            begin: 0,
            end: _waveLength * _waveSpeed,
          ).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Curves.linear,
            ),
          )
          ..addListener(() {
            if (mounted) {
              setState(() {
                // Trigger rebuild with the new animation value
              });
            }
          });

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animation.removeListener(() {});
    super.dispose();
  }

  double _calculateHeight(int index, double time) {
    // Use the animation value which is properly interpolated
    final wavePosition = _animation.value;

    // Create a sine wave that moves across the bars
    final position = index / widget.numberOfBars;

    // Base wave with smooth movement
    final wave = sin(wavePosition + position * _waveLength * 1.5 + _waveOffsets[index]);

    // Secondary wave with different frequency for organic feel
    final secondaryWave = sin(wavePosition * 0.7 + position * _waveLength * 2.0 + _waveOffsets[index]) * 0.3;

    // Tertiary wave for subtle variation
    final tertiaryWave = cos(wavePosition * 0.3 + position * _waveLength * 0.5 - _waveOffsets[index]) * 0.2;

    // Combine waves with different weights for natural movement
    final waveValue = (wave * 0.7 + secondaryWave * 0.2 + tertiaryWave * 0.1) * 0.8;

    // Normalize to 0.1-0.9 range and apply wave height
    return 0.1 + ((waveValue + 1) / 2) * widget.waveHeight * 0.8;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final time = _controller.value * 2 * pi;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: _WavePainter(
          color: color,
          barCount: widget.numberOfBars,
          calculateHeight: (index) => _calculateHeight(index, time),
          barWidth: 6.0,
          maxHeight: widget.height,
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  final int barCount;
  final double Function(int) calculateHeight;
  final double barWidth;
  final double maxHeight;
  final Paint _paint = Paint()..style = PaintingStyle.fill;

  _WavePainter({
    required this.color,
    required this.barCount,
    required this.calculateHeight,
    required this.barWidth,
    required this.maxHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barSpacing = size.width / (barCount + 1);
    final radius = barWidth / 2;

    for (int i = 0; i < barCount; i++) {
      final height = calculateHeight(i) * maxHeight;
      final left = (i + 1) * barSpacing - barWidth / 2;
      final top = size.height - height;

      // Create a gradient effect from top to bottom
      final gradient = LinearGradient(
        colors: [
          color.withValues(alpha: 0.9 - (i * 0.05)),
          color.withValues(alpha: 0.7 - (i * 0.03)),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

      _paint.shader = gradient.createShader(Rect.fromLTWH(left, top, barWidth, height));

      // Draw rounded rectangle for each bar
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, height),
        Radius.circular(radius),
      );

      canvas.drawRRect(rect, _paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => true;
}
