import 'package:flutter/material.dart';
import 'package:storypad/core/objects/feeling_object.dart';
import 'package:storypad/widgets/feeling_picker/feeling_object_card.dart';
import 'package:storypad/widgets/sticky_header/sticky_header.dart';

class SpFeelingPicker extends StatelessWidget {
  const SpFeelingPicker({
    super.key,
    required this.feeling,
    required this.onPicked,
  });

  final String? feeling;
  final Future<void> Function(String? feeling) onPicked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Material(
        clipBehavior: Clip.hardEdge,
        color: ColorScheme.of(context).surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: FeelingGroup.values.length,
          itemBuilder: (context, index) {
            final group = FeelingGroup.values[index];
            final feelings = FeelingObject.feelignGroups[group];

            if (feelings?.contains(feeling) == true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Scrollable.ensureVisible(context);
              });
            }

            return StickyHeader(
              key: GlobalKey(),
              header: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: ColorScheme.of(context).surface,
                  border: Border(
                    top: index == 0 ? BorderSide.none : BorderSide(color: Theme.of(context).dividerColor),
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        group.translatedName,
                        textAlign: TextAlign.start,
                        style: TextTheme.of(context).titleSmall?.copyWith(color: ColorScheme.of(context).onSurface),
                      ),
                    ),
                    Icon(
                      group.iconData,
                      color: ColorScheme.of(context).secondary,
                    )
                  ],
                ),
              ),
              content: Wrap(
                children: List.generate(feelings!.length, (index) {
                  final String item = feelings[index];

                  return FeelingObjectCard(
                    showSuffixIcon: false,
                    name: FeelingObject.feelingsByKey[item]!.translation(context),
                    selected: feeling == item,
                    onTap: () => onPicked(item),
                    icon: FeelingObject.feelingsByKey[item]!.image64.image(
                      width: 36,
                      height: 36,
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}
