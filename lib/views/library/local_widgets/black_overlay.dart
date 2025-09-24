part of '../library_view.dart';

class _BlackOverlay extends StatelessWidget {
  const _BlackOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: .0),
                Colors.black.withValues(alpha: .6),
                Colors.black.withValues(alpha: .9),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
