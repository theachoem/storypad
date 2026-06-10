part of 'map_picker_manual_input_view.dart';

class _MapPickerManualInputContent extends StatelessWidget {
  const _MapPickerManualInputContent(this.viewModel);

  final MapPickerManualInputViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr("button.manual_input")),
        actions: [
          FilledButton(
            onPressed: viewModel.canConfirm ? () => viewModel.apply(context) : null,
            child: Text(tr("button.save")),
          ),
          const SizedBox(width: 12.0),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: 16.0,
          left: MediaQuery.paddingOf(context).left + 16.0,
          right: MediaQuery.paddingOf(context).right + 16.0,
          bottom: MediaQuery.paddingOf(context).bottom + 16.0,
        ),
        children: [
          TextField(
            controller: viewModel.coordinateController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (viewModel.canConfirm) viewModel.apply(context);
            },
            decoration: InputDecoration(
              labelText: tr("input.coordinates.label"),
              errorText: viewModel.errorText,
            ),
          ),
          const SizedBox(height: 12.0),
          _buildFormatHints(context),
          const SizedBox(height: 16.0),
          const Divider(height: 1.0),
          _buildStatus(context, colorScheme),
        ],
      ),
    );
  }

  static const List<(String, String)> _formatExamples = [
    ('Latitude/Longitude', '13.41259, 103.86697'),
    ('Apple Maps', '29.97937° N, 31.13419° E'),
    ('Google Maps / Plus Code', 'MXQ4+M5 New York, USA'),
  ];

  Widget _buildFormatHints(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextStyle? labelStyle = textTheme.bodySmall;
    final TextStyle valueStyle = (textTheme.bodySmall ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.bold,
      color: colorScheme.primary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Can't find your location? Enter its coordinates above. Supported formats below, tap an example to try it.",
          style: labelStyle,
        ),
        const SizedBox(height: 8.0),
        ..._formatExamples.map((entry) {
          return GestureDetector(
            onTap: () {
              viewModel.coordinateController
                ..text = entry.$2
                ..selection = TextSelection.collapsed(offset: entry.$2.length);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '• ${entry.$1}: ', style: labelStyle),
                    TextSpan(text: entry.$2, style: valueStyle),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatus(BuildContext context, ColorScheme colorScheme) {
    if (viewModel.isResolving) {
      return const Column(
        children: [
          SizedBox(height: 16.0),
          Row(
            children: [
              SizedBox.square(dimension: 18.0, child: CircularProgressIndicator.adaptive()),
              SizedBox(width: 12.0),
              Expanded(child: Text('Resolving location…')),
            ],
          ),
        ],
      );
    }

    final PlaceDbModel? place = viewModel.resolvedPlace;
    if (place == null) return const SizedBox.shrink();

    final String title = place.displayLabel;
    final List<String> subtitleParts = [
      if (place.locality != null && place.locality!.isNotEmpty) place.locality!,
      if (place.country != null && place.country!.isNotEmpty) place.country!,
    ];
    final String subtitle = subtitleParts.isNotEmpty
        ? subtitleParts.join(', ')
        : '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(SpIcons.locationPin, color: colorScheme.primary),
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(height: 8.0),
        _MapPreview(place: place),
      ],
    );
  }
}

class _MapPreview extends StatefulWidget {
  const _MapPreview({required this.place});

  final PlaceDbModel place;

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  final SpMapController _mapController = SpMapController();

  SpMapCamera get _camera => SpMapCamera(
    target: SpLatLng(widget.place.latitude, widget.place.longitude),
    zoom: 15.0,
  );

  @override
  void didUpdateWidget(_MapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.place.latitude != oldWidget.place.latitude || widget.place.longitude != oldWidget.place.longitude) {
      _mapController.animateTo(widget.place.latitude, widget.place.longitude, zoom: 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<SpMapMarker<PlaceDbModel>> markers = [
      SpMapMarker<PlaceDbModel>(
        id: 'selected-place',
        point: SpLatLng(widget.place.latitude, widget.place.longitude),
        data: widget.place,
        title: widget.place.displayLabel,
      ),
    ];

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: switch (SpMapRenderer.defaultRenderer) {
            SpMapRenderer.googleMap => SpGoogleMap<PlaceDbModel>(
              mapController: _mapController,
              initialCamera: _camera,
              mapStyle: SpMapStyle.streets,
              markers: markers,
            ),
            SpMapRenderer.flutterMap => SpFlutterMap<PlaceDbModel>(
              mapController: _mapController,
              initialCamera: _camera,
              mapStyle: SpMapStyle.streets,
              markers: markers,
            ),
          },
        ),
      ),
    );
  }
}
