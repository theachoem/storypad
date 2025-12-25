part of '../home_view_model.dart';

class _HomeScrollInfo {
  final HomeViewModel Function() viewModel;
  final ScrollController scrollController = ScrollController();

  ValueNotifier<int?> scrollingToStoryIdNotifier = ValueNotifier(null);

  bool _scrolling = false;
  double extraExpandedHeight = 0;
  List<GlobalKey> storyKeys = [];
  List<GlobalKey> pinnedStoryKeys = [];

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

  void setupStoryKeys(List<StoryDbModel> stories, List<StoryDbModel> pinnedStories) {
    storyKeys = List.generate(stories.length, (_) => GlobalKey());
    pinnedStoryKeys = List.generate(pinnedStories.length, (_) => GlobalKey());
  }

  void setExtraExpandedHeight(double extra) {
    if (extraExpandedHeight == extra) return;

    extraExpandedHeight = extra;
    viewModel().notifyListeners();
  }

  void _listener() {
    if (_scrolling) return;
    final stories = viewModel().stories?.items ?? [];

    int? visibleIndex;

    // This listener only for tab change, so we only check unpinned stories.
    for (int i = 0; i < storyKeys.length; i++) {
      if (storyKeys[i].currentContext == null) continue;

      final context = storyKeys[i].currentContext;
      if (context != null) {
        double expandedHeight = appBar(context).getExpandedHeight();
        double scrollOffset = max(0.0, scrollController.offset - expandedHeight + MediaQuery.of(context).padding.top);

        final renderBox = context.findRenderObject() as RenderBox?;
        double? itemPosition = renderBox?.localToGlobal(Offset(0.0, scrollOffset)).dy;

        if (itemPosition != null && itemPosition > scrollOffset + 48) {
          visibleIndex = i;
          break;
        }
      }
    }

    if (visibleIndex != null) {
      int? month = stories.elementAt(visibleIndex).month;
      int monthIndex = months.indexWhere((e) => month == e);
      DefaultTabController.of(storyKeys[visibleIndex].currentContext!).animateTo(monthIndex);
    }
  }

  List<GlobalKey<State<StatefulWidget>>> getKeys(bool? pinned) {
    return pinned == true ? pinnedStoryKeys : storyKeys;
  }

  GlobalKey<State<StatefulWidget>>? getKeyForStoryIndex(bool? pinned, int storyIndex) {
    return getKeys(pinned)[storyIndex];
  }

  StoryDbModel? findStoryById(int storyId) {
    final allStories = [
      ...viewModel().stories?.items ?? [],
      ...viewModel().pinnedStories?.items ?? [],
    ];
    return allStories.where((e) => e.id == storyId).firstOrNull;
  }

  Future<void> moveToStory({
    required int targetStoryId,
  }) async {
    final story = findStoryById(targetStoryId);
    if (story == null) return;

    int targetStoryIndex = story.pinned == true
        ? viewModel().pinnedStories?.items.indexWhere((e) => e.id == targetStoryId) ?? -1
        : viewModel().stories?.items.indexWhere((e) => e.id == targetStoryId) ?? -1;
    if (targetStoryIndex == -1) return;

    scrollingToStoryIdNotifier.value = targetStoryId;
    await moveToStoryIndex(targetStoryIndex: targetStoryIndex, pinned: story.pinned == true);

    int? month = story.month;
    int monthIndex = months.indexWhere((e) => month == e);

    // for pinned, month tab should be first tab (0)
    final context = getKeyForStoryIndex(story.pinned, targetStoryIndex)?.currentContext;
    if (context != null && context.mounted) {
      DefaultTabController.of(context).animateTo(story.pinned == true ? 0 : monthIndex);
    }

    await Future.delayed(Durations.medium2, () {
      scrollingToStoryIdNotifier.value = null;
    });
  }

  Future<void> moveToMonthIndex({
    required int targetMonthIndex,
    required BuildContext context,
  }) async {
    List<StoryDbModel> stories = viewModel().stories?.items ?? [];

    int targetStoryIndex = -1;
    if (targetMonthIndex >= 0 && targetMonthIndex < months.length) {
      targetStoryIndex = stories.indexWhere((e) => e.month == months[targetMonthIndex]);
    }

    if (targetStoryIndex == -1) return;

    await moveToStoryIndex(
      targetStoryIndex: targetStoryIndex,
      pinned: false,
    );
  }

  Future<void> moveToStoryIndex({
    required int targetStoryIndex,
    required bool pinned,
  }) async {
    _scrolling = true;

    final allStoryKeys = [...pinnedStoryKeys, ...storyKeys];
    final globalTargetIndex = pinned ? targetStoryIndex : pinnedStoryKeys.length + targetStoryIndex;
    final targetStoryKey = allStoryKeys.elementAt(globalTargetIndex);

    if (globalTargetIndex < 0 || globalTargetIndex >= allStoryKeys.length) {
      _scrolling = false;
      return;
    }

    // Progressively jump to visible keys until target becomes visible
    int maxAttempts = 100; // Safety limit to avoid infinite loops
    int attempts = 0;

    while (targetStoryKey.currentContext == null && attempts < maxAttempts) {
      attempts++;

      // Find all currently visible keys
      List<int> visibleIndices = [];
      for (int i = 0; i < allStoryKeys.length; i++) {
        if (allStoryKeys[i].currentContext != null) {
          visibleIndices.add(i);
        }
      }

      if (visibleIndices.isEmpty) break;

      // Determine direction and find nearest visible key
      bool isMovingForward = visibleIndices.every((index) => globalTargetIndex > index);
      int nearestIndex = isMovingForward ? visibleIndices.last : visibleIndices.first;

      // Jump to nearest visible key (no animation) to trigger rendering of more items
      final nearestKey = allStoryKeys[nearestIndex];
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
    if (targetStoryKey.currentContext != null) {
      await Scrollable.ensureVisible(
        targetStoryKey.currentContext!,
        duration: Durations.medium3,
        curve: Curves.ease,
      );
    }

    _scrolling = false;
  }
}
