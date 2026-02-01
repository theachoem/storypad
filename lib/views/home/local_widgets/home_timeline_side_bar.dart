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
  @override
  Widget build(BuildContext context) {
    final iapProvider = Provider.of<InAppPurchaseProvider>(context);

    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        buildBackgrounds(context),
        buildButtons(context, iapProvider),
      ],
    );
  }

  Widget buildButtons(BuildContext context, InAppPurchaseProvider provider) {
    double baseSideMargin = (Platform.isMacOS ? 12.0 : 8.0);

    return Container(
      margin: EdgeInsets.only(
        top: 8.0,
        left: AppTheme.getDirectionValue(context, 0.0, widget.screenPadding.left + baseSideMargin)!,
        right: AppTheme.getDirectionValue(context, widget.screenPadding.right + baseSideMargin, 0.0)!,
        bottom: widget.screenPadding.bottom + 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Platform.isMacOS ? 8.0 : 0.0,
        children: [
          if (kIAPEnabled && !provider.allRewarded) const _AddOnButton(),
          if (kIAPEnabled)
            SpFadeIn.bound(
              child: SpFloatingMusicNote.wrapIfPlaying(
                child: IconButton(
                  tooltip: tr('add_ons.relax_sounds.title'),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: CircleBorder(
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  icon: const Icon(SpIcons.musicNote),
                  onPressed: () => const RelaxSoundsRoute().push(context),
                ),
              ),
            ),
          SpFadeIn.bound(
            child: IconButton(
              tooltip: tr('page.search.title'),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: CircleBorder(
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              icon: const Icon(SpIcons.search),
              onPressed: () => SearchRoute().push(context),
            ),
          ),
          IconButton(
            tooltip: tr('page.calendar.title'),
            style: IconButton.styleFrom(
              backgroundColor: ColorScheme.of(context).surface,
              shape: CircleBorder(side: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            icon: const Icon(SpIcons.calendar),
            onPressed: () => CalendarRoute(
              initialMonth: null,
              initialYear: widget.viewModel.year,
              initialSegment: .mood,
            ).push(context),
          ),
        ],
      ),
    );
  }

  Widget buildBackgrounds(BuildContext context) {
    return Positioned(
      left: AppTheme.getDirectionValue(context, 4.0, widget.screenPadding.left + 12.0)!,
      right: AppTheme.getDirectionValue(context, widget.screenPadding.right + 12.0, 4.0)!,
      bottom: 0,
      top: 0,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 32,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.backgroundColor.withValues(alpha: 0.0),
                    widget.backgroundColor.withValues(alpha: 0.8),
                    widget.backgroundColor,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: 32,
            child: Container(
              color: widget.backgroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddOnButton extends StatefulWidget {
  const _AddOnButton();

  @override
  State<_AddOnButton> createState() => _AddOnButtonState();
}

class _AddOnButtonState extends State<_AddOnButton> {
  late bool showBadge = true;

  @override
  Widget build(BuildContext context) {
    return SpFadeIn.bound(
      child: buildButton(context),
    );
  }

  Widget buildButton(BuildContext context) {
    Widget button = IconButton(
      tooltip: tr('page.add_ons.title'),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: CircleBorder(
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      icon: const Icon(SpIcons.addOns),
      onPressed: () {
        const AddOnsRoute().push(context);

        setState(() {
          showBadge = false;
        });
      },
    );

    if (showBadge) {
      return Stack(
        children: [
          button,
          Positioned(
            right: 6.5,
            top: 6.5,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: .circle,
                color: ColorFromDayService(context: context).get(7),
              ),
            ),
          ),
        ],
      );
    } else {
      return button;
    }
  }
}
