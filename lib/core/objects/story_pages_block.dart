import 'package:storypad/core/objects/story_page_object.dart';

class StoryPagesBlock {
  List<StoryPageObject> pages;

  StoryPagesBlock({
    required this.pages,
  }) : assert(pages.isNotEmpty);

  static List<StoryPagesBlock> buildBlocks(List<StoryPageObject> pages) {
    List<StoryPagesBlock> blocks = [];

    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];

      if (blocks.lastOrNull?.accept(page) == true) {
        blocks[blocks.length - 1].pages.add(page);
      } else {
        blocks.add(StoryPagesBlock(pages: [page]));
      }
    }

    return blocks;
  }

  void addPage(StoryPageObject page) {
    pages.add(page);
    assert(pages.length <= 3);
  }

  bool accept(StoryPageObject newPage) {
    final firstPage = pages.first;
    final lastPage = pages.last;

    if (pages.length == 1 && lastPage.matched(2 / 1)) {
      return false;
    }

    if (pages.length == 2 && lastPage.matched(1 / 2)) {
      return false;
    }

    if (pages.length == 2 && firstPage.matched(1 / 1) && lastPage.matched(1 / 1)) {
      if (newPage.matched(1 / 2)) return true;
      return false;
    }

    if (pages.length == 1 && lastPage.matched(1 / 1)) {
      if (newPage.matched(1 / 1)) return true;
      if (newPage.matched(1 / 2)) return true;
    }

    if (pages.length == 1 && lastPage.matched(1 / 2)) {
      if (newPage.matched(1 / 1)) return true;
      if (newPage.matched(1 / 2)) return true;
    }

    if (pages.length == 2 && lastPage.matched(1 / 1)) {
      if (newPage.matched(1 / 1)) return true;
    }

    return false;
  }
}
