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
    List<Widget> buttons = switch (kIAPEnabled) {
      false => [],
      true => [
        SpFadeIn.bound(
          child: IconButton(
            tooltip: tr('add_ons.relax_sounds.title'),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: CircleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            icon: const Icon(SpIcons.musicNote),
            onPressed: () {
              if (provider.relaxSound) {
                const RelaxSoundsRoute().push(context);
              } else {
                const AddOnsRoute().push(context);
              }
            },
          ),
        ),
      ],
    };

    return Container(
      margin: EdgeInsets.only(
        top: 8.0,
        left: AppTheme.getDirectionValue(context, 0.0, widget.screenPadding.left + 8.0)!,
        right: AppTheme.getDirectionValue(context, widget.screenPadding.right + 8.0, 0.0)!,
        bottom: widget.screenPadding.bottom + 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 0.0,
        children: [
          ...buttons,
          IconButton(
            tooltip: tr('page.calendar.title'),
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
