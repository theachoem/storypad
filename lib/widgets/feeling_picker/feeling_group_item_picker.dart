part of 'sp_feeling_picker.dart';

class _FeelingGroupItemPicker extends StatefulWidget {
  const _FeelingGroupItemPicker({
    required this.feeling,
    required this.group,
    required this.onPicked,
    required this.onHeightChanged,
  });

  final FeelingGroup group;
  final String? feeling;
  final Future<void> Function(BuildContext context, String? feeling) onPicked;
  final void Function(double height) onHeightChanged;

  @override
  State<_FeelingGroupItemPicker> createState() => _FeelingGroupItemPickerState();
}

class _FeelingGroupItemPickerState extends State<_FeelingGroupItemPicker> {
  final ScrollController controller = ScrollController();
  late String? feeling = widget.feeling;

  final int crossAxisCount = 3;
  late final double feelingCardSize = gridCardWidth / crossAxisCount;

  final double gridCardWidth = 300;
  late final double gridCardHeight = feelingCardSize * min(3, (feelings.length / 3).ceil());

  late final feelings = FeelingObject.feelignGroups[widget.group]!;

  final double toolbarHeight = 48;
  final double toolbarDividerHeight = 1;

  @override
  void initState() {
    animateToInitialFeeling();
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onHeightChanged(gridCardHeight + toolbarHeight + toolbarDividerHeight);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void animateToInitialFeeling() {
    double offset = findInitialScrollOffset(feeling);
    if (offset < 100) return;

    Future.delayed(Durations.medium2).then((value) {
      controller.animateTo(
        min(offset, controller.position.maxScrollExtent),
        duration: Duration(milliseconds: max(100 * offset ~/ 100, 350)),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  double findInitialScrollOffset(String? selectedFeeling) {
    if (selectedFeeling == null) return 0;

    FeelingObject? selected = FeelingObject.feelingsByKey[selectedFeeling];
    List<String> keysList = FeelingObject.feelignGroups[widget.group]!;

    if (selected != null) {
      int index = keysList.indexOf(selectedFeeling);
      int rowIndex = (index / 3).floor();
      int lastRow = keysList.length - 3 * 1;

      // scroll to -2 on last row, while -1 on other
      // to made them in middle on grid of 3
      if (index > lastRow) {
        rowIndex = max(0, rowIndex - 2);
        return rowIndex * 100;
      } else {
        rowIndex = max(0, rowIndex - 1);
        return rowIndex * 100;
      }
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      interactive: true,
      controller: controller,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildToolbar(context),
            Divider(height: toolbarDividerHeight),
            buildFeelingGrid(context),
          ],
        ),
      ),
    );
  }

  Widget buildToolbar(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
      child: BackButton(),
    );
  }

  Widget buildFeelingGrid(BuildContext context) {
    return SizedBox(
      width: gridCardWidth,
      height: gridCardHeight,
      child: GridView.count(
        padding: EdgeInsets.zero,
        crossAxisCount: crossAxisCount,
        controller: controller,
        children: List.generate(feelings.length, (index) {
          final String item = feelings[index];
          return _FeelingObjectCard(
            showSuffixIcon: false,
            name: FeelingObject.feelingsByKey[item]!.translation(context),
            selected: feeling == item,
            onTap: () {
              setState(() => feeling = item);
              widget.onPicked(context, item);
            },
            icon: FeelingObject.feelingsByKey[item]!.image64.image(
              width: 36,
              height: 36,
            ),
          );
        }),
      ),
    );
  }
}
