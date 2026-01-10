part of '../root_view.dart';

class _SideBar extends StatelessWidget {
  const _SideBar();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: context.read<RootProvider>().sideBarInfoNotifier,
      builder: (context, sideBarInfo, child) {
        bool showSideBar = sideBarInfo?.showSideBar ?? false;

        return AnimatedContainer(
          duration: Durations.medium3,
          curve: Curves.ease,
          width: showSideBar ? 260.0 : 0.0,
          child: child!,
        );
      },
      child: Material(
        color: ColorScheme.of(context).surface,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1.0,
              ),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                width: 260.0,
                height: MediaQuery.sizeOf(context).height,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top + 16.0,
                    left: MediaQuery.paddingOf(context).left,
                    bottom: MediaQuery.paddingOf(context).bottom + 32,
                  ),
                  child: const _SideBarItems(),
                ),
              ),
              SpSideBarTogglerButton.buildViewButton(
                right: 12.0,
                viewContext: context,
                open: false,
              ),
              const _TopOverlay(),
              const _BottomOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideBarItems extends StatelessWidget {
  const _SideBarItems();

  @override
  Widget build(BuildContext context) {
    final sideItems = SideItems.getMainItems(fromSideBar: true);
    final moreOptions = SideItems.getMoreOptions(fromSideBar: true);

    return ValueListenableBuilder(
      valueListenable: context.read<RootProvider>().sideBarInfoNotifier,
      builder: (context, sideBarInfo, child) {
        final bool optionsExpanded = sideBarInfo?.optionsExpanded == true;

        if (optionsExpanded) {
          return Column(
            children: moreOptions.map((item) {
              return item.build(context, fromSideBar: true);
            }).toList(),
          );
        } else {
          return Column(
            children: sideItems.map((item) {
              return item.build(context, fromSideBar: true);
            }).toList(),
          );
        }
      },
    );
  }
}

class _TopOverlay extends StatelessWidget {
  const _TopOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 1, // 1 for side bar divider
      height: 32,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ColorScheme.of(context).surface,
                ColorScheme.of(context).surface.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 1, // 1 for side bar divider
      height: 32,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ColorScheme.of(context).surface.withValues(alpha: 0.0),
                ColorScheme.of(context).surface,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
