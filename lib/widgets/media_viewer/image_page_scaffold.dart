part of 'sp_media_viewer.dart';

/// A single image page: its own [Scaffold] with a zoomable [PhotoView] body,
/// an app bar, and an alt-text bottom bar. Tapping the center toggles the
/// app bar + bottom bar together; nothing here is shared with other pages.
class _ImagePageScaffold extends StatefulWidget {
  const _ImagePageScaffold({
    required this.item,
    required this.index,
    required this.total,
  });

  final SpMediaViewerItem item;
  final int index;
  final int total;

  @override
  State<_ImagePageScaffold> createState() => _ImagePageScaffoldState();
}

class _ImagePageScaffoldState extends State<_ImagePageScaffold> {
  bool controlsVisible = true;

  void _toggleControls() => setState(() => controlsVisible = !controlsVisible);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _Chrome(
          visible: controlsVisible,
          child: _buildAppBar(context, index: widget.index, total: widget.total, item: widget.item),
        ),
      ),
      bottomNavigationBar: _Chrome(
        visible: controlsVisible,
        child: _AltText(alt: widget.item.alt),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final item = widget.item;

    if (item.builder != null) {
      return PhotoView.customChild(
        heroAttributes: PhotoViewHeroAttributes(tag: item.tag),
        initialScale: PhotoViewComputedScale.contained * item.scale,
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        onTapUp: (context, details, value) => _toggleControls(),
        child: item.builder!(context, Image(image: item.provider!)),
      );
    }

    return PhotoView(
      heroAttributes: PhotoViewHeroAttributes(tag: item.tag),
      initialScale: PhotoViewComputedScale.contained * item.scale,
      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      imageProvider: item.provider,
      onTapUp: (context, details, value) => _toggleControls(),
      loadingBuilder: (context, event) {
        return const Center(
          child: CircularProgressIndicator.adaptive(),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return DecoratedBox(
          decoration: const BoxDecoration(color: Colors.black),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8.0,
              children: [
                const Icon(
                  Icons.broken_image,
                  color: _foregroundColor,
                  size: 40.0,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _foregroundColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AltText extends StatelessWidget {
  const _AltText({required this.alt});

  final String? alt;

  @override
  Widget build(BuildContext context) {
    bool hasAlt = alt?.trim().isNotEmpty == true;

    return AnimatedOpacity(
      opacity: hasAlt ? 1.0 : 0,
      curve: Curves.ease,
      duration: Durations.medium1,
      child: AnimatedContainer(
        duration: Durations.medium4,
        curve: Curves.ease,
        padding: const EdgeInsets.all(16.0)
            .copyWith(bottom: hasAlt ? 24.0 : 20.0)
            .add(
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black,
              Colors.black54,
              Colors.transparent,
            ],
          ),
        ),
        child: _buildContainer(context),
      ),
    );
  }

  Widget _buildContainer(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          color: Colors.white.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          child: Text(
            alt ?? '',
            style: TextTheme.of(context).bodyMedium?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
