part of 'location_picker_view.dart';

class _LocationPickerContent extends StatelessWidget {
  const _LocationPickerContent(this.viewModel);

  final LocationPickerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: _buildTitle(context),
        leading: BackButton(
          style: _appBarButtonStyle(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Use current location',
            style: _appBarButtonStyle(context),
            onPressed: viewModel.isFetchingLocation ? null : viewModel.fetchCurrentLocation,
            icon: viewModel.isFetchingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(SpIcons.myLocation),
          ),
          IconButton(
            tooltip: viewModel.tileStyle.toggled.label,
            style: _appBarButtonStyle(context),
            icon: Icon(
              viewModel.tileStyle == SpMapTileStyle.streets ? SpIcons.satellite : SpIcons.map,
            ),
            onPressed: viewModel.toggleTileStyle,
          ),
          if (viewModel.params.onDelete != null)
            IconButton(
              tooltip: 'Remove location',
              style: _appBarButtonStyle(context),
              icon: const Icon(SpIcons.delete),
              onPressed: () => viewModel.deleteLocation(context),
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButtonLocation: SpFabLocation.endFloat(context),
      floatingActionButton: _buildFabs(context),
      body: viewModel.mapAdapter.buildMap(
        context: context,
        tileStyle: viewModel.tileStyle,
        controller: viewModel.mapController,
        onTap: viewModel.onMapTap,
        markers: viewModel.selectedLatLng != null ? [SpPinMapMarker(position: viewModel.selectedLatLng!)] : [],
        initialPosition: viewModel.initialLatLng,
        initialZoom: kLocationZoom,
      ),
    );
  }

  ButtonStyle _appBarButtonStyle(BuildContext context) {
    return IconButton.styleFrom(
      side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
      backgroundColor: ColorScheme.of(context).surface.withValues(alpha: 0.5),
      foregroundColor: ColorScheme.of(context).onSurface,
    );
  }

  Widget? _buildFabs(BuildContext context) {
    if (viewModel.selectedLatLng == null) return null;
    return FloatingActionButton.extended(
      heroTag: 'location_confirm',
      shape: const StadiumBorder(),
      icon: viewModel.isGeocoding
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(SpIcons.check),
      label: const Text('Confirm'),
      onPressed: viewModel.isGeocoding ? null : () => viewModel.confirm(context),
    );
  }

  Widget _buildTitle(BuildContext context) {
    if (viewModel.selectedLatLng == null) {
      return const Text('Pick a location');
    }

    if (viewModel.isGeocoding || viewModel.isFetchingLocation) {
      return const Text('Finding place…');
    }

    final label = viewModel.result?.displayLabel;
    return Text(
      label ?? 'Unknown place',
      overflow: TextOverflow.ellipsis,
    );
  }
}
