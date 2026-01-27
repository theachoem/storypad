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
    final List<IconButtonSideItem> sideItems = SideItems.getSideMenuItems();

    return SpAppLockWrapper(
      child: SpOnboardingWrapper(
        onOnboarded: () {
          // onboard is considered re-starting experience,
          // reset to show new badge back.
          NewBadgeStorage().remove();
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!SpAppLockWrapper.authenticated(context)) return;
            if (!didPop) {
              final NavigatorState? navigator = rootProvider.navigatorKey.currentState;
              if (navigator?.canPop() ?? false) navigator?.maybePop(result);
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                rootProvider.setSideBarInfoWithConstraints(constraints);
              });

              return Scaffold(
                extendBody: true,
                extendBodyBehindAppBar: true,
                body: Stack(
                  children: [
                    buildPagesNavigator(context),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: RootSideBar(rootProvider: rootProvider, sideItems: sideItems),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildPagesNavigator(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: rootProvider.sideBarInfoNotifier,
      builder: (context, sideBarInfo, child) {
        double left;
        double right;

        if (sideBarInfo?.bigScreen ?? false) {
          left = 88;
          right = MediaQuery.of(context).padding.right + 88;
        } else {
          left = MediaQuery.of(context).padding.left;
          right = MediaQuery.of(context).padding.right;
        }

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top,
              left: left,
              bottom: MediaQuery.paddingOf(context).bottom,
              right: right,
            ),
          ),
          child: child!,
        );
      },
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
                autoBackupWhenNavigateToHome(previousRoute, context);
              },
              onPush: (route, previousRoute) {
                if (route.settings.name == null) return;
                rootProvider.selectedRootRouteNameNotifier.value = route.settings.name!;
                autoBackupWhenNavigateToHome(route, context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // This is to trigger auto backup when user navigates to home page.
  // It is not fully accurate as some data can be modified directly on home page,
  // but it is good enough for most cases. User can still click backup button manually to ensure data is backed up.
  void autoBackupWhenNavigateToHome(Route<dynamic> route, BuildContext context) {
    if (route.settings.name == const HomeRoute().routeName && context.read<InAppPurchaseProvider>().autoBackups) {
      final backupProvider = context.read<BackupProvider>();
      if (backupProvider.readyToSynced && !backupProvider.allYearSynced) {
        backupProvider.recheckAndSync();
      }
    }
  }
}
