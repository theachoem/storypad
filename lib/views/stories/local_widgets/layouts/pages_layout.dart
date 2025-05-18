part of '../story_pages_builder.dart';

class _PagesLayout extends StatelessWidget {
  const _PagesLayout({
    required this.builder,
  });

  final StoryPagesBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: builder.padding,
      child: Column(
        children: [
          if (builder.header != null) builder.header!,
          buildContainer(
            context: context,
            child: buildPageView(),
          ),
          if (!builder.readOnly) builder._buildAddButton(),
        ],
      ),
    );
  }

  Widget buildContainer({
    required BuildContext context,
    required Widget child,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(12.0),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(8.0),
            left: Radius.circular(2.0),
          ),
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
            right: BorderSide(color: Theme.of(context).dividerColor),
            bottom: BorderSide(color: Theme.of(context).dividerColor),
            left: BorderSide(
              width: 4.0,
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
        child: child,
      ),
    );
  }

  PageView buildPageView() {
    return PageView.builder(
      controller: builder.pageController,
      itemCount: builder.pages.length,
      itemBuilder: (context, index) {
        return SpDefaultScrollController(
          builder: (context, scrollController) {
            return Scrollbar(
              controller: scrollController,
              interactive: true,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: 1.0,
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      clipBehavior: Clip.none,
                      controller: scrollController,
                      child: builder.buildPage(
                        builder.pages[index],
                        context,
                        showBorder: false,
                      ),
                    ),
                    buildPageNumber(index, context),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildPageNumber(int index, BuildContext context) {
    return Positioned(
      right: 8.0,
      bottom: 8.0,
      child: RichText(
        text: TextSpan(
          text: "${index + 1}",
          style: TextTheme.of(context).bodySmall,
          children: [
            TextSpan(
              text: " / ${builder.storyContent.richPages?.length}",
              style: TextTheme.of(context)
                  .bodySmall
                  ?.copyWith(color: ColorScheme.of(context).onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
