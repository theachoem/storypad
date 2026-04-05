part of 'root_view.dart';

class _RootContent extends StatelessWidget {
  const _RootContent(
    this.viewModel,
    this.rootProvider,
  );

  final RootViewModel viewModel;
  final RootProvider rootProvider;

  @override
  Widget build(BuildContext context) {
    return SpAppLockWrapper(
      child: SpOnboardingWrapper(
        onOnboarded: () {
          // onboard is considered re-starting experience,
          // reset to show new badge back.
          NewBadgeStorage().remove();
        },
        child: NavigatorPopHandler(
          enabled: true,
          onPopWithResult: (result) {
            if (!SpAppLockWrapper.authenticated(context)) return;

            final NavigatorState? navigator = rootProvider.navigatorKey.currentState;
            if (navigator?.canPop() ?? false) navigator?.maybePop(result);
          },
          child: Scaffold(
            extendBody: true,
            extendBodyBehindAppBar: true,
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                // Use inner of scaffold context instead of root context.
                Builder(builder: (context) => buildPagesNavigator(context)),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: RootSideBar(rootProvider: rootProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPagesNavigator(BuildContext context) {
    double left;
    double right;

    bool bigScreen = WindowedDetectorService.isBigWindow(context);

    final screenPadding = MediaQuery.paddingOf(context);

    if (bigScreen) {
      left = 88;
      right = screenPadding.right + 88;
    } else {
      left = screenPadding.left;
      right = screenPadding.right;
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: EdgeInsets.only(
          top: screenPadding.top,
          left: left,
          bottom: screenPadding.bottom,
          right: right,
        ),
      ),
      child: HeroControllerScope(
        controller: rootProvider.heroController,
        child: Navigator(
          key: rootProvider.navigatorKey,
          initialRoute: rootProvider.initialRoute,
          onGenerateRoute: (settings) => rootProvider.generateRoute(settings),
          observers: [
            _RootRouteObserver(
              onPop: (route, previousRoute) {
                if (previousRoute?.settings.name == null) return;
                rootProvider.selectedRootRouteNameNotifier.value = previousRoute!.settings.name!;
                viewModel.autoBackupWhenNavigateToHome(previousRoute, context);
              },
              onPush: (route, previousRoute) {
                if (route.settings.name == null) return;
                rootProvider.selectedRootRouteNameNotifier.value = route.settings.name!;
                viewModel.autoBackupWhenNavigateToHome(route, context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
