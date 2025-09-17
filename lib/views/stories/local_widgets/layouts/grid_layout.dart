part of '../story_pages_builder.dart';

class _GridLayout extends StatelessWidget {
  const _GridLayout({
    required this.builder,
  });

  final StoryPagesBuilder builder;

  @override
  Widget build(BuildContext context) {
    List<StoryPagesBlock> blocks = StoryPagesBlock.buildBlocks(builder.pages);

    return ListView(
      controller: builder.pageScrollController,
      padding: builder.padding,
      children: [
        if (builder.headerBuilder != null) builder.headerBuilder!(builder.pages[0]),
        buildLayout(blocks, context),
      ],
    );
  }

  Widget buildLayout(List<StoryPagesBlock> blocks, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: builder.spacing,
        children: List.generate(
          blocks.length,
          (index) {
            // Each block can't have more than 3 pages,
            // we validate in assertion.
            //
            // I prefer explicit checking conditions.
            // Currently only support following layouts.
            final block = blocks[index];

            final firstPage = block.pages.elementAt(0);
            final secondPageOrNull = block.pages.elementAtOrNull(1);
            final thirdPageOrNull = block.pages.elementAtOrNull(2);

            if (firstPage.matched(1 / 2) &&
                secondPageOrNull?.matched(1 / 1) == true &&
                thirdPageOrNull?.matched(1 / 1) == true) {
              return builder._buildGrid1LayoutBlock(
                context,
                firstPage,
                secondPageOrNull!,
                thirdPageOrNull!,
              );
            }

            if (firstPage.matched(1 / 1) &&
                secondPageOrNull?.matched(1 / 1) == true &&
                thirdPageOrNull?.matched(1 / 2) == true) {
              return builder._buildGrid2LayoutBlock(
                context,
                firstPage,
                secondPageOrNull!,
                thirdPageOrNull!,
              );
            }

            if (firstPage.crossAxisCount == 1 && secondPageOrNull?.crossAxisCount == 1 && thirdPageOrNull == null) {
              return builder._buildRowLayoutBlock(
                context,
                firstPage,
                secondPageOrNull!,
              );
            }

            return builder._buildColumnLayoutBlock(block, context);
          },
        )..add(builder._buildAddButton()),
      ),
    );
  }
}
