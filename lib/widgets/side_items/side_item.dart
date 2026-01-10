part of 'side_items.dart';

class SideItem extends BaseSideItem {
  final String title;
  final String? subtitle;
  final BaseRoute? route;
  final Widget icon;
  final void Function(BuildContext context)? onTap;

  // optional, some item might want to be hidden on big screen.
  final bool? visibleOnBigScreen;

  static BaseSideItem divider({
    double? height,
  }) => _SideBarBuilder(
    builder: (context, {bool fromSideBar = false, bool fromEndDrawer = false}) => const Divider(),
  );

  static BaseSideItem custom({
    required Widget Function(BuildContext) builder,
  }) => _SideBarBuilder(
    builder: (context, {bool fromSideBar = false, bool fromEndDrawer = false}) => builder(context),
  );

  SideItem({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    this.visibleOnBigScreen,
    this.onTap,
  }) : assert(route != null || onTap != null, 'Either route or onTap must be provided.');

  void tap(bool fromSideBar, BuildContext context) {
    if (onTap != null) return onTap!(context);
    if (route == null) return;

    SideItems.navigate(
      context: context,
      route: route!,
      fromSideBar: fromSideBar,
    );
  }

  @override
  Widget build(
    BuildContext context, {
    bool fromSideBar = false,
    bool fromEndDrawer = false,
  }) {
    if (fromEndDrawer) {
      if (visibleOnBigScreen == false && context.read<RootProvider>().sideBarInfoNotifier.value?.bigScreen == true) {
        return const SizedBox.shrink();
      }

      return ListTile(
        leading: icon,
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        onTap: () => tap(fromSideBar, context),
      );
    } else {
      return buildSideBarItem(
        context: context,
        title: title,
        subtitle: subtitle,
        icon: icon,
        routeName: route?.routeName,
        onTap: () => tap(fromSideBar, context),
      );
    }
  }

  static Widget buildSideBarItem({
    required BuildContext context,
    void Function()? onTap,
    required String title,
    required String? subtitle,
    required Widget? icon,
    required String? routeName,
  }) {
    return _SideBarItem(
      onTap: onTap,
      icon: icon,
      title: title,
      subtitle: subtitle,
      routeName: routeName,
    );
  }
}

class _SideBarBuilder extends BaseSideItem {
  final Widget Function(
    BuildContext, {
    bool fromSideBar,
    bool fromEndDrawer,
  })
  builder;

  _SideBarBuilder({
    required this.builder,
  });

  @override
  Widget build(
    BuildContext context, {
    bool fromSideBar = false,
    bool fromEndDrawer = false,
  }) => builder(context, fromSideBar: fromSideBar, fromEndDrawer: fromEndDrawer);
}

class _SideBarItem extends StatelessWidget {
  const _SideBarItem({
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.routeName,
  });

  final void Function()? onTap;
  final Widget? icon;
  final String title;
  final String? subtitle;
  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ValueListenableBuilder(
        valueListenable: context.read<RootProvider>().selectedRootRouteNameNotifier,
        child: Row(
          mainAxisAlignment: .start,
          crossAxisAlignment: .center,
          spacing: 12.0,
          children: [
            SizedBox.square(dimension: 32, child: icon),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisAlignment: .center,
                spacing: 4.0,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    style: TextTheme.of(context).titleMedium,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      style: TextTheme.of(context).bodySmall?.copyWith(
                        color: ColorScheme.of(context).onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        builder: (context, selectedRootRouteName, contents) {
          bool selected = selectedRootRouteName == routeName;

          return Container(
            padding: EdgeInsets.only(
              left: _leadingPaddedSize,
              top: 8.0,
              bottom: 8.0,
              right: selected ? 8.0 : 12.0,
            ),
            decoration: BoxDecoration(
              border: selected
                  ? Border(
                      right: BorderSide(
                        color: ColorScheme.of(context).primary,
                        width: 4.0,
                      ),
                    )
                  : null,
            ),
            child: contents,
          );
        },
      ),
    );
  }
}
