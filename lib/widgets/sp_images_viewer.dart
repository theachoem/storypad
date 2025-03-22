import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/google_drive/google_drive_service.dart';
import 'package:storypad/widgets/asset_db/sp_db_image_provider.dart';

class SpImageViewerProvider {
  final ImageProvider provider;
  final String tag;
  final String? alt;
  final double scale;
  final Widget Function(BuildContext, Image)? builder;

  SpImageViewerProvider({
    required this.provider,
    required this.alt,
    required this.tag,
    this.scale = 1,
    this.builder,
  });
}

class SpImagesViewer extends StatefulWidget {
  const SpImagesViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  final List<SpImageViewerProvider> images;
  final int initialIndex;

  factory SpImagesViewer.fromString({
    required List<String> images,
    required int initialIndex,
  }) {
    List<(String, ImageProvider)> providers = [];

    for (String imageUrl in images) {
      ImageProvider? imageProvider;

      if (imageUrl.startsWith('storypad://')) {
        imageProvider =
            SpDbImageProvider(assetLink: imageUrl, currentUser: GoogleDriveService.instance.googleSignIn.currentUser);
      } else if (imageUrl.startsWith('http')) {
        imageProvider = CachedNetworkImageProvider(imageUrl);
      } else if (File(imageUrl).existsSync()) {
        imageProvider = FileImage(File(imageUrl));
      }

      if (imageProvider == null) continue;
      providers.add((imageUrl, imageProvider));
    }

    return SpImagesViewer(
      initialIndex: providers.length != images.length ? 0 : initialIndex,
      images: providers.map((provider) {
        return SpImageViewerProvider(
          provider: provider.$2,
          tag: provider.$1,
          alt: null,
        );
      }).toList(),
    );
  }

  Future<void> show(BuildContext context) async {
    if (images.isEmpty) return;

    AnalyticsService.instance.logViewImages(
      imagesCount: images.length,
    );

    await context.pushTransparentRoute(
      this,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<SpImagesViewer> createState() => _SpImagesViewerState();
}

class _SpImagesViewerState extends State<SpImagesViewer> {
  late final PageController controller;
  late final ValueNotifier<int> currentIndexNotifier;

  @override
  void initState() {
    controller = PageController(
      initialPage: min(
        widget.initialIndex,
        widget.images.length - 1,
      ),
    );

    currentIndexNotifier = ValueNotifier(controller.initialPage);
    controller.addListener(() {
      if (controller.page != null && controller.page! % 1 == 0) {
        int index = controller.page?.toInt() ?? currentIndexNotifier.value;
        currentIndexNotifier.value = index % widget.images.length;
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    currentIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildDismissiblePage(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: buildAppBar(),
        extendBody: true,
        extendBodyBehindAppBar: true,
        bottomNavigationBar: _AltText(currentIndexNotifier: currentIndexNotifier, widget: widget),
        body: _Images(
          widget: widget,
          controller: controller,
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      automaticallyImplyLeading: false,
      title: _Title(currentIndexNotifier: currentIndexNotifier, widget: widget),
      actions: const [
        CloseButton(),
      ],
    );
  }

  Widget buildDismissiblePage({required Widget child}) {
    return DismissiblePage(
      backgroundColor: Colors.black12,
      onDismissed: () => Navigator.of(context).pop(),
      direction: DismissiblePageDismissDirection.vertical,
      isFullScreen: true,
      child: child,
    );
  }
}

class _Images extends StatelessWidget {
  const _Images({
    required this.widget,
    required this.controller,
  });

  final SpImagesViewer widget;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return PhotoViewGallery.builder(
      itemCount: widget.images.length,
      pageController: controller,
      loadingBuilder: (context, event) {
        return const Center(
          child: CircularProgressIndicator.adaptive(),
        );
      },
      builder: (context, index) {
        index = index % widget.images.length;

        final SpImageViewerProvider image = widget.images[index];

        if (image.builder != null) {
          return PhotoViewGalleryPageOptions.customChild(
            heroAttributes: PhotoViewHeroAttributes(tag: image.tag),
            initialScale: PhotoViewComputedScale.contained * image.scale,
            child: image.builder!(context, Image(image: image.provider)),
          );
        } else {
          return PhotoViewGalleryPageOptions(
            heroAttributes: PhotoViewHeroAttributes(tag: image.tag),
            initialScale: PhotoViewComputedScale.contained * image.scale,
            imageProvider: image.provider,
          );
        }
      },
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({
    required this.currentIndexNotifier,
    required this.widget,
  });

  final ValueNotifier<int> currentIndexNotifier;
  final SpImagesViewer widget;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: currentIndexNotifier,
      builder: (context, currentIndex, child) {
        return Text(
          '${currentIndex + 1}/${widget.images.length}',
          style: TextTheme.of(context).titleMedium?.copyWith(color: Colors.white),
        );
      },
    );
  }
}

class _AltText extends StatelessWidget {
  const _AltText({
    required this.currentIndexNotifier,
    required this.widget,
  });

  final ValueNotifier<int> currentIndexNotifier;
  final SpImagesViewer widget;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: currentIndexNotifier,
      builder: (context, currentIndex, child) {
        String? alt = widget.images[currentIndexNotifier.value].alt;
        bool hasAlt = alt?.trim().isNotEmpty == true;

        return AnimatedOpacity(
          opacity: hasAlt ? 1.0 : 0,
          curve: Curves.ease,
          duration: Durations.medium1,
          child: AnimatedContainer(
            duration: Durations.medium4,
            curve: Curves.ease,
            padding: const EdgeInsets.all(16.0).copyWith(bottom: hasAlt ? 24.0 : 20.0).add(
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
            child: buildContainer(alt, context),
          ),
        );
      },
    );
  }

  Widget buildContainer(String? alt, BuildContext context) {
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
