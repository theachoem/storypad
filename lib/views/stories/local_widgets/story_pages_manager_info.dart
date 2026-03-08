part of 'base_story_view_model.dart';

class StoryPagesManagerInfo {
  final StoryContentDbModel? Function() draftContent;
  final void Function() notifyListeners;

  StoryPagesManagerInfo({
    required int? initialPageIndex,
    required double initialScrollOffset,
    required this.draftContent,
    required this.notifyListeners,
  }) {
    pageScrollController = ScrollController(initialScrollOffset: initialScrollOffset);
    pageController = PageController(initialPage: initialPageIndex ?? 0);
    pageScrollOffsetNotifier = ValueNotifier(initialScrollOffset);
    currentPageIndexNotifier = ValueNotifier(initialPageIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      pageController.addListener(() => currentPageIndexNotifier.value = pageController.page?.toInt());
      pageScrollController.addListener(() => pageScrollOffsetNotifier.value = pageScrollController.offset);
    });
  }

  late final ScrollController pageScrollController;
  late final PageController pageController;
  late final ValueNotifier<double> pageScrollOffsetNotifier;

  // only use for pages layout.
  late final ValueNotifier<int?> currentPageIndexNotifier;
  final ValueNotifier<bool> draggingNotifier = ValueNotifier(false);

  StoryPageObjectsMap pagesMap = StoryPageObjectsMap();

  int get pagesCount => draftContent()?.richPages?.length ?? 0;
  bool get canDeletePage => pagesCount > 1;

  late bool _managingPage = false;
  bool get managingPage => _managingPage;

  void toggleManagingPage() {
    _managingPage = !_managingPage;
    notifyListeners();

    if (_managingPage) FocusManager.instance.primaryFocus?.unfocus();
  }

  double _headerHeight = 0;
  void setHeaderHeight(double height) => _headerHeight = height;

  Future<void> scrollToPage(int pageId) async {
    double? itemPosition = getPagePosition(pageId);

    if (itemPosition != null) {
      double destination = itemPosition - _headerHeight;
      destination = max(0, min(destination, pageScrollController.position.maxScrollExtent));
      int pageIndex = draftContent()?.richPages?.indexWhere((e) => e.id == pageId) ?? -1;

      if (pageIndex == 0) {
        await pageScrollController.animateTo(
          0.0,
          duration: Durations.long4,
          curve: Curves.fastLinearToSlowEaseIn,
        );
      } else {
        await pageScrollController.animateTo(
          destination,
          duration: Durations.medium3,
          curve: Curves.fastLinearToSlowEaseIn,
        );
      }
    }
  }

  double? getPagePosition(int pageId) {
    double scrollOffset = max(0.0, pageScrollController.offset);
    final renderBox = pagesMap[pageId]?.key.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.localToGlobal(Offset(0.0, scrollOffset)).dy;
  }

  void dispose() {
    pageScrollController.dispose();
    pageScrollOffsetNotifier.dispose();
    pageController.dispose();
    draggingNotifier.dispose();
    currentPageIndexNotifier.dispose();
    pagesMap.dispose();
  }
}
