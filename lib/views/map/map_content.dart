part of 'map_view.dart';

class _MapContent extends StatelessWidget {
  const _MapContent(this.viewModel);

  final MapViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _buildMapLayer(context),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SpMapSideButton(
                    icon: SpIcons.keyboardLeft,
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      const Spacer(),
                      Column(
                        mainAxisSize: .min,
                        spacing: 8.0,
                        children: <Widget>[
                          SpMapSideButton(
                            icon: viewModel.mapStyle == SpMapStyle.streets ? SpIcons.map : SpIcons.satellite,
                            tooltip: 'Map style',
                            onPressed: () =>
                                viewModel.setMapStyle(viewModel.mapStyle == .streets ? .satellite : .streets),
                          ),
                          SpMapSideButton(
                            icon: SpIcons.myLocation,
                            tooltip: 'Current location',
                            onPressed: () => viewModel.goToCurrentLocation(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLayer(BuildContext context) {
    switch (viewModel.mapRenderer) {
      case SpMapRenderer.googleMaps:
        return SpGoogleMap<MapStoryObject>(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8.0),
          mapController: viewModel.mapController,
          initialCamera: viewModel.initialSpMapCamera,
          mapStyle: viewModel.mapStyle,
          markers: viewModel.mapMarkers,
          onViewportChanged: viewModel.handleViewportChanged,
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
      width: 62.0,
      height: 74.0,
      child: CustomPaint(
        painter: const _FlutterMapStoryMarkerFramePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 14.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11.0),
            child: DecoratedBox(
              decoration: BoxDecoration(color: color),
              child: imageFile != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
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
    return Center(
      child: Icon(
        SpIcons.text,
        color: Colors.white,
        size: 22.0,
      ),
    );
  }
}

class _FlutterMapStoryMarkerFramePainter extends CustomPainter {
  const _FlutterMapStoryMarkerFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Path markerPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(2.0, 2.0, 58.0, 62.0),
          const Radius.circular(14.0),
        ),
      )
      ..moveTo(size.width / 2 - 8.0, 61.0)
      ..lineTo(size.width / 2, 70.0)
      ..lineTo(size.width / 2 + 8.0, 61.0)
      ..close();

    canvas.drawShadow(markerPath, Colors.black.withValues(alpha: 0.32), 7.0, true);
    canvas.drawPath(markerPath, Paint()..color = Colors.white);

    final RRect contentRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(6.0, 6.0, 50.0, 54.0),
      const Radius.circular(11.0),
    );
    canvas.drawRRect(
      contentRRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.86)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant _FlutterMapStoryMarkerFramePainter oldDelegate) {
    return false;
  }
}

class _MapStoryMarkerIconFactory {
  const _MapStoryMarkerIconFactory._();

  static const double _logicalWidth = 62.0;
  static const double _logicalHeight = 74.0;
  static const double _cardHeight = 62.0;

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
      width: _logicalWidth,
      height: _logicalHeight,
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

    final ui.Path markerPath = ui.Path()
      ..addRRect(
        ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTWH(2.0, 2.0, _logicalWidth - 4.0, _cardHeight),
          const ui.Radius.circular(14.0),
        ),
      )
      ..moveTo(_logicalWidth / 2 - 8.0, _cardHeight - 1.0)
      ..lineTo(_logicalWidth / 2, _logicalHeight - 4.0)
      ..lineTo(_logicalWidth / 2 + 8.0, _cardHeight - 1.0)
      ..close();

    canvas.drawShadow(markerPath, Colors.black.withValues(alpha: 0.32), 7.0, true);
    canvas.drawPath(markerPath, ui.Paint()..color = Colors.white);

    final ui.RRect contentRRect = ui.RRect.fromRectAndRadius(
      const ui.Rect.fromLTWH(6.0, 6.0, _logicalWidth - 12.0, _cardHeight - 8.0),
      const ui.Radius.circular(11.0),
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
        ..strokeWidth = 2.0,
    );

    final ui.Image markerImage = await recorder.endRecording().toImage(
      (_logicalWidth * pixelRatio).round(),
      (_logicalHeight * pixelRatio).round(),
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
