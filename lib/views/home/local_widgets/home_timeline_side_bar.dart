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
  ValueNotifier<bool> showProBadgeNotifier = ValueNotifier<bool>(true);
  late final DevicePreferencesProvider devicePreferencesProvider = context.read<DevicePreferencesProvider>();

  @override
  void initState() {
    super.initState();
    devicePreferencesProvider.addListenerForAddOnChanges(_addOnListeners);
  }

  void _addOnListeners() {
    setState(() {});
  }

  @override
  void dispose() {
    showProBadgeNotifier.dispose();
    devicePreferencesProvider.removeListenerForAddOnChanges(_addOnListeners);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        buildBackgrounds(context),
        buildButtons(context),
      ],
    );
  }

  Widget buildButtons(BuildContext context) {
    final double baseSideMargin = (Platform.isMacOS ? 12.0 : 8.0);

    return Consumer<InAppPurchaseProvider>(
      builder: (context, provider, child) {
        final items = SideItems.getTimelineSideBarItems(
          homeViewModel: widget.viewModel,
          iapProvider: provider,
          showBadgeNotifer: showProBadgeNotifier,
          enableRelaxSounds: context.read<DevicePreferencesProvider>().enableRelaxSounds,
        );

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
            children: items.map((item) => _buildTimelineButton(context, item)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTimelineButton(BuildContext context, TimelineSideBarItem item) {
    Widget button = IconButton(
      tooltip: item.tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: CircleBorder(
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      icon: Icon(item.icon),
      onPressed: () => item.onTap(context),
    );

    if (item.showBadgeNotifer != null) {
      button = ValueListenableBuilder<bool>(
        valueListenable: item.showBadgeNotifer!,
        child: button,
        builder: (context, showBadge, child) {
          if (!showBadge) return child!;

          return Stack(
            children: [
              child!,
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
        },
      );
    }

    return item.wrap?.call(context, button) ?? button;
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
