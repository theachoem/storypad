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
          style: IconButton.styleFrom(
            side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
            backgroundColor: ColorScheme.of(context).surface.withValues(alpha: 0.5),
            foregroundColor: ColorScheme.of(context).onSurface,
          ),
        ),
      ),
      floatingActionButtonLocation: SpFabLocation.endFloat(context),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: viewModel.tileStyle.toggled.label,
        onPressed: viewModel.toggleTileStyle,
        child: Icon(viewModel.tileStyle == SpMapTileStyle.streets ? SpIcons.satellite : SpIcons.map),
      ),
      body: viewModel.mapAdapter.buildMap(
        context: context,
        tileStyle: viewModel.tileStyle,
        controller: viewModel.mapController,
        markers: [
          const SpPinMapMarker(
            position: SpLatLng(37.7749, -122.4194),
          ),
        ],
      ),
    );
  }
}
