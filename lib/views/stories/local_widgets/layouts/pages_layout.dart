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
    pageOffset.value = widget.builder.pageController?.offset ?? 0.0;
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
            SingleChildScrollView(
              clipBehavior: Clip.none,
              padding: widget.builder.padding,
              child: Column(
                children: [
                  if (widget.builder.headerBuilder != null) buildHeader(index, screenWidth),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 200),
                    child: widget.builder.buildPage(
                      widget.builder.pages[index],
                      context,
                      smallPage: false,
                    ),
                  ),
                  widget.builder._buildAddButton(),
                ],
              ),
            ),
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
          itemIndex: pageIndex,
          controller: widget.builder.pageController!,
          width: screenWidth,
        );

        return Column(
          children: [
            Transform(
              transform: Matrix4.identity()
                ..spTranslate(datas.translateX1)
                ..spTranslate(datas.translateX2 ?? 0),
              child: Opacity(
                opacity: datas.opacity,
                child: child!,
              ),
            ),
            Transform(
              transform: Matrix4.identity()..spTranslate(offset - pageIndex * screenWidth),
              child: Opacity(
                opacity: datas.opacity,
                child: const Padding(
                  padding: EdgeInsetsGeometry.only(top: 8.0),
                  child: Divider(height: 1, indent: 0.0, endIndent: 0.0),
                ),
              ),
            ),
          ],
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
