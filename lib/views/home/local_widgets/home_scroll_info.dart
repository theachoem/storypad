part of '../home_view_model.dart';

class _HomeScrollInfo {
  final HomeViewModel Function() viewModel;
  final ScrollController scrollController = ScrollController();

  ValueNotifier<int?> scrollingToStoryIdNotifier = ValueNotifier(null);

  bool _scrolling = false;
  double extraExpandedHeight = 0;

  List<HomeItem> get items => viewModel().items;
  List<int> get months => viewModel().months;

  _HomeScrollAppBarInfo appBar(BuildContext context) =>
      _HomeScrollAppBarInfo(context: context, extraExpandedHeight: extraExpandedHeight);

  _HomeScrollInfo({
    required this.viewModel,
  }) {
    scrollController.addListener(_listener);
  }

  void dispose() {
    scrollController.dispose();
    scrollingToStoryIdNotifier.dispose();
  }

  void setExtraExpandedHeight(double extra) {
    if (extraExpandedHeight == extra) return;

    extraExpandedHeight = extra;
    viewModel().notifyListeners();
  }

  void _listener() {
    if (_scrolling) return;

    // No scroll-position-based paging trigger here: HomeViewModel.reload()
    // already eagerly works through remaining pages in the background right
    // after page 1 (see _prefetchRemainingPages), and HomeLoadMoreItem
    // triggers a (cheap, joined) fetch if its tile is ever built before that
    // background work catches up. This listener only for tab change, so we
    // only check unpinned stories.
    for (final item in items) {
      if (item is! HomeStoryItem) continue;

      final context = item.key.currentContext;
      if (context == null) continue;

      double expandedHeight = appBar(context).getExpandedHeight();
      double scrollOffset = max(0.0, scrollController.offset - expandedHeight + MediaQuery.of(context).padding.top);

      final renderBox = context.findRenderObject() as RenderBox?;
      double? itemPosition = renderBox?.localToGlobal(Offset(0.0, scrollOffset)).dy;

      if (itemPosition != null && itemPosition > scrollOffset + 48) {
        int monthIndex = months.indexWhere((e) => e == item.story.month);
        DefaultTabController.of(context).animateTo(monthIndex);
        break;
      }
    }
  }

  Future<void> scrollToTop() async {
    // No need to set _scrolling = true here because we want to trigger
    // the listener so tab will be reset to first tab.
    await scrollController.animateTo(
      0,
      duration: Durations.medium3,
      curve: Curves.ease,
    );
  }

  Future<void> moveToStory({
    required int targetStoryId,
  }) async {
    final targetIndex = items.indexWhere((item) => item.storyId == targetStoryId);
    if (targetIndex == -1) return;

    final item = items[targetIndex];
    final story = switch (item) {
      HomeStoryItem(:final story) => story,
      HomePinnedStoryItem(:final story) => story,
      _ => null,
    };
    if (story == null) return;

    scrollingToStoryIdNotifier.value = targetStoryId;
    await moveToItemIndex(targetIndex);

    int monthIndex = months.indexWhere((e) => e == story.month);
    final targetTabIndex = item is HomePinnedStoryItem ? 0 : monthIndex;

    // for pinned, month tab should be first tab (0); -1 means [months]
    // doesn't have this story's month (shouldn't happen — HomeViewModel
    // keeps it fresh via _refreshMonthsForYear — but don't feed
    // TabController an invalid index if it somehow does).
    final context = item.key.currentContext;
    if (context != null && context.mounted && targetTabIndex != -1) {
      DefaultTabController.of(context).animateTo(targetTabIndex);
    }

    await Future.delayed(Durations.medium2, () {
      scrollingToStoryIdNotifier.value = null;
    });
  }

  Future<void> moveToMonthIndex({
    required int targetMonthIndex,
    required BuildContext context,
  }) async {
    if (targetMonthIndex < 0 || targetMonthIndex >= months.length) return;
    final targetMonth = months[targetMonthIndex];

    // Prefer the month's recap tile (if it has one)
    // over its first story tile, so tapping a month tab lands on the
    // recap summary rather than scrolling past it.
    int findTargetIndex() {
      final recapIndex = items.indexWhere((item) => item is HomeMonthRecapItem && item.story.month == targetMonth);
      if (recapIndex != -1) return recapIndex;
      return items.indexWhere((item) => item is HomeStoryItem && item.story.month == targetMonth);
    }

    int targetIndex = findTargetIndex();

    // Target month may not have loaded yet (pagination hasn't reached it).
    // Pages load strictly newest-first, so loading forward always converges.
    if (targetIndex == -1 && viewModel().hasMoreStories) {
      AppLogger.d('🚧 $runtimeType#moveToMonthIndex month $targetMonth not loaded yet, loading forward');
    }
    while (targetIndex == -1 && viewModel().hasMoreStories) {
      await viewModel().loadNextPage();
      targetIndex = findTargetIndex();
    }
    if (targetIndex == -1) {
      AppLogger.d('🚧 $runtimeType#moveToMonthIndex gave up: month $targetMonth not found after loading all pages');
      return;
    }

    await moveToItemIndex(targetIndex);
  }

  /// Progressively jump to visible keys until target becomes visible, since
  /// `SliverList.builder` only builds widgets near the viewport so far-away
  /// GlobalKeys have no `currentContext` until scrolled near.
  Future<void> moveToItemIndex(int targetIndex) async {
    _scrolling = true;

    final keys = items.map((e) => e.key).toList();

    if (targetIndex < 0 || targetIndex >= keys.length) {
      _scrolling = false;
      return;
    }

    final targetKey = keys[targetIndex];

    // Safety limit to avoid infinite loops
    int maxAttempts = 100;
    int attempts = 0;

    while (targetKey.currentContext == null && attempts < maxAttempts) {
      attempts++;

      // Find all currently visible keys
      List<int> visibleIndices = [];
      for (int i = 0; i < keys.length; i++) {
        if (keys[i].currentContext != null) {
          visibleIndices.add(i);
        }
      }

      if (visibleIndices.isEmpty) break;

      // Determine direction and find nearest visible key
      bool isMovingForward = visibleIndices.every((index) => targetIndex > index);
      int nearestIndex = isMovingForward ? visibleIndices.last : visibleIndices.first;

      // Jump to nearest visible key (no animation) to trigger rendering of more items
      final nearestKey = keys[nearestIndex];
      if (nearestKey.currentContext != null) {
        await Scrollable.ensureVisible(
          nearestKey.currentContext!,
          duration: Duration.zero,
          curve: Curves.ease,
        );

        Completer<void> completer = Completer<void>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          completer.complete();
        });
        await completer.future;
      }
    }

    // Finally, smoothly scroll to target if it's now visible
    if (targetKey.currentContext != null) {
      await Scrollable.ensureVisible(
        targetKey.currentContext!,
        duration: Durations.medium3,
        curve: Curves.ease,
      );
    }

    _scrolling = false;
  }
}
