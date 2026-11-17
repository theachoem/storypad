import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/geocoding/sp_coordinate_parser_service.dart';
import 'package:storypad/core/services/geocoding/sp_geocoding_service.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_filled_button.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_section_title.dart';

/// What [SpPlaceNameSheet] pops.
sealed class SpPlaceNameResult {
  const SpPlaceNameResult();
}

/// Keep the spot, give it this name.
class SpPlaceNameRenamed extends SpPlaceNameResult {
  const SpPlaceNameRenamed(this.name);
  final String name;
}

/// Go to one of the user's places: its exact spot, name and details.
class SpPlaceNamePicked extends SpPlaceNameResult {
  const SpPlaceNamePicked(this.place);
  final PlaceDbModel place;
}

/// Names the picked spot, or finds a place by its name or its coordinates.
///
/// The two do different things, so they look different: a row of "Places" moves the pin there —
/// the user's named places from their stories (local only, no paid geocoding API; nearest first
/// with nothing typed), or the typed text read as coordinates (formats behind the info button);
/// the button keeps the spot and names it.
class SpPlaceNameSheet extends BaseBottomSheet {
  const SpPlaceNameSheet({required this.place});

  /// The spot being named: its name fills the field, and distances are measured from it.
  final PlaceDbModel place;

  @override
  bool get fullScreen => false;

  /// One row per name + spot (~110m), nearest to [from] first: 50 stories at "Home" are one row,
  /// an old and a new "Home" two. Places without a name are skipped.
  @visibleForTesting
  static List<({PlaceDbModel place, double distance})> groupNamedPlaces(Iterable<PlaceDbModel> places, SpLatLng from) {
    final grouped = <String, PlaceDbModel>{};
    for (final place in places) {
      final name = place.placeName?.trim();
      if (name == null || name.isEmpty) continue;

      // Whole numbers, so -0.000 and 0.000 can't split one place in two.
      final key = '${name.toLowerCase()}|${(place.latitude * 1000).round()}|${(place.longitude * 1000).round()}';
      grouped.putIfAbsent(key, () => place);
    }

    return [for (final place in grouped.values) (place: place, distance: from.distanceTo(place.latLng))]
      ..sort((a, b) => a.distance.compareTo(b.distance));
  }

  @visibleForTesting
  static String formatDistance(double meters) {
    if (meters.round() < 1000) return '${meters.round()} m';
    if (meters < 9950) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${(meters / 1000).round()} km';
  }

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return Column(
      mainAxisSize: .min,
      children: [
        SizedBox(
          height: fixedContentHeight(context, bottomPadding),
          child: _PlaceNameBody(place: place),
        ),
        SizedBox(height: bottomPadding),
      ],
    );
  }
}

/// One row: a place, grouped from all the stories at (about) the same spot under the same name.
typedef _NamedPlace = ({PlaceDbModel place, double distance});

class _PlaceNameBody extends StatefulWidget {
  const _PlaceNameBody({required this.place});

  final PlaceDbModel place;

  @override
  State<_PlaceNameBody> createState() => _PlaceNameBodyState();
}

class _PlaceNameBodyState extends State<_PlaceNameBody> with DebounchedCallback {
  late final String initialName = widget.place.placeName?.trim() ?? '';

  // The current name, all selected: typing replaces it, and the list stays unfiltered until the user types.
  late final TextEditingController controller = TextEditingController(text: initialName)
    ..selection = TextSelection(baseOffset: 0, extentOffset: initialName.length);

  bool _edited = false;
  String get _name => controller.text.trim();

  // The typed text as coordinates (lat/lng, Apple Maps or a Plus Code), shown as a place to go to;
  // its area is filled in after. A name it isn't, so it can't be used to name the spot.
  PlaceDbModel? _coordinates;
  int _parseVersion = 0;

  bool get _canRename => _name.isNotEmpty && _name != initialName && _coordinates == null;

  List<_NamedPlace> _places = const [];

  @override
  void dispose() {
    cancelTimer(null);
    controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    // A lookup still running for the old text must not bring its row back.
    _parseVersion += 1;
    setState(() {
      _edited = true;
      // For the old text: gone right away, so it can't be tapped by mistake.
      _coordinates = null;
    });
    debouncedCallback(_parseCoordinates, duration: const Duration(milliseconds: 400));
  }

  Future<void> _parseCoordinates() async {
    if (!mounted) return;
    final version = ++_parseVersion;

    // A bare short Plus Code is recovered near the spot being named.
    final latLng = await SpCoordinateParserService.parse(_name, fallbackReference: widget.place.latLng);
    if (!mounted || version != _parseVersion || latLng == null) return;

    final place = PlaceDbModel(latitude: latLng.latitude, longitude: latLng.longitude);
    setState(() => _coordinates = place);

    final geocoded = await SpGeocodingService.systemInstance.reverseGeocode(latLng);
    if (!mounted || version != _parseVersion || geocoded == null) return;
    setState(() => _coordinates = place.copyWith(locality: geocoded.locality, country: geocoded.country));
  }

  Future<void> _showCoordinateFormats() async {
    final example = await const _CoordinateFormatsSheet().show<String>(context: context);
    if (example == null || !mounted) return;

    controller
      ..text = example
      ..selection = TextSelection.collapsed(offset: example.length);
    _onChanged();
  }

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    final places = SpPlaceNameSheet.groupNamedPlaces(await StoryDbModel.db.getNamedPlaces(), widget.place.latLng);
    if (mounted) setState(() => _places = places);
  }

  List<_NamedPlace> get _filteredPlaces {
    if (!_edited || _name.isEmpty) return _places;

    final fuzzy = Fuzzy<_NamedPlace>(
      _places,
      options: FuzzyOptions(
        isCaseSensitive: false,
        keys: [WeightedKey(name: 'name', getter: (e) => e.place.placeName ?? '', weight: 1)],
      ),
    );

    final results = fuzzy.search(_name)..sort((a, b) => a.score.compareTo(b.score));
    return results.map((r) => r.item).toList();
  }

  void _rename() {
    if (_canRename) Navigator.of(context).pop(SpPlaceNameRenamed(_name));
  }

  @override
  Widget build(BuildContext context) {
    final places = _filteredPlaces;
    final coordinates = _coordinates;

    return Column(
      crossAxisAlignment: .start,
      children: [
        Column(
          crossAxisAlignment: .start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr("input.place_name.label"),
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: TextTheme.of(context).titleLarge?.copyWith(color: ColorScheme.of(context).primary),
                    ),
                  ),
                  IconButton(
                    tooltip: tr("page.map.place_name.search_info_title"),
                    icon: const Icon(SpIcons.info),
                    onPressed: _showCoordinateFormats,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: controller,
                autofocus: true,
                textInputAction: .done,
                onChanged: (_) => _onChanged(),
                onSubmitted: (_) => _rename(),
                decoration: InputDecoration(hintText: tr("input.place_name.hint")),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        if (places.isNotEmpty || coordinates != null) SpSectionTitle(title: tr("general.places")),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: .onDrag,
            padding: EdgeInsets.zero,
            children: [
              if (coordinates != null) _buildCoordinatesTile(context, coordinates),
              for (final place in places) _buildPlaceTile(context, place),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: SpFilledButton(
              onPressed: _canRename ? _rename : null,
              child: Text(tr("button.name_this_spot")),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceTile(BuildContext context, _NamedPlace item) {
    final place = item.place;
    final area = place.areaLabel;

    return ListTile(
      leading: Icon(SpIcons.locationPin, color: ColorScheme.of(context).primary),
      title: Text(place.placeName ?? '', maxLines: 1, overflow: .ellipsis),
      subtitle: area == null ? null : Text(area, maxLines: 1, overflow: .ellipsis),
      trailing: Text(SpPlaceNameSheet.formatDistance(item.distance), style: TextTheme.of(context).bodySmall),
      onTap: () => Navigator.of(context).pop(SpPlaceNamePicked(place)),
    );
  }

  Widget _buildCoordinatesTile(BuildContext context, PlaceDbModel place) {
    final area = place.areaLabel;

    return ListTile(
      leading: Icon(SpIcons.myLocation, color: ColorScheme.of(context).primary),
      title: Text(
        '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
        maxLines: 1,
        overflow: .ellipsis,
      ),
      subtitle: area == null ? null : Text(area, maxLines: 1, overflow: .ellipsis),
      // Coordinates only: the Map tab looks up the details, so a name the user gave a place nearby wins.
      onTap: () => Navigator.of(context).pop(
        SpPlaceNamePicked(PlaceDbModel(latitude: place.latitude, longitude: place.longitude)),
      ),
    );
  }
}

/// How the search works: it finds the user's saved places, and takes typed coordinates in these
/// formats (one example each; pops the tapped one).
class _CoordinateFormatsSheet extends BaseBottomSheet {
  const _CoordinateFormatsSheet();

  // Private class: name it for analytics (it's from the runtime type otherwise).
  @override
  String get className => 'CoordinateFormatsSheet';

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    final examples = [
      (tr("page.map.place_name.latitude_longitude"), '13.41259, 103.86697'),
      ('Apple Maps', '29.97937° N, 31.13419° E'),
      ('Google Maps / Plus Code', 'MXQ4+M5 New York, USA'),
    ];

    final TextStyle? labelStyle = TextTheme.of(context).bodyMedium;
    final TextStyle valueStyle = (labelStyle ?? const TextStyle()).copyWith(
      fontWeight: .bold,
      color: ColorScheme.of(context).primary,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          Text(
            tr("page.map.place_name.search_info_title"),
            maxLines: 1,
            overflow: .ellipsis,
            style: TextTheme.of(context).titleLarge?.copyWith(color: ColorScheme.of(context).primary),
          ),
          const SizedBox(height: 8.0),
          Text(tr("page.map.place_name.search_info_message"), style: labelStyle),
          const SizedBox(height: 8.0),
          for (final (format, example) in examples)
            InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: () => Navigator.of(context).pop(example),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '• $format: ', style: labelStyle),
                      TextSpan(text: example, style: valueStyle),
                    ],
                  ),
                ),
              ),
            ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}
