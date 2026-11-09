part of '../sp_story_labels_sheet.dart';

/// The story's place: drag the map under the center pin, zoom, jump to the current
/// location, remove/reset, type coordinates, switch map style, rename, then Save.
/// Naming, and finding a place by name or coordinates, open as a sheet on top ([SpPlaceNameSheet]).
/// Lookups live in [_PlaceLookup], so this state keeps only what's on screen.
class _PlaceTab extends StatefulWidget {
  const _PlaceTab({
    required this.savedPlace,
    required this.onSetPlace,
  });

  /// The story's place when the tab opened.
  final PlaceDbModel? savedPlace;
  final Future<void> Function(PlaceDbModel? place) onSetPlace;

  @override
  State<_PlaceTab> createState() => _PlaceTabState();
}

class _PlaceTabState extends State<_PlaceTab> with DebounchedCallback {
  static const double _buttonSize = 40.0;
  static const double _buttonGap = 8.0;

  final SpMapController mapController = SpMapController();

  late final DevicePreferencesProvider _preferences = context.read<DevicePreferencesProvider>();
  late SpMapStyle _mapStyle = _preferences.preferences.mapStyle;

  // Null until known: the map shows once it has a starting camera.
  SpMapCamera? _initialCamera;
  bool _showCurrentLocation = false;

  PlaceDbModel? _selected;
  bool _resolving = false;

  // The saved place with the details looked up for it (it was saved without them). Those details
  // aren't the user's edit, so they don't enable Save on their own.
  PlaceDbModel? _savedWithDetails;

  // Bumped by every selection, so a slower lookup for an older one is dropped.
  int _selectedVersion = 0;

  // The user moved the map or picked a spot: from then on, nothing moves it for them.
  bool _userPicked = false;
  bool _dragging = false;
  bool _closing = false;

  List<SpMapMarker<PlaceDbModel>> _dots = const [];
  int _dotsVersion = 0;

  bool get _canReset {
    final saved = widget.savedPlace;
    final selected = _selected;
    return saved != null && selected != null && !PlaceSelectionService.isSameSpot(selected.latLng, saved.latLng);
  }

  bool get _canSave =>
      _selected != null &&
      !_resolving &&
      PlaceSelectionService.hasChanges(_selected!, widget.savedPlace, savedWithDetails: _savedWithDetails);

  @override
  void initState() {
    super.initState();
    _loadInitialCamera();

    // A saved place is selected (and its details filled in if it was saved without); with none,
    // start at the current location when access is already granted (never asks).
    if (widget.savedPlace case final saved?) {
      _select(saved);
    } else {
      _goToCurrentLocationIfAllowed();
    }
  }

  @override
  void dispose() {
    cancelTimer('drag');
    cancelTimer('dots');
    super.dispose();
  }

  Future<void> _loadInitialCamera() async {
    final (:camera, :fromDevice) = await _PlaceLookup.initialCamera(widget.savedPlace);
    // Already started at a place picked meanwhile (see [_moveTo]).
    if (!mounted || _initialCamera != null) return;

    setState(() {
      _initialCamera = camera;
      if (fromDevice) _showCurrentLocation = true;
    });
  }

  // Every selection goes through here: it cancels an older selection's pending lookup.
  void _select(PlaceDbModel place) {
    setState(() {
      _selectedVersion += 1;
      _selected = place;
      _resolving = PlaceSelectionService.needsDetails(place);
    });
    if (_resolving) _resolveDetails(_selectedVersion);
  }

  Future<void> _resolveDetails(int version) async {
    final details = await _PlaceLookup.details(_selected!);
    if (!mounted || version != _selectedVersion) return;

    setState(() {
      if (details != null) {
        // Looked up for the saved place itself (on open, or after Reset): the new baseline for Save.
        if (!PlaceSelectionService.hasChanges(_selected!, widget.savedPlace)) _savedWithDetails = details;
        _selected = details;
      }
      _resolving = false;
    });
    if (details != null) HapticFeedback.selectionClick();
  }

  // Moves the map to [place] and selects it: a dot, a place picked by name or coordinates,
  // or the current location.
  Future<void> _moveTo(PlaceDbModel place, {bool currentLocation = false}) async {
    _userPicked = true;
    final mapShown = _initialCamera != null;

    setState(() {
      if (currentLocation) _showCurrentLocation = true;
      // The map isn't shown until it has a starting camera: start it at the place instead.
      _initialCamera ??= SpMapCamera(target: place.latLng, zoom: 15.0);
    });
    _select(place);

    if (mapShown) await mapController.animateTo(place.latitude, place.longitude, zoom: 15.0, bearing: 0.0);
  }

  Future<void> _goToCurrentLocation() async {
    final place = await SpAppLocationService.fetchCurrentPlaceWithRecovery(context);
    if (mounted && place != null) await _moveTo(place, currentLocation: true);
  }

  Future<void> _goToCurrentLocationIfAllowed() async {
    final place = await _PlaceLookup.currentPlaceIfAllowed();
    if (mounted && place != null && !_userPicked) await _moveTo(place, currentLocation: true);
  }

  // Back to the story's saved place, keeping the zoom.
  Future<void> _reset() async {
    final saved = widget.savedPlace;
    if (saved == null) return;

    _userPicked = true;
    _select(saved);
    await mapController.animateTo(saved.latitude, saved.longitude);
  }

  void _setMapStyle(SpMapStyle mapStyle) {
    setState(() {
      _mapStyle = mapStyle;
      // Each style has its own dot color (see SpMapDotMarker.colorFor).
      _dots = [for (final dot in _dots) _PlaceLookup.dot(dot.point, mapStyle)];
    });
    _preferences.updateMapStyle(mapStyle);
  }

  void _onCameraMoveStarted() {
    _userPicked = true;
    if (_dragging) return;

    HapticFeedback.selectionClick();
    setState(() => _dragging = true);
  }

  void _onCameraIdle(SpLatLng center) {
    cancelTimer('drag');
    setState(() => _dragging = false);
    _selectSpot(center);
  }

  void _onViewportChanged(SpMapViewport viewport) {
    debouncedCallback(() => _loadDots(viewport.bounds), duration: const Duration(milliseconds: 400), key: 'dots');

    // While dragging, follow the pin before the map stops.
    if (_dragging) {
      debouncedCallback(
        () {
          if (mounted && _dragging) _selectSpot(viewport.center);
        },
        duration: const Duration(milliseconds: 300),
        key: 'drag',
      );
    }
  }

  void _selectSpot(SpLatLng center) {
    final current = _selected;
    if (current != null && PlaceSelectionService.isSameSpot(center, current.latLng)) return;
    _select(PlaceDbModel(latitude: center.latitude, longitude: center.longitude));
  }

  Future<void> _loadDots(SpLatLngBounds bounds) async {
    final version = ++_dotsVersion;
    final spots = await _PlaceLookup.savedPlaceSpots(bounds);
    // Drawn for the style at hand (it may have changed while loading).
    if (mounted && version == _dotsVersion) {
      setState(() => _dots = [for (final spot in spots) _PlaceLookup.dot(spot, _mapStyle)]);
    }
  }

  // Once only: a double tap on Save/Remove would save twice and pop the page under the sheet.
  Future<void> _setPlaceAndClose(PlaceDbModel? place) async {
    if (_closing) return;
    _closing = true;

    try {
      await widget.onSetPlace(place);
    } catch (_) {
      _closing = false;
      rethrow;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    var place = _selected;
    if (place == null) return;

    // No details yet (the lookup failed or found none): one last, bounded try —
    // on timeout we just save the coordinates.
    if (PlaceSelectionService.needsDetails(place)) {
      place =
          await _PlaceLookup.details(place).timeout(SpLocationService.geocodeTimeout, onTimeout: () => null) ?? place;
    }

    await _setPlaceAndClose(place);
  }

  // Names the spot, or moves the pin to a place picked by name or coordinates.
  Future<void> _editPlaceName(PlaceDbModel place) async {
    // Nothing moves the map for the user while they're naming it.
    _userPicked = true;
    final result = await SpPlaceNameSheet(place: place).show<SpPlaceNameResult>(context: context);
    if (!mounted || result == null) return;

    switch (result) {
      case SpPlaceNameRenamed(:final name):
        // The latest selection (details may have arrived while the sheet was open).
        _select((_selected ?? place).copyWith(placeName: name));
      case SpPlaceNamePicked(place: final picked):
        await _moveTo(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The sheet's insets (see SpStoryLabelsSheet): the map runs edge to edge, its buttons and the
    // place bar keep clear of the sides. (Not passed to the map's own padding: that would move the
    // camera's center off the pin.)
    final padding = MediaQuery.paddingOf(context);

    return Column(
      children: [
        // Edges the map at both ends, like the place bar's below.
        const Divider(height: 1),
        Expanded(
          child: Stack(
            children: [
              _buildMap(),
              Center(child: SpMapCenterPin(isDragging: _dragging)),
              // Top row: reset, zoom, more (remove, map style, open in a maps app).
              // Zoom has buttons, not only pinch: a pinch zooms around the fingers and so moves the
              // picked spot; the buttons zoom around the center pin.
              Positioned(
                top: 8.0,
                right: max(8.0, padding.right),
                child: Row(
                  spacing: _buttonGap,
                  children: [
                    // Back to the story's saved place, e.g. after an accidental drag. At the row's
                    // start, so it never shifts the others; mounted only while needed, so it fades in.
                    if (_canReset)
                      SpFadeIn.fromRight(
                        child: SpMapSideButton(
                          size: _buttonSize,
                          tooltip: tr("button.reset"),
                          icon: const Icon(SpIcons.refresh),
                          onPressed: _reset,
                        ),
                      ),
                    SpMapSideButton(
                      size: _buttonSize,
                      tooltip: tr("button.zoom_out"),
                      icon: const Icon(SpIcons.zoomOut),
                      onPressed: () => mapController.zoomBy(-1.0),
                    ),
                    SpMapSideButton(
                      size: _buttonSize,
                      tooltip: tr("button.zoom_in"),
                      icon: const Icon(SpIcons.zoomIn),
                      onPressed: () => mapController.zoomBy(1.0),
                    ),
                    _buildMoreOptionsButton(),
                  ],
                ),
              ),
              // Bottom right, in thumb reach (Google Maps draws its logo bottom left).
              Positioned(
                bottom: 8.0,
                right: max(8.0, padding.right),
                child: _buildMyLocationButton(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        _buildPlaceBar(),
        // Above the sheet's safe area (see SpStoryLabelsSheet).
        SizedBox(height: padding.bottom),
      ],
    );
  }

  Widget _buildMap() {
    final initialCamera = _initialCamera;
    if (initialCamera == null) return const Center(child: CircularProgressIndicator.adaptive());

    return switch (_preferences.mapRenderer) {
      .googleMap => SpGoogleMap<PlaceDbModel>(
        mapController: mapController,
        initialCamera: initialCamera,
        mapStyle: _mapStyle,
        markers: _dots,
        markerIconBuilder: (context, marker, pixelRatio) => SpMapDotMarker.googleIcon(_mapStyle, pixelRatio),
        onMarkerTap: (marker) => _moveTo(marker.data),
        showCurrentLocation: _showCurrentLocation,
        eagerGestures: true,
        onCameraMoveStarted: _onCameraMoveStarted,
        onCameraIdle: _onCameraIdle,
        onViewportChanged: _onViewportChanged,
      ),
      .flutterMap => SpFlutterMap<PlaceDbModel>(
        mapController: mapController,
        initialCamera: initialCamera,
        mapStyle: _mapStyle,
        markers: _dots,
        markerBuilder: (context, marker) => SpMapDotMarker(mapStyle: _mapStyle),
        onMarkerTap: (marker) => _moveTo(marker.data),
        showCurrentLocation: _showCurrentLocation,
        onCameraMoveStarted: _onCameraMoveStarted,
        onCameraIdle: _onCameraIdle,
        onViewportChanged: _onViewportChanged,
      ),
    };
  }

  Widget _buildMyLocationButton() {
    return SpSingleStateWidget.listen(
      initialValue: false,
      builder: (context, loading, notifier) {
        return SpMapSideButton(
          size: _buttonSize,
          tooltip: tr("button.move_to_current_location"),
          icon: loading
              ? const SizedBox.square(dimension: 20.0, child: CircularProgressIndicator.adaptive())
              : const Icon(SpIcons.myLocation),
          onPressed: () async {
            if (loading) return;
            notifier.value = true;
            await _goToCurrentLocation();
            notifier.value = false;
          },
        );
      },
    );
  }

  Widget _buildMoreOptionsButton() {
    return SpPopupMenuButton(
      items: (context) => [
        if (widget.savedPlace != null)
          SpPopMenuItem(
            leadingIconData: SpIcons.delete,
            title: tr("button.remove_selected_place"),
            titleStyle: TextStyle(color: ColorScheme.of(context).error),
            onPressed: () => _setPlaceAndClose(null),
          ),
        SpPopMenuItem(
          leadingIconData: SpIcons.mapLayers,
          title: tr("button.switch_map_style"),
          onPressed: () => _setMapStyle(_mapStyle == .streets ? .satellite : .streets),
        ),
        // The tab's context, not the menu's: the menu is gone by the time the maps app chooser shows.
        if (_selected case final place?)
          SpPopMenuItem(
            leadingIconData: SpIcons.openInNew,
            title: tr("button.open_in_args", namedArgs: {"OPENEE_NAME": tr("page.map.title")}),
            onPressed: () => MapAppOpenerService.open(this.context, place.latLng),
          ),
      ],
      builder: (callback) => SpMapSideButton(
        size: _buttonSize,
        tooltip: tr("button.more_options"),
        icon: const Icon(SpIcons.moreVert),
        onPressed: callback,
      ),
    );
  }

  // The place — what it is: rename, save.
  Widget _buildPlaceBar() {
    final place = _selected;

    final String title = place == null
        ? tr("page.map.place.messages.drag_map_to_select_place")
        : _resolving
        ? tr("page.map.place.messages.resolving_place")
        : place.displayLabel;

    final String? subtitle = place == null
        ? null
        : _resolving
        ? tr("general.messages.please_wait")
        : place.areaOrCoordinatesLabel;

    return ListTile(
      // A ListTile keeps clear of the side insets itself.
      contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
      // The whole bar opens the place name sheet (name the spot, or find a place).
      onTap: place == null ? null : () => _editPlaceName(place),
      leading: _resolving
          ? const SizedBox.square(dimension: 20.0, child: CircularProgressIndicator.adaptive())
          : Icon(SpIcons.locationPin, color: ColorScheme.of(context).primary),
      title: Text(title, maxLines: 1, overflow: .ellipsis),
      subtitle: subtitle == null ? null : Text(subtitle, maxLines: 1, overflow: .ellipsis),
      trailing: Row(
        mainAxisSize: .min,
        children: [
          Icon(SpIcons.edit, color: place == null ? Theme.of(context).disabledColor : null),
          const SizedBox(width: 16.0),
          SpFilledButton(
            onPressed: _canSave ? _save : null,
            child: Text(tr("button.save")),
          ),
        ],
      ),
    );
  }
}
