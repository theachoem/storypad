part of 'map_picker_view.dart';

class _MapPickerContent extends StatelessWidget {
  const _MapPickerContent(this.viewModel);

  final MapPickerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final PlaceDbModel? selectedPlace = viewModel.selectedPlace;
    final bool isResolving = viewModel.isResolvingPlace;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop(MapPickerResult.cancel(viewModel.initialSelectedPlace));
          },
        ),
        actions: [
          if (viewModel.canRemove)
            IconButton.filledTonal(
              style: IconButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              tooltip: tr("button.remove_selected_place"),
              icon: const Icon(SpIcons.delete),
              onPressed: () => Navigator.of(context).pop(MapPickerResult.remove()),
            ),
          FilledButton.icon(
            onPressed: viewModel.canConfirm
                ? () async {
                    final MapPickerResult? result = await viewModel.buildConfirmResult();
                    if (!context.mounted || result == null) return;
                    Navigator.of(context).pop(result);
                  }
                : null,
            icon: const Icon(SpIcons.check),
            label: Text(tr("button.confirm")),
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      floatingActionButtonLocation: SpFabLocation.endFloat(context),
      floatingActionButton: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .end,
        children: [
          IconButton(
            tooltip: tr("button.switch_map_style"),
            icon: SpAnimatedIcons.fadeScale(
              duration: Durations.long1,
              firstChild: const Icon(SpIcons.map),
              secondChild: const Icon(SpIcons.satellite),
              showFirst: viewModel.mapStyle == SpMapStyle.streets,
            ),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8.0),
              ),
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
        ],
      ),
      body: Stack(
        children: [
          _MapPickerLayer(viewModel: viewModel),
          buildSelectedPlaceCard(context, selectedPlace, isResolving),
        ],
      ),
    );
  }

  Widget buildSelectedPlaceCard(BuildContext context, PlaceDbModel? selectedPlace, bool isResolving) {
    return MediaQuery.removePadding(
      removeLeft: true,
      removeRight: true,
      context: context,
      child: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight,
          left: MediaQuery.of(context).padding.left + 16.0,
          right: MediaQuery.of(context).padding.right + 16.0,
        ),
        child: Builder(
          builder: (context) {
            final ColorScheme colorScheme = Theme.of(context).colorScheme;
            final String title = selectedPlace == null
                ? tr("page.map.picker.messages.tap_map_to_select_place")
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

            return Material(
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.only(left: 16.0, right: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                enabled: true,
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
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: subtitle == null ? null : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  style: IconButton.styleFrom(shape: const CircleBorder()),
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
          },
        ),
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
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 16.0,
            bottom: 112.0,
            left: MediaQuery.paddingOf(context).left,
            right: MediaQuery.paddingOf(context).right,
          ),
          mapController: viewModel.mapController,
          initialCamera: viewModel.initialSpMapCamera,
          mapStyle: viewModel.mapStyle,
          markers: viewModel.selectedMarkers,
          showCurrentLocation: viewModel.showCurrentLocation,
          onMapTap: (point) => viewModel.setSelectedLocation(point.latitude, point.longitude),
        );
      case SpMapRenderer.flutterMap:
        return SpFlutterMap<PlaceDbModel>(
          mapController: viewModel.mapController,
          initialCamera: viewModel.initialSpMapCamera,
          mapStyle: viewModel.mapStyle,
          markers: viewModel.selectedMarkers,
          showCurrentLocation: viewModel.showCurrentLocation,
          onMapTap: (point) => viewModel.setSelectedLocation(point.latitude, point.longitude),
        );
    }
  }
}
