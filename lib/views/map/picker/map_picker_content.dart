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
              tooltip: 'Remove selected place',
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
            label: const Text('Confirm'),
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
            tooltip: 'Map style',
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
          IconButton(
            tooltip: 'Current location',
            icon: const Icon(SpIcons.myLocation),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: () => viewModel.goToCurrentLocation(context),
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
    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + kToolbarHeight,
        left: MediaQuery.of(context).padding.left + 16.0,
        right: MediaQuery.of(context).padding.right + 16.0,
      ),
      child: Builder(
        builder: (context) {
          final ColorScheme colorScheme = Theme.of(context).colorScheme;
          final String title = selectedPlace == null
              ? 'Tap map to select a place'
              : isResolving
              ? 'Resolving place...'
              : selectedPlace.displayLabel;

          final String subtitle = selectedPlace == null
              ? 'or use current location'
              : isResolving
              ? 'Please wait'
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
              subtitle: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                style: IconButton.styleFrom(shape: const CircleBorder()),
                icon: const Icon(SpIcons.edit),
                onPressed: selectedPlace == null
                    ? null
                    : () async {
                        final List<String>? values = await Navigator.of(context).push<List<String>>(
                          MaterialPageRoute(
                            builder: (context) => SpTextInputsPage(
                              appBar: AppBar(
                                title: const Text('Edit place'),
                              ),
                              saveButtonLabel: 'Apply',
                              fields: <SpTextInputField>[
                                SpTextInputField(
                                  labelText: 'Place name',
                                  hintText: 'Coffee shop, park, museum...',
                                  initialText: selectedPlace.placeName,
                                ),
                              ],
                            ),
                          ),
                        );

                        if (!context.mounted || values == null || values.length != 1) return;
                        viewModel.updateSelectedPlaceDetails(
                          placeName: values[0],
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
      case SpMapRenderer.googleMaps:
        return SpGoogleMap<PlaceDbModel>(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 8.0, bottom: 112.0),
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
