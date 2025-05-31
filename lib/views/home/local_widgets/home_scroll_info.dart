part of '../home_view_model.dart';

class _HomeScrollInfo {
  final HomeViewModel Function() viewModel;
  final ScrollController scrollController = ScrollController();

  bool _scrolling = false;
  double extraExpandedHeight = 0;
  List<GlobalKey> storyKeys = [];

  _HomeScrollAppBarInfo appBar(BuildContext context) =>
      _HomeScrollAppBarInfo(context: context, extraExpandedHeight: extraExpandedHeight);

  _HomeScrollInfo({
    required this.viewModel,
  }) {
    scrollController.addListener(_listener);
  }

  void dispose() {
    scrollController.dispose();
  }

  void setupStoryKeys(List<StoryDbModel> stories) {
    storyKeys = List.generate(stories.length, (_) => GlobalKey());
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
      int monthIndex = viewModel().months.indexWhere((e) => month == e);
      DefaultTabController.of(storyKeys[visibleIndex].currentContext!).animateTo(monthIndex);
    }
  }

  Future<void> moveToMonthIndex({
    required List<int> months,
    required int targetMonthIndex,
    required BuildContext context,
  }) async {
    _scrolling = true;
    List<StoryDbModel> stories = viewModel().stories?.items ?? [];

    int targetStoryIndex = -1;
    if (targetMonthIndex >= 0 && targetMonthIndex < months.length) {
      targetStoryIndex = stories.indexWhere((e) => e.month == months[targetMonthIndex]);
    }

    if (targetStoryIndex == -1) {
      _scrolling = false;
      return;
    }

    if (targetStoryIndex == 0) {
      await scrollController.animateTo(0.0, duration: Durations.long4, curve: Curves.fastLinearToSlowEaseIn);
      _scrolling = false;
      return;
    }

    final targetStoryKey = storyKeys.elementAt(targetStoryIndex);
    (bool, int) result = _getScrollInfo(storyKeys, months, stories, targetMonthIndex);

    bool isMovingRight = result.$1;
    int nearestToTargetStoryIndex = result.$2;

    if (targetStoryKey.currentContext == null) {
      if (isMovingRight) {
        for (int i = nearestToTargetStoryIndex; i <= targetStoryIndex; i++) {
          final visibleKey = storyKeys[i];
          final nextVisibleKey = (i + 1 < storyKeys.length) ? storyKeys[i + 1] : null;

          if (visibleKey.currentContext == null) continue;
          if (i != targetStoryIndex && nextVisibleKey?.currentContext != null) continue;

          await Scrollable.ensureVisible(
            visibleKey.currentContext!,
            duration: i == targetStoryIndex ? Durations.medium3 : Durations.short1,
            curve: i == targetStoryIndex ? Curves.ease : Curves.linear,
          );
        }
      } else {
        for (int i = nearestToTargetStoryIndex; i >= targetStoryIndex; i--) {
          final visibleKey = storyKeys[i];
          final nextVisibleKey = i > 0 ? storyKeys[i - 1] : null;

          if (visibleKey.currentContext == null) continue;
          if (i != targetStoryIndex && nextVisibleKey?.currentContext != null) continue;

          await Scrollable.ensureVisible(
            visibleKey.currentContext!,
            duration: i == targetStoryIndex ? Durations.medium3 : Durations.short1,
            curve: i == targetStoryIndex ? Curves.ease : Curves.linear,
          );
        }
      }
    } else {
      await Scrollable.ensureVisible(
        targetStoryKey.currentContext!,
        duration: Durations.medium3,
        curve: Curves.ease,
      );
    }

    _scrolling = false;
  }

  (bool, int) _getScrollInfo(
    List<GlobalKey<State<StatefulWidget>>> storyKeys,
    List<int> months,
    List<StoryDbModel> stories,
    int targetMonthIndex,
  ) {
    List<int> visibleStoryIndexes = [];

    for (int i = 0; i < storyKeys.length; i++) {
      if (storyKeys[i].currentContext != null) visibleStoryIndexes.add(i);
    }

    Set<int> visibleMonthIndexs = visibleStoryIndexes.map((index) {
      return months.indexWhere((month) => month == stories[index].month);
    }).toSet();

    bool isMovingRight = visibleMonthIndexs.every((monthIndex) => targetMonthIndex > monthIndex);
    return (isMovingRight, isMovingRight ? visibleStoryIndexes.last : visibleStoryIndexes.first);
  }
}
