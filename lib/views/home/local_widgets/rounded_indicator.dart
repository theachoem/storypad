part of '../home_view.dart';

class _RoundedIndicator extends Decoration {
  const _RoundedIndicator({
    this.borderSide = const BorderSide(width: 2.0, color: Colors.white),
    this.insets = EdgeInsets.zero,
  });

  _RoundedIndicator.simple({
    double height = 40,
    Color color = Colors.white,
  }) : borderSide = BorderSide(width: height, color: color),
       insets = const EdgeInsets.all(1);

  final BorderSide borderSide;
  final EdgeInsetsGeometry insets;

  @override
  Decoration? lerpFrom(Decoration? a, double t) {
    if (a is _RoundedIndicator) {
      return _RoundedIndicator(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        insets: EdgeInsetsGeometry.lerp(a.insets, insets, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  Decoration? lerpTo(Decoration? b, double t) {
    if (b is _RoundedIndicator) {
      return _RoundedIndicator(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        insets: EdgeInsetsGeometry.lerp(insets, b.insets, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _RoundedPainter(this, onChanged);
  }

  Rect _indicatorRectFor(Rect rect, TextDirection textDirection) {
    final Rect indicator = insets.resolve(textDirection).deflateRect(rect);
    return Rect.fromLTWH(
      indicator.left,
      indicator.bottom - borderSide.width,
      indicator.width,
      borderSide.width,
    );
  }

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) {
    return Path()..addRect(_indicatorRectFor(rect, textDirection));
  }
}

class _RoundedPainter extends BoxPainter {
  _RoundedPainter(
    this.decoration,
    super.onChanged,
  );

  final _RoundedIndicator decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration.size != null);

    final Rect rect = offset & configuration.size!;
    final TextDirection textDirection = configuration.textDirection!;
    final Paint paint;

    paint = decoration.borderSide.toPaint()..strokeCap = StrokeCap.round;
    final Rect indicator = decoration._indicatorRectFor(rect, textDirection).deflate(decoration.borderSide.width / 2.0);

    canvas.drawLine(indicator.bottomLeft, indicator.bottomRight, paint);
  }
}
