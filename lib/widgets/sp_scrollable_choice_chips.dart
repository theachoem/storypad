import 'package:flutter/material.dart';

class SpScrollableChoiceChips<T> extends StatefulWidget {
  const SpScrollableChoiceChips({
    super.key,
    required this.choices,
    required this.storiesCount,
    required this.toLabel,
    required this.selected,
    required this.onToggle,
    this.wrapWidth,
  });

  final List<T> choices;
  final int? Function(T choice) storiesCount;
  final String Function(T choice) toLabel;
  final bool Function(T choice) selected;
  final void Function(T choice)? onToggle;
  final double? wrapWidth;

  @override
  State<SpScrollableChoiceChips<T>> createState() => SpScrollableChoiceChipsState<T>();
}

class SpScrollableChoiceChipsState<T> extends State<SpScrollableChoiceChips<T>> {
  final Map<int, GlobalKey> _chipKeys = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToFirstSelected(animated: false);
    });
  }

  void scrollToFirstSelected({
    bool animated = true,
  }) {
    int? lastSelectedIndex;

    for (int i = 0; i < widget.choices.length; i++) {
      if (widget.selected(widget.choices[i])) {
        lastSelectedIndex = i;
      }
    }

    if (lastSelectedIndex != null) {
      final key = _chipKeys[lastSelectedIndex];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          curve: Curves.ease,
          duration: animated ? Durations.medium1 : Duration.zero,
          alignment: 0.5,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0).add(
        EdgeInsets.only(
          left: MediaQuery.of(context).padding.left,
          right: MediaQuery.of(context).padding.right,
        ),
      ),
      child: SizedBox(
        width: widget.wrapWidth,
        child: Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: List.generate(widget.choices.length, (index) {
            final choice = widget.choices.elementAt(index);
            final label = widget.toLabel(choice);
            final storyCount = widget.storiesCount(choice);

            _chipKeys[index] = GlobalKey();

            return ChoiceChip(
              key: _chipKeys[index],
              materialTapTargetSize: .shrinkWrap,
              showCheckmark: false,
              selected: widget.selected(choice),
              onSelected: widget.onToggle != null ? (_) => widget.onToggle!(choice) : null,
              label: Row(
                mainAxisAlignment: .center,
                crossAxisAlignment: .center,
                spacing: 4.0,
                mainAxisSize: .min,
                children: [
                  Text(
                    label,
                    style: TextTheme.of(context).labelMedium,
                  ),
                  if (storyCount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2),
                      decoration: BoxDecoration(
                        color: ColorScheme.of(context).surface,
                        borderRadius: BorderRadius.circular(48.0),
                      ),
                      child: Text(
                        storyCount.toString(),
                        style: TextTheme.of(context).labelSmall,
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );

    // when wrapWidth is not null, it is not a single row scrollable, so no need for fade effect.
    if (widget.wrapWidth != null) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 16.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 16.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
