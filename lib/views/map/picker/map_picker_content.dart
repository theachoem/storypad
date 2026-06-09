part of 'map_picker_view.dart';

const Color _kDefaultPinColor = Colors.redAccent;

class _MapPickerContent extends StatelessWidget {
  const _MapPickerContent(this.viewModel);

  final MapPickerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final PlaceDbModel? selectedPlace = viewModel.selectedPlace;
    final bool isResolving = viewModel.isResolvingPlace;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        titleSpacing: 0.0,
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop(MapPickerResult.cancel(viewModel.initialSelectedPlace));
          },
        ),

        // Map tiler is affordable but results is not good.
        // Google map is better but very expensive.
        // For now, we have system geocoding, using current location, allow rename place, this cover most use cases already.
        // Let's disable map search for now.
        //
        // title: buildSearchAnchor(context),
        actions: [
          const SizedBox(width: 4.0),
          buildMyLocationButton(context),
          buildMoreOptionsButton(context),
          const SizedBox(width: 4.0),
        ],
      ),
      floatingActionButtonLocation: SpFabLocation.endFloat(context),
      floatingActionButton: FloatingActionButton(
        tooltip: tr("button.done"),
        onPressed: () async {
          if (!viewModel.canConfirm) {
            Navigator.of(context).pop();
            return;
          }

          final MapPickerResult? result = await viewModel.buildConfirmResult();
          if (!context.mounted || result == null) return;
          Navigator.of(context).pop(result);
        },
        child: const Icon(SpIcons.check),
      ),
      bottomNavigationBar: buildSelectedPlaceBar(context, selectedPlace, isResolving),
      body: Stack(
        children: [
          _MapPickerLayer(viewModel: viewModel),
          Align(
            alignment: Alignment.center,
            child: _CenterPinOverlay(isDragging: viewModel.isDragging),
          ),
        ],
      ),
    );
  }

  Widget buildSearchAnchor(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 40.0),
      child: SearchAnchor.bar(
        barElevation: WidgetStateProperty.all(0.0),
        barShape: WidgetStateProperty.all(
          StadiumBorder(side: BorderSide(color: Theme.of(context).dividerColor, width: 1.0)),
        ),
        isFullScreen: true,
        barHintText: tr("button.search"),
        barLeading: const Icon(SpIcons.search),
        suggestionsBuilder: (context, controller) async {
          final String query = controller.text.trim();
          if (query.isEmpty) return const <Widget>[];

          // Lightweight debounce: while the user keeps typing, each keystroke
          // restarts this builder. If the query changed during the delay, bail
          // out and let the newer build do the geocoding so we don't hammer the
          // system geocoder on every character.
          await Future.delayed(const Duration(milliseconds: 400));
          if (controller.text.trim() != query) return const <Widget>[];

          final List<PlaceDbModel> results = await viewModel.searchPlaces(query);

          return results.map((place) {
            return ListTile(
              leading: const Icon(SpIcons.locationPin),
              title: Text(place.address ?? place.displayLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
              ),
              onTap: () {
                controller.closeView(place.address ?? place.displayLabel);
                viewModel.selectSearchedPlace(place);
              },
            );
          }).toList();
        },
      ),
    );
  }

  Widget buildMyLocationButton(BuildContext context) {
    return SpSingleStateWidget.listen(
      initialValue: false,
      builder: (context, loading, notifier) {
        return IconButton(
          tooltip: tr("button.move_to_current_location"),
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
    );
  }

  Widget buildMoreOptionsButton(BuildContext context) {
    return SpPopupMenuButton(
      fromAppBar: true,
      items: (context) => [
        if (viewModel.canRemove)
          SpPopMenuItem(
            leadingIconData: SpIcons.delete,
            title: tr("button.remove_selected_place"),
            titleStyle: TextStyle(color: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(MapPickerResult.remove()),
          ),
        if (viewModel.canReset)
          SpPopMenuItem(
            leadingIconData: SpIcons.refresh,
            title: tr("button.reset"),
            onPressed: viewModel.resetToInitial,
          ),
        SpPopMenuItem(
          leadingIconData: SpIcons.zoomIn,
          title: tr("button.zoom_in"),
          onPressed: () => viewModel.mapController.zoomBy(1.0),
        ),
        SpPopMenuItem(
          leadingIconData: SpIcons.zoomOut,
          title: tr("button.zoom_out"),
          onPressed: () => viewModel.mapController.zoomBy(-1.0),
        ),
        SpPopMenuItem(
          leadingIconData: SpIcons.locationPin,
          title: tr("button.manual_input"),
          onPressed: () async {
            final place = await const MapPickerManualInputRoute().push(context);
            if (!context.mounted || place is! PlaceDbModel) return;
            unawaited(viewModel.selectSearchedPlace(place));
          },
        ),
        SpPopMenuItem(
          leadingIconData: viewModel.mapStyle == SpMapStyle.streets ? SpIcons.satellite : SpIcons.map,
          title: tr("button.switch_map_style"),
          onPressed: () => viewModel.setMapStyle(viewModel.mapStyle == .streets ? .satellite : .streets),
        ),
      ],
      builder: (callback) => IconButton(
        tooltip: tr("button.more_options"),
        icon: const Icon(SpIcons.moreVert),
        onPressed: callback,
      ),
    );
  }

  Widget buildSelectedPlaceBar(BuildContext context, PlaceDbModel? selectedPlace, bool isResolving) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    final String title = selectedPlace == null
        ? tr("page.map.picker.messages.drag_map_to_select_place")
        : isResolving
        ? tr("page.map.picker.messages.resolving_place")
        : selectedPlace.displayLabel;

    final String? subtitle = selectedPlace == null
        ? null
        : isResolving
        ? tr("page.map.picker.messages.please_wait")
        : () {
            final List<String> parts = <String>[
              if (selectedPlace.locality != null && selectedPlace.locality!.trim().isNotEmpty)
                selectedPlace.locality!.trim(),
              if (selectedPlace.country != null && selectedPlace.country!.trim().isNotEmpty)
                selectedPlace.country!.trim(),
            ];
            if (parts.isNotEmpty) return parts.join(', ');
            return '${selectedPlace.latitude.toStringAsFixed(5)}, ${selectedPlace.longitude.toStringAsFixed(5)}';
          }();

    return BottomAppBar(
      padding: EdgeInsets.only(bottom: bottomInset),
      height: 72.0 + bottomInset,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16.0, right: 4.0),
        onTap: selectedPlace == null
            ? null
            : () => viewModel.mapController.animateTo(
                selectedPlace.latitude,
                selectedPlace.longitude,
                zoom: 15.0,
                bearing: 0.0,
              ),
        leading: isResolving
            ? const SizedBox.square(
                dimension: 18.0,
                child: CircularProgressIndicator.adaptive(),
              )
            : Icon(SpIcons.locationPin, color: colorScheme.primary),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle == null ? null : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          tooltip: tr("button.edit"),
          style: IconButton.styleFrom(shape: const CircleBorder(), backgroundColor: Colors.transparent),
          icon: const Icon(SpIcons.edit),
          onPressed: selectedPlace == null
              ? null
              : () async {
                  final label = await EditPlaceRoute(place: selectedPlace).push(viewModel.viewContext);
                  if (!context.mounted || label == null || label is! String) return;

                  viewModel.updateSelectedPlaceDetails(
                    placeName: label,
                    locality: selectedPlace.locality,
                    country: selectedPlace.country,
                    address: selectedPlace.address,
                  );
                },
        ),
      ),
    );
  }
}

// --- Center pin tunables ---
const double _kPinSize = 48.0;
const double _kPinLiftHeight = 20.0;
const double _kShadowRestDiameter = 6.0;
const double _kShadowLiftDiameter = 20.0;
// ---

class _CenterPinOverlay extends StatefulWidget {
  const _CenterPinOverlay({required this.isDragging});

  final bool isDragging;

  @override
  State<_CenterPinOverlay> createState() => _CenterPinOverlayState();
}

class _CenterPinOverlayState extends State<_CenterPinOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.elasticOut,
    );
  }

  @override
  void didUpdateWidget(_CenterPinOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDragging != oldWidget.isDragging) {
      if (widget.isDragging) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -24.0),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final double t = _animation.value;
          final double shadowDiameter = _kShadowRestDiameter + (_kShadowLiftDiameter - _kShadowRestDiameter) * t;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: Offset(0, -_kPinLiftHeight * t),
                child: const Icon(SpIcons.locationPin, size: _kPinSize, color: _kDefaultPinColor),
              ),
              Container(
                width: shadowDiameter,
                height: shadowDiameter,
                decoration: BoxDecoration(
                  color: _kDefaultPinColor.withValues(alpha: 0.8 * (1 - t)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _kDefaultPinColor.withValues(alpha: 0.8 * t),
                    width: 1.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapPickerLayer extends StatelessWidget {
  const _MapPickerLayer({required this.viewModel});

  final MapPickerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (!viewModel.isCameraResolved) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    switch (viewModel.mapRenderer) {
      case SpMapRenderer.googleMap:
        return SpGoogleMap<PlaceDbModel>(
          mapController: viewModel.mapController,
          initialCamera: viewModel.initialSpMapCamera,
          mapStyle: viewModel.mapStyle,
          markers: const [],
          showCurrentLocation: viewModel.showCurrentLocation,
          onCameraMoveStarted: viewModel.onCameraMoveStarted,
          onCameraIdle: viewModel.onCameraIdle,
          onViewportChanged: viewModel.onCameraViewportChanged,
        );
      case SpMapRenderer.flutterMap:
        return SpFlutterMap<PlaceDbModel>(
          mapController: viewModel.mapController,
          initialCamera: viewModel.initialSpMapCamera,
          mapStyle: viewModel.mapStyle,
          markers: const [],
          showCurrentLocation: viewModel.showCurrentLocation,
          onCameraMoveStarted: viewModel.onCameraMoveStarted,
          onCameraIdle: viewModel.onCameraIdle,
          onViewportChanged: viewModel.onCameraViewportChanged,
        );
    }
  }
}
