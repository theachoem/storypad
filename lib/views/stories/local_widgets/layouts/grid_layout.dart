part of '../story_pages_builder.dart';

class _GridLayout extends StatelessWidget {
  const _GridLayout({
    required this.builder,
  });

  final StoryPagesBuilder builder;

  @override
  Widget build(BuildContext context) {
    int itemCount = builder.pages.length;

    return ListView(
      controller: builder.pageScrollController,
      padding: builder.padding,
      children: [
        if (builder.headerBuilder != null) builder.headerBuilder!(builder.pages[0]),
        Padding(
          padding: EdgeInsets.all(builder.spacing),
          child: StaggeredGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: builder.spacing,
            crossAxisSpacing: builder.spacing,
            children: [
              for (int i = 0; i < itemCount; i++)
                StaggeredGridTile.fit(
                  crossAxisCellCount: 1,
                  child: builder.buildPage(builder.pages[i], context, smallPage: true),
                ),
            ],
          ),
        ),
        SizedBox(height: builder.spacing),
        builder._buildAddButton(),
      ],
    );
  }
}
