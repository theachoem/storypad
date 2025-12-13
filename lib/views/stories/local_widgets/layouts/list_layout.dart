part of '../story_pages_builder.dart';

class _ListLayout extends StatelessWidget {
  const _ListLayout({
    required this.builder,
  });

  final StoryPagesBuilder builder;

  @override
  Widget build(BuildContext context) {
    int itemCount = builder.pages.length;

    return ListView.separated(
      controller: builder.pageScrollController,
      padding: builder.padding,
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: builder.spacing),
      itemBuilder: (context, index) {
        final page = builder.pages[index];

        return Column(
          children: [
            if (index == 0 && builder.headerBuilder != null) ...[
              builder.headerBuilder!(builder.pages[0]),
              SizedBox(height: builder.spacing),
            ],
            Padding(
              padding: EdgeInsets.symmetric(horizontal: builder.spacing),
              child: builder.buildPage(page, context, smallPage: true),
            ),
            if (index == itemCount - 1) ...[
              SizedBox(height: builder.spacing),
              builder._buildAddButton(),
            ],
          ],
        );
      },
    );
  }
}
