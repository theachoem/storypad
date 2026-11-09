import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_icons.dart';

const Color _kDefaultPinColor = Colors.redAccent;

// --- Center pin tunables ---
const double _kPinSize = 48.0;
const double _kPinLiftHeight = 20.0;
const double _kShadowRestDiameter = 6.0;
const double _kShadowLiftDiameter = 20.0;
// ---

/// The pin fixed at a map picker's center: lifts while the map is dragged and drops back
/// (with a small bounce) when it stops. Its tip points at the map's center.
class SpMapCenterPin extends StatefulWidget {
  const SpMapCenterPin({super.key, required this.isDragging});

  final bool isDragging;

  @override
  State<SpMapCenterPin> createState() => _SpMapCenterPinState();
}

class _SpMapCenterPinState extends State<SpMapCenterPin> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.elasticOut,
    );
  }

  @override
  void didUpdateWidget(SpMapCenterPin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDragging != oldWidget.isDragging) {
      if (widget.isDragging) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Decorative: a drag that starts on the pin (or its shadow) must reach the map beneath it.
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: _buildPin());
  }

  Widget _buildPin() {
    return Transform.translate(
      offset: const Offset(0, -24.0),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final double t = _animation.value;
          final double shadowDiameter = _kShadowRestDiameter + (_kShadowLiftDiameter - _kShadowRestDiameter) * t;

          return Column(
            mainAxisSize: .min,
            children: [
              Transform.translate(
                offset: Offset(0, -_kPinLiftHeight * t),
                child: const Icon(SpIcons.locationPin, size: _kPinSize, color: _kDefaultPinColor),
              ),
              Container(
                width: shadowDiameter,
                height: shadowDiameter,
                decoration: BoxDecoration(
                  color: _kDefaultPinColor.withValues(alpha: 0.8 * (1 - t)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _kDefaultPinColor.withValues(alpha: 0.8 * t),
                    width: 1.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
