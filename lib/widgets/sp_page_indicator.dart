import 'package:flutter/material.dart';

class SpPageIndicator extends StatefulWidget {
  final PageController controller;
  final int pageCount;
  final int maxVisiblePages;
  final Color activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double spacing;

  const SpPageIndicator({
    super.key,
    required this.controller,
    required this.pageCount,
    this.maxVisiblePages = 5,
    this.activeColor = Colors.blue,
    this.inactiveColor = Colors.grey,
    this.dotSize = 8.0,
    this.spacing = 6.0,
  });

  @override
  State<SpPageIndicator> createState() => _SpPageIndicatorState();
}

class _SpPageIndicatorState extends State<SpPageIndicator> {
  @override
  void initState() {
    super.initState();

    // Re-build whenever the controller scrolls
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (widget.controller.hasClients) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pageCount <= 0) return const SizedBox.shrink();

    // Get current scroll position (0.0 to pageCount - 1)
    double currentPage = 0;
    try {
      currentPage = widget.controller.page ?? 0;
    } catch (_) {
      currentPage = 0;
    }

    return Container(
      height: widget.dotSize * 2,
      alignment: Alignment.center,
      child: ClipRect(
        // Keeps dots from bleeding outside the container
        child: SizedBox(
          width: (widget.dotSize + widget.spacing) * widget.maxVisiblePages,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(widget.pageCount, (index) {
              // Calculate the offset of each dot relative to the center
              final double centerIndex = (widget.maxVisiblePages - 1) / 2;
              final double offsetFromCenter = index - currentPage;

              // Logic for scaling dots at the edges
              double distance = (index - currentPage).abs();
              double scale = 1.0;

              // Telegram logic: shrink dots if they are far from the current page
              if (distance > (widget.maxVisiblePages / 2) - 1) {
                scale = 0.6;
              }
              if (distance > (widget.maxVisiblePages / 2)) {
                scale = 0.4;
              }
              if (distance > (widget.maxVisiblePages / 2) + 1) {
                scale = 0.0; // Hide completely
              }

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                // Center the current dot and move others accordingly
                left: (centerIndex + offsetFromCenter) * (widget.dotSize + widget.spacing),
                top: (widget.dotSize - (widget.dotSize * scale)) / 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: widget.dotSize * scale,
                  height: widget.dotSize * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == currentPage.round()
                        ? widget.activeColor
                        : widget.inactiveColor.withValues(alpha: scale.clamp(0.2, 1.0)),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
