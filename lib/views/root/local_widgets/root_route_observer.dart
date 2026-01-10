part of '../root_view.dart';

class _RootRouteObserver extends NavigatorObserver {
  final void Function(Route route, Route? previousRoute)? onPush;
  final void Function(Route route, Route? previousRoute)? onPop;

  _RootRouteObserver({
    required this.onPush,
    required this.onPop,
  });

  @override
  void didPop(Route route, Route? previousRoute) {
    onPop?.call(route, previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onPush?.call(newRoute!, oldRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    onPush?.call(route, previousRoute);
    super.didPush(route, previousRoute);
  }
}
