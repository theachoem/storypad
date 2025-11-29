class RootViewSideBarInfo {
  final bool bigScreen;
  final bool showSideBar;
  final bool manuallyToggled;

  RootViewSideBarInfo({
    required this.bigScreen,
    required this.showSideBar,
    required this.manuallyToggled,
  });

  RootViewSideBarInfo copyWith({
    bool? bigScreen,
    bool? showSideBar,
    bool? manuallyToggled,
  }) {
    return RootViewSideBarInfo(
      bigScreen: bigScreen ?? this.bigScreen,
      showSideBar: showSideBar ?? this.showSideBar,
      manuallyToggled: manuallyToggled ?? this.manuallyToggled,
    );
  }
}
