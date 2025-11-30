part of 'root_view.dart';

class _RootContent extends StatelessWidget {
  const _RootContent(this.viewModel);

  final RootViewModel viewModel;

  static const double leadingPaddedSize = 12.0;

  @override
  Widget build(BuildContext context) {
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
            if (!context.read<AppLockProvider>().authenticated) return;
            if (!didPop) {
              final NavigatorState? navigator = viewModel.navigatorKey.currentState;
              if (navigator?.canPop() ?? false) navigator?.maybePop(result);
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                viewModel.setSideBarInfoWithConstraints(constraints);
              });

              return Row(
                children: [
                  _SideBar(viewModel: viewModel),
                  buildPagesNavigator(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildPagesNavigator(BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder(
        valueListenable: viewModel.sideBarInfoNotifier,
        builder: (context, sideBarInfo, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top,
                left: sideBarInfo?.showSideBar == true ? 0.0 : MediaQuery.paddingOf(context).left,
                bottom: MediaQuery.paddingOf(context).bottom,
                right: MediaQuery.paddingOf(context).right + 0.0,
              ),
            ),
            child: child!,
          );
        },
        child: HeroControllerScope(
          controller: viewModel.heroController,
          child: Navigator(
            key: viewModel.navigatorKey,
            initialRoute: viewModel.initialRoute,
            onGenerateRoute: (settings) => viewModel.generateRoute(settings),
            observers: [
              _RootRouteObserver(
                onPop: (route, previousRoute) {
                  if (previousRoute?.settings.name == null) return;
                  viewModel.selectedRootRouteNameNotifier.value = previousRoute!.settings.name!;
                },
                onPush: (route, previousRoute) {
                  if (route.settings.name == null) return;
                  viewModel.selectedRootRouteNameNotifier.value = route.settings.name!;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
