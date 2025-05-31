part of '../home_view.dart';

class _HomeTimelineSideBar extends StatefulWidget {
  const _HomeTimelineSideBar({
    required this.screenPadding,
    required this.backgroundColor,
    required this.viewModel,
  });

  final EdgeInsets screenPadding;
  final Color backgroundColor;
  final HomeViewModel viewModel;

  @override
  State<_HomeTimelineSideBar> createState() => _HomeTimelineSideBarState();
}

class _HomeTimelineSideBarState extends State<_HomeTimelineSideBar> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildBackgrounds(context),
        buildButtons(context),
      ],
    );
  }

  Widget buildButtons(BuildContext context) {
    final buttons = [
      if (kHasRelaxSoundsFeature)
        SpFadeIn.bound(
          child: IconButton(
            color: Theme.of(context).colorScheme.onPrimary,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: CircleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            icon: const Icon(SpIcons.musicNote),
            onPressed: () => const RelaxSoundsRoute().push(context),
          ),
        ),
    ];

    return Container(
      margin: EdgeInsets.only(
        left: AppTheme.getDirectionValue(context, 0.0, widget.screenPadding.left + 8.0)!,
        right: AppTheme.getDirectionValue(context, widget.screenPadding.right + 8.0, 0.0)!,
        bottom: widget.screenPadding.bottom + 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 0.0,
        children: [
          if (expanded) ...buttons,
          if (buttons.isNotEmpty)
            IconButton(
              icon: SpAnimatedIcons.fadeScale(
                showFirst: expanded,
                firstChild: const Icon(SpIcons.keyboardDown),
                secondChild: const Icon(SpIcons.keyboardUp),
              ),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: CircleBorder(
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              onPressed: () {
                expanded = !expanded;
                setState(() {});
              },
            ),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: ColorScheme.of(context).surface,
              shape: CircleBorder(side: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            icon: const Icon(SpIcons.calendar),
            onPressed: () => SpCalendarSheet(
              initialMonth: null,
              initialYear: widget.viewModel.year,
            ).show(context: context),
          ),
        ],
      ),
    );
  }

  Widget buildBackgrounds(BuildContext context) {
    return Positioned.fill(
      child: Container(
        margin: EdgeInsets.only(
          left: AppTheme.getDirectionValue(context, 4.0, widget.screenPadding.left + 12.0)!,
          right: AppTheme.getDirectionValue(context, widget.screenPadding.right + 12.0, 4.0)!,
        ),
        child: Column(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.backgroundColor.withValues(alpha: 0.0),
                    widget.backgroundColor,
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: widget.backgroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
