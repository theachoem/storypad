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
            child: Text(tr("button.done")),
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
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            onSubmitted: (_) {
              if (viewModel.canConfirm) viewModel.apply(context);
            },
            decoration: InputDecoration(
              labelText: tr("input.coordinates.label"),
              hintText: tr("input.coordinates.hint"),
              errorText: viewModel.errorText,
            ),
          ),
          const SizedBox(height: 20.0),
          _buildStatus(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatus(BuildContext context, ColorScheme colorScheme) {
    if (viewModel.isResolving) {
      return const Row(
        children: [
          SizedBox.square(dimension: 18.0, child: CircularProgressIndicator.adaptive()),
          SizedBox(width: 12.0),
          Expanded(child: Text('Resolving location…')),
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

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(SpIcons.locationPin, color: colorScheme.primary),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
