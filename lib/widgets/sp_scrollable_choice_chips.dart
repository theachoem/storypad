import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';

class SpScrollableChoiceChips<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0).add(
        EdgeInsets.only(
          left: MediaQuery.of(context).padding.left,
          right: MediaQuery.of(context).padding.right,
        ),
      ),
      child: SizedBox(
        width: wrapWidth,
        child: Wrap(
          spacing: 8.0,
          children: List.generate(choices.length, (index) {
            final choice = choices.elementAt(index);
            final label = toLabel(choice);
            final storyCount = storiesCount(choice);

            return ChoiceChip(
              label: RichText(
                text: TextSpan(
                  text: "$label ",
                  style: TextTheme.of(context).labelMedium,
                  children: [
                    if (storyCount != null)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2),
                          decoration: BoxDecoration(
                            color: ColorScheme.of(context).readOnly.surface5,
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
                      ),
                  ],
                ),
              ),
              selected: selected(choice),
              onSelected: onToggle != null ? (_) => onToggle!(choice) : null,
            );
          }),
        ),
      ),
    );
  }
}
