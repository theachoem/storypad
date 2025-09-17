part of '../story_pages_builder.dart';

class _PagesLayout extends StatefulWidget {
  const _PagesLayout({
    required this.builder,
  });

  final StoryPagesBuilder builder;

  @override
  State<_PagesLayout> createState() => _PagesLayoutState();
}

class _PagesLayoutState extends State<_PagesLayout> {
  bool get keyboardOpened => widget.builder.viewInsets.bottom > 100;

  final ValueNotifier<double> pageOffset = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setPageOffset();
    });

    widget.builder.pageController?.addListener(_setPageOffset);
  }

  void _setPageOffset() {
    pageOffset.value = widget.builder.pageController?.page ?? 0.0;
  }

  @override
  void dispose() {
    pageOffset.dispose();
    widget.builder.pageController?.removeListener(_setPageOffset);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return PageView.builder(
      controller: widget.builder.pageController,
      itemCount: widget.builder.pages.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            SpDefaultScrollController(builder: (context, scrollController) {
              return Scrollbar(
                controller: scrollController,
                interactive: true,
                child: SingleChildScrollView(
                  clipBehavior: Clip.none,
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    bottom: keyboardOpened ? widget.builder.viewInsets.bottom + 16.0 : 16.0,
                  ),
                  child: Column(
                    children: [
                      if (widget.builder.headerBuilder != null) buildHeader(index, screenWidth),
                      widget.builder.buildPage(
                        widget.builder.pages[index],
                        context,
                        smallPage: false,
                      ),
                      widget.builder._buildAddButton(),
                    ],
                  ),
                ),
              );
            }),
            buildPageNumber(index, context),
          ],
        );
      },
    );
  }

  Widget buildHeader(int pageIndex, double screenWidth) {
    return ValueListenableBuilder(
      valueListenable: pageOffset,
      child: widget.builder.headerBuilder!(widget.builder.pages[pageIndex]),
      builder: (context, offset, child) {
        SpPageViewDatas datas = SpPageViewDatas.fromOffset(
          pageOffset: offset,
          itemIndex: pageIndex,
          controller: widget.builder.pageController!,
          width: screenWidth,
        );

        return Transform(
          transform: Matrix4.identity()
            ..spTranslate(datas.translateX1)
            ..spTranslate(datas.translateX2 ?? 0),
          child: Opacity(
            opacity: datas.opacity,
            child: child,
          ),
        );
      },
    );
  }

  Widget buildPageNumber(int index, BuildContext context) {
    return Positioned(
      right: 16.0,
      bottom: MediaQuery.of(context).padding.bottom + 16.0,
      child: RichText(
        text: TextSpan(
          text: "${index + 1}",
          style: TextTheme.of(context).bodySmall,
          children: [
            TextSpan(
              text: " / ${widget.builder.storyContent.richPages?.length}",
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
