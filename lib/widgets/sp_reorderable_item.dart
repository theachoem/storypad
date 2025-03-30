import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_measure_size.dart';

class SpReorderableItem extends StatefulWidget {
  const SpReorderableItem({
    super.key,
    required this.index,
    required this.child,
    required this.onAccepted,
    this.onDragStarted,
    this.onDragCompleted,
  });

  final int index;
  final Widget child;
  final void Function(int oldIndex) onAccepted;
  final void Function()? onDragStarted;
  final void Function()? onDragCompleted;

  @override
  State<SpReorderableItem> createState() => _SpReorderableItemState();
}

class _SpReorderableItemState extends State<SpReorderableItem> {
  final ValueNotifier<Size?> sizeNotifier = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        widget.onAccepted(details.data);
      },
      builder: (context, candidateItems, rejectedItems) {
        return LongPressDraggable<int>(
          data: widget.index,
          onDragStarted: widget.onDragStarted,
          onDragCompleted: widget.onDragCompleted,
          feedback: ValueListenableBuilder<Size?>(
            valueListenable: sizeNotifier,
            child: widget.child,
            builder: (context, size, child) {
              return Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: size?.width,
                  height: size?.height,
                  child: child,
                ),
              );
            },
          ),
          child: SpMeasureSize(
            onChange: (size) => sizeNotifier.value = size,
            child: candidateItems.isNotEmpty ? Opacity(opacity: 0.5, child: widget.child) : widget.child,
          ),
        );
      },
    );
  }
}
