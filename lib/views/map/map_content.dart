part of 'map_view.dart';

class _MapContent extends StatelessWidget {
  const _MapContent(this.viewModel);

  final MapViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

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
                      if (viewModel.isPreparingMarkers) _MarkerPreparingPill(colorScheme: colorScheme),
                      const Spacer(),
                      Column(
                        mainAxisSize: .min,
                        spacing: 8.0,
                        children: <Widget>[
                          SpMapSideButton(
                            icon: SpIcons.refresh,
                            tooltip: 'Reset rotation',
                            onPressed: () => viewModel.resetRotation(),
                          ),
                          SpMapSideButton(
                            icon: viewModel.mapStyle == SpMapStyle.streets ? SpIcons.map : SpIcons.satellite,
                            tooltip: 'Map style',
                            onPressed: () {
                              SpMapStyleSheet(
                                mapStyle: viewModel.mapStyle,
                                onChanged: viewModel.setMapStyle,
                              ).show(context: context);
                            },
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
        return SpGoogleMap<MapJournalEntry>(
          mapController: viewModel.mapController,
          initialCamera: viewModel.initialSpMapCamera,
          mapStyle: viewModel.mapStyle,
          markers: viewModel.mapMarkers,
          onMarkerTap: (marker) => viewModel.handleEntryTap(context, marker.data),
          markerIconBuilder: _MapJournalMarkerIconFactory.create,
          onMarkersPreparing: viewModel.setMarkersPreparing,
        );
      case SpMapRenderer.flutterMap:
        if (viewModel.isPreparingMarkers) viewModel.setMarkersPreparing(false);
        return SpFlutterMap<MapJournalEntry>(
          mapController: viewModel.mapController,
          initialCamera: viewModel.initialSpMapCamera,
          mapStyle: viewModel.mapStyle,
          markers: viewModel.mapMarkers,
          onMarkerTap: (marker) => viewModel.handleEntryTap(context, marker.data),
          markerBuilder: (context, marker) => _FlutterMapJournalMarker(entry: marker.data),
        );
    }
  }
}

class _FlutterMapJournalMarker extends StatelessWidget {
  const _FlutterMapJournalMarker({required this.entry});

  final MapJournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62.0,
      height: 74.0,
      child: CustomPaint(
        painter: const _FlutterMapJournalMarkerFramePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 14.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11.0),
            child: DecoratedBox(
              decoration: BoxDecoration(color: entry.color),
              child: entry.hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Image.asset(
                          entry.imageAssetPath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _FlutterMapJournalTextPlaceholder(entry: entry),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.14),
                          ),
                        ),
                      ],
                    )
                  : _FlutterMapJournalTextPlaceholder(entry: entry),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlutterMapJournalTextPlaceholder extends StatelessWidget {
  const _FlutterMapJournalTextPlaceholder({required this.entry});

  final MapJournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        entry.markerText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.0,
        ),
      ),
    );
  }
}

class _FlutterMapJournalMarkerFramePainter extends CustomPainter {
  const _FlutterMapJournalMarkerFramePainter();

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
  bool shouldRepaint(covariant _FlutterMapJournalMarkerFramePainter oldDelegate) {
    return false;
  }
}

class _MapJournalMarkerIconFactory {
  const _MapJournalMarkerIconFactory._();

  static const double _logicalWidth = 62.0;
  static const double _logicalHeight = 74.0;
  static const double _cardHeight = 62.0;

  static Future<gm.BitmapDescriptor> create(
    BuildContext context,
    SpMapMarker<MapJournalEntry> marker,
    double pixelRatio,
  ) async {
    final MapJournalEntry entry = marker.data;
    final ui.Image? image = entry.imageAssetPath == null ? null : await _loadImage(entry.imageAssetPath!);
    final Uint8List bytes = await _drawMarker(
      entry: entry,
      image: image,
      pixelRatio: pixelRatio,
    );

    return gm.BitmapDescriptor.bytes(
      bytes,
      imagePixelRatio: pixelRatio,
      width: _logicalWidth,
      height: _logicalHeight,
    );
  }

  static Future<ui.Image?> _loadImage(String assetPath) async {
    final Completer<ui.Image?> completer = Completer<ui.Image?>();
    final ImageStream stream = AssetImage(assetPath).resolve(ImageConfiguration.empty);
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
    required MapJournalEntry entry,
    required ui.Image? image,
    required double pixelRatio,
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
        ui.Paint()..color = entry.color,
      );
      _drawCenteredText(
        canvas: canvas,
        text: entry.markerText,
        color: Colors.white,
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
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

  static void _drawCenteredText({
    required ui.Canvas canvas,
    required String text,
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    required ui.Rect bounds,
  }) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: 0.0,
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
