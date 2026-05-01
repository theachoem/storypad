part of 'map_picker_view.dart';

class _MapPickerContent extends StatelessWidget {
  const _MapPickerContent(this.viewModel);

  final MapPickerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final PlaceObject? selectedPlace = viewModel.selectedPlace;
    final bool isResolving = viewModel.isResolvingPlace;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          _MapPickerLayer(viewModel: viewModel),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SpMapSideButton(
                        icon: SpIcons.keyboardLeft,
                        tooltip: 'Back',
                        onPressed: () {
                          Navigator.of(context).pop(MapPickerResult.cancel(viewModel.initialSelectedPlace));
                        },
                      ),
                      const Spacer(),
                      if (viewModel.canRemove)
                        SpMapSideButton(
                          icon: SpIcons.delete,
                          tooltip: 'Remove selected place',
                          isDanger: true,
                          onPressed: () => Navigator.of(context).pop(MapPickerResult.remove()),
                        ),
                      const SizedBox(width: 8.0),
                      _MapPickerActionButton(
                        icon: SpIcons.check,
                        label: 'Confirm',
                        tooltip: 'Confirm location',
                        enabled:
                            selectedPlace != null &&
                            !isResolving &&
                            selectedPlace.compareTo(viewModel.initialSelectedPlace) != 0,
                        isPrimary: true,
                        onPressed: () async {
                          final MapPickerResult? result = await viewModel.buildConfirmResult();
                          if (!context.mounted || result == null) return;
                          Navigator.of(context).pop(result);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  GestureDetector(
                    onTap: selectedPlace == null
                        ? null
                        : () => viewModel.mapController.animateTo(
                            selectedPlace.latitude,
                            selectedPlace.longitude,
                            zoom: 15.0,
                            bearing: 0.0,
                          ),
                    child: _SelectedPlaceCard(
                      place: selectedPlace,
                      isResolving: isResolving,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: .end,
                      mainAxisAlignment: .end,
                      spacing: 8.0,
                      children: [
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPickerLayer extends StatelessWidget {
  const _MapPickerLayer({required this.viewModel});

  final MapPickerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    switch (viewModel.mapRenderer) {
      case SpMapRenderer.googleMaps:
        return SpGoogleMap<PlaceObject>(
          mapController: viewModel.mapController,
          initialCamera: viewModel.initialSpMapCamera,
          mapStyle: viewModel.mapStyle,
          markers: viewModel.selectedMarkers,
          onMapTap: (point) => viewModel.setSelectedLocation(point.latitude, point.longitude),
        );
      case SpMapRenderer.flutterMap:
        return SpFlutterMap<PlaceObject>(
          mapController: viewModel.mapController,
          initialCamera: viewModel.initialSpMapCamera,
          mapStyle: viewModel.mapStyle,
          markers: viewModel.selectedMarkers,
          onMapTap: (point) => viewModel.setSelectedLocation(point.latitude, point.longitude),
        );
    }
  }
}

class _MapPickerActionButton extends StatelessWidget {
  static const double _minHeight = 44.0;

  const _MapPickerActionButton({
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.enabled = true,
    this.isPrimary = false,

    // ignore: unused_element_parameter
    this.isDanger = false,
  });

  final String label;
  final String tooltip;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool enabled;
  final bool isPrimary;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final Color backgroundColor;
    final Color foregroundColor;
    if (!enabled) {
      backgroundColor = colorScheme.surface.withValues(alpha: 0.72);
      foregroundColor = colorScheme.onSurface.withValues(alpha: 0.44);
    } else if (isDanger) {
      backgroundColor = colorScheme.errorContainer.withValues(alpha: 0.96);
      foregroundColor = colorScheme.onErrorContainer;
    } else if (isPrimary) {
      backgroundColor = colorScheme.primary;
      foregroundColor = colorScheme.onPrimary;
    } else {
      backgroundColor = colorScheme.surface.withValues(alpha: 0.94);
      foregroundColor = colorScheme.onSurface;
    }

    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18.0,
              offset: const Offset(0.0, 8.0),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            onTap: enabled ? onPressed : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, size: 18.0, color: foregroundColor),
                      const SizedBox(width: 6.0),
                    ],
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedPlaceCard extends StatelessWidget {
  const _SelectedPlaceCard({
    required this.place,
    required this.isResolving,
  });

  final PlaceObject? place;
  final bool isResolving;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String title = _resolveTitle();
    final String subtitle = _resolveSubtitle();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18.0,
            offset: const Offset(0.0, 8.0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Row(
          children: <Widget>[
            if (isResolving)
              SizedBox.square(
                dimension: 18.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: colorScheme.primary,
                ),
              )
            else
              Icon(SpIcons.myLocation, size: 18.0, color: colorScheme.primary),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveTitle() {
    if (place == null) return 'Tap map to select a place';
    if (isResolving) return 'Resolving place...';
    return place!.displayLabel;
  }

  String _resolveSubtitle() {
    if (place == null) return 'or use current location';
    if (isResolving) return 'Please wait';

    final List<String> parts = <String>[
      if (place!.locality != null && place!.locality!.trim().isNotEmpty) place!.locality!.trim(),
      if (place!.country != null && place!.country!.trim().isNotEmpty) place!.country!.trim(),
    ];
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return '${place!.latitude.toStringAsFixed(5)}, ${place!.longitude.toStringAsFixed(5)}';
  }
}
