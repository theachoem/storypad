class RootViewSideBarInfo {
  final bool bigScreen;
  final bool showSideBar;
  final bool manuallyToggled;
  final bool optionsExpanded;

  RootViewSideBarInfo({
    required this.bigScreen,
    required this.showSideBar,
    required this.manuallyToggled,
    required this.optionsExpanded,
  });

  RootViewSideBarInfo copyWith({
    bool? bigScreen,
    bool? showSideBar,
    bool? manuallyToggled,
    bool? optionsExpanded,
  }) {
    return RootViewSideBarInfo(
      bigScreen: bigScreen ?? this.bigScreen,
      showSideBar: showSideBar ?? this.showSideBar,
      manuallyToggled: manuallyToggled ?? this.manuallyToggled,
      optionsExpanded: optionsExpanded ?? this.optionsExpanded,
    );
  }
}
