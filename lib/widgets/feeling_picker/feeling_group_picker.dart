part of 'sp_feeling_picker.dart';

class _FeelingGroupPicker extends StatefulWidget {
  const _FeelingGroupPicker({
    required this.feeling,
    required this.onPicked,
    required this.onHeightChanged,
  });

  final String? feeling;
  final Future<void> Function(String? feeling) onPicked;
  final void Function(double height) onHeightChanged;

  @override
  State<_FeelingGroupPicker> createState() => _FeelingGroupPickerState();
}

class _FeelingGroupPickerState extends State<_FeelingGroupPicker> {
  late String? feeling = widget.feeling;

  bool? visible;
  final double gridCardWidth = 300;
  final int crossAxisCount = 3;
  late final double feelingCardSize = gridCardWidth / crossAxisCount;
  late final double gridCardHeight = feelingCardSize * min(3, (FeelingGroup.values.length / crossAxisCount).ceil());

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onHeightChanged(gridCardHeight);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: gridCardWidth,
      height: gridCardHeight,
      child: GridView.count(
        padding: EdgeInsets.zero,
        crossAxisCount: crossAxisCount,
        physics: NeverScrollableScrollPhysics(),
        children: List.generate(FeelingGroup.values.length, (index) {
          final Widget feelingGroup = buildFeelingGroup(
            group: FeelingGroup.values[index],
            context: context,
          );

          if (visible == null) return feelingGroup;
          return Visibility(
            visible: visible!,
            child: SpFadeIn.bound(
              delay: Durations.short2 * index,
              child: feelingGroup,
            ),
          );
        }),
      ),
    );
  }

  Widget buildFeelingGroup({
    required FeelingGroup group,
    required BuildContext context,
  }) {
    final moods = FeelingObject.feelignGroups[group]!;
    final bool selected = FeelingObject.feelignGroups[group]?.contains(feeling) == true;

    return FeelingObjectCard(
      showSuffixIcon: true,
      name: group.translatedName,
      selected: selected,
      icon: (selected ? FeelingObject.feelingsByKey[feeling] : FeelingObject.feelingsByKey[moods.first])!
          .image64
          .image(width: 36, height: 36),
      onTap: () async {
        setState(() => visible = false);

        await Navigator.of(context).push(MaterialPageRoute(
          builder: (context) {
            return _FeelingGroupItemPicker(
              group: group,
              feeling: feeling,
              onPicked: (context, feeling) {
                if (this.feeling == feeling) feeling = null;
                setState(() => this.feeling = feeling);
                return widget.onPicked(feeling);
              },
              onHeightChanged: (childHeight) {
                widget.onHeightChanged(childHeight);
              },
            );
          },
        ));

        setState(() => visible = true);
        widget.onHeightChanged(gridCardHeight);
      },
    );
  }
}
