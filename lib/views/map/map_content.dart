part of 'map_view.dart';

class _MapContent extends StatelessWidget {
  const _MapContent(this.viewModel);

  final MapViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButtonLocation: SpFabLocation.endFloat(context),
      floatingActionButton: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .end,
        children: [
          IconButton(
            tooltip: tr("button.switch_map_style"),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            icon: SpAnimatedIcons.fadeScale(
              duration: Durations.long1,
              firstChild: const Icon(SpIcons.map),
              secondChild: const Icon(SpIcons.satellite),
              showFirst: viewModel.mapStyle == SpMapStyle.streets,
            ),
            onPressed: () => viewModel.setMapStyle(viewModel.mapStyle == .streets ? .satellite : .streets),
          ),
          SpSingleStateWidget.listen(
            initialValue: false,
            builder: (context, loading, notifier) {
              return IconButton(
                tooltip: tr("button.move_to_current_location"),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                icon: loading
                    ? const SizedBox.square(
                        dimension: 24.0,
                        child: CircularProgressIndicator.adaptive(),
                      )
                    : const Icon(SpIcons.myLocation),
                onPressed: () async {
                  notifier.value = true;
                  await viewModel.goToCurrentLocation(context);
                  notifier.value = false;
                },
              );
            },
          ),
          const SizedBox(height: 4.0),
          FloatingActionButton(
            tooltip: tr("button.new_story"),
            child: const Icon(SpIcons.newStory),
            onPressed: () => viewModel.goToNewPage(),
          ),
        ],
      ),
      body: _buildMapLayer(context),
    );
  }

  Widget _buildMapLayer(BuildContext context) {
    if (!viewModel.isCameraResolved) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    final double topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 16.0;

    switch (viewModel.mapRenderer) {
      case SpMapRenderer.googleMap:
        return SpGoogleMap<MapStoryObject>(
          padding: EdgeInsets.only(
            top: topPadding,
            bottom: 112.0,
            left: MediaQuery.paddingOf(context).left,
            right: MediaQuery.paddingOf(context).right,
          ),
          mapController: viewModel.mapController,
          initialCamera: viewModel.initialSpMapCamera,
          mapStyle: viewModel.mapStyle,
          markers: viewModel.mapMarkers,
          showCurrentLocation: viewModel.showCurrentLocation,
          onViewportChanged: viewModel.handleViewportChanged,
          onMarkerTap: viewModel.onMarkerTap,
          onClusterTap: viewModel.onClusterTap,
          markerIconBuilder: (context, marker, pixelRatio) => _MapStoryMarkerIconFactory.create(
            context,
            marker,
            pixelRatio,
            imageFile: viewModel.firstAssetFileForStory(marker.data),
            color: viewModel.markerColorForStory(marker.data),
          ),
        );
      case SpMapRenderer.flutterMap:
        return SpFlutterMap<MapStoryObject>(
          mapController: viewModel.mapController,
          initialCamera: viewModel.initialSpMapCamera,
          mapStyle: viewModel.mapStyle,
          markers: viewModel.mapMarkers,
          onViewportChanged: viewModel.handleViewportChanged,
          showCurrentLocation: viewModel.showCurrentLocation,
          onMarkerTap: viewModel.onMarkerTap,
          onClusterTap: viewModel.onClusterTap,
          markerBuilder: (context, marker) => _FlutterMapStoryMarker(
            imageFile: viewModel.firstAssetFileForStory(marker.data),
            color: viewModel.markerColorForStory(marker.data),
          ),
        );
    }
  }
}

class _FlutterMapStoryMarker extends StatelessWidget {
  const _FlutterMapStoryMarker({
    required this.imageFile,
    required this.color,
  });

  final File? imageFile;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60.0,
      height: 60.0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 8.0,
              offset: const Offset(0.0, 3.0),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: DecoratedBox(
              decoration: BoxDecoration(color: color),
              child: imageFile != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          imageFile!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const _FlutterMapStoryIconPlaceholder(),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.14),
                          ),
                        ),
                      ],
                    )
                  : const _FlutterMapStoryIconPlaceholder(),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlutterMapStoryIconPlaceholder extends StatelessWidget {
  const _FlutterMapStoryIconPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        SpIcons.text,
        color: Colors.white,
        size: 22.0,
      ),
    );
  }
}

class _MapStoryMarkerIconFactory {
  const _MapStoryMarkerIconFactory._();

  static const double _logicalSize = 60.0;

  static Future<gm.BitmapDescriptor> create(
    BuildContext context,
    SpMapMarker<MapStoryObject> marker,
    double pixelRatio, {
    required File? imageFile,
    required Color color,
  }) async {
    final ui.Image? image = imageFile == null ? null : await _loadImage(imageFile);
    final Uint8List bytes = await _drawMarker(
      image: image,
      pixelRatio: pixelRatio,
      color: color,
    );

    return gm.BitmapDescriptor.bytes(
      bytes,
      imagePixelRatio: pixelRatio,
      width: _logicalSize,
      height: _logicalSize,
    );
  }

  static Future<ui.Image?> _loadImage(File imageFile) async {
    final Completer<ui.Image?> completer = Completer<ui.Image?>();
    final ImageStream stream = FileImage(imageFile).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(image.image);
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    stream.addListener(listener);
    return completer.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        stream.removeListener(listener);
        return null;
      },
    );
  }

  static Future<Uint8List> _drawMarker({
    required ui.Image? image,
    required double pixelRatio,
    required Color color,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.scale(pixelRatio);

    final ui.RRect cardRRect = ui.RRect.fromRectAndRadius(
      const ui.Rect.fromLTWH(1.0, 1.0, _logicalSize - 2.0, _logicalSize - 2.0),
      const ui.Radius.circular(14.0),
    );

    canvas.drawShadow(ui.Path()..addRRect(cardRRect), Colors.black.withValues(alpha: 0.24), 8.0, true);
    canvas.drawRRect(cardRRect, ui.Paint()..color = Colors.white);

    final ui.RRect contentRRect = ui.RRect.fromRectAndRadius(
      const ui.Rect.fromLTWH(5.0, 5.0, _logicalSize - 10.0, _logicalSize - 10.0),
      const ui.Radius.circular(10.0),
    );

    canvas.save();
    canvas.clipRRect(contentRRect);

    if (image != null) {
      paintImage(
        canvas: canvas,
        rect: contentRRect.outerRect,
        image: image,
        fit: BoxFit.cover,
      );
      canvas.drawRect(
        contentRRect.outerRect,
        ui.Paint()..color = Colors.black.withValues(alpha: 0.14),
      );
    } else {
      canvas.drawRect(
        contentRRect.outerRect,
        ui.Paint()..color = color,
      );
      _drawCenteredIcon(
        canvas: canvas,
        icon: SpIcons.text,
        color: Colors.white,
        size: 22.0,
        bounds: contentRRect.outerRect,
      );
    }

    canvas.restore();

    canvas.drawRRect(
      contentRRect,
      ui.Paint()
        ..color = Colors.white.withValues(alpha: 0.86)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final ui.Image markerImage = await recorder.endRecording().toImage(
      (_logicalSize * pixelRatio).round(),
      (_logicalSize * pixelRatio).round(),
    );
    final ByteData? byteData = await markerImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static void _drawCenteredIcon({
    required ui.Canvas canvas,
    required IconData icon,
    required Color color,
    required double size,
    required ui.Rect bounds,
  }) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: color,
          fontSize: size,
          letterSpacing: 0.0,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: bounds.width);

    textPainter.paint(
      canvas,
      ui.Offset(
        bounds.left + (bounds.width - textPainter.width) / 2,
        bounds.top + (bounds.height - textPainter.height) / 2,
      ),
    );
  }
}
