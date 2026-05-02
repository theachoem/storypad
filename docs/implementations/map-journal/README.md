# Map Journal

Location-aware journal entries: manual pin-drop, reverse geocoding, map view with clustering, and cross-platform import/export.

## Architecture

```
Story Editor (SpStoryLabels widget)
    ↓ (user taps location label)
MapPickerView (full-screen map, tap to pin)
    ↓ (confirm → MapPickerResult)
SpGeocodingService.reverseGeocode(SpLatLng) → PlaceDbModel
    ↓
StoryDbModel.place (PlaceDbModel)
    ↓ (persisted as JSON in StoryObjectBox.place, lat/lon unpacked separately)
StoryObjectBox: latitude, longitude (range-queryable), place (JSON string)
```

```
Map View
    ↓ (camera idle → debounced 50 ms → onViewportChanged)
MapViewModel.handleViewportChanged(SpMapViewport)
    ↓ (expand bounds by _viewportFetchExpansionFactor)
StoriesBox.getStoriesWithLocation(bounds)  ← ObjectBox between() query on lat/lon
    ↓ (_limitStoriesByDistance: keep 100 closest to viewport centre)
SpMapMarker<MapStoryObject> list → SpGoogleMap
    ↓ (native Google Maps ClusterManager handles marker grouping)
_MapStoryMarkerIconFactory — BitmapDescriptor rendered per marker
```

## Files

```
lib/core/databases/models/
  place_db_model.dart              # PlaceDbModel — lat, lon, placeName, locality, country, address

lib/core/databases/adapters/objectbox/
  entities.dart                    # StoryObjectBox: +latitude, +longitude, +place fields

lib/core/services/geocoding/
  sp_geocoding_service.dart        # abstract SpGeocodingService + singleton (.instance)
  sp_null_geocoding_service.dart   # Linux / Windows / Web no-op stub
  system/
    sp_system_geocoding_service.dart  # iOS / Android / macOS (geocoding package)

lib/views/map/
  map_view.dart                    # MapRoute + MapView (entry point)
  map_view_model.dart              # MapViewModel — viewport handling, story fetching, asset caching
  map_content.dart                 # _MapContent, _FlutterMapStoryMarker, _MapStoryMarkerIconFactory
  local_widgets/
    maps/
      map_types.dart               # SpMapRenderer, SpMapStyle, SpMapCamera, SpMapViewport, SpMapMarker
      sp_map_controller.dart       # SpMapController — animateTo, zoomBy, resetRotation
      sp_google_maps_flutter.dart  # SpGoogleMap<T> — Google Maps adapter with ClusterManager
      sp_flutter_map.dart          # SpFlutterMap<T> — flutter_map adapter (fallback)
    marker_preparing_pill.dart     # loading indicator shown while marker icons are being built
    sp_map_side_button.dart        # icon button used in map overlays
    sp_map_zoom_controls.dart      # +/- zoom overlay buttons
  picker/
    map_picker_view.dart           # MapPickerRoute, MapPickerView, MapPickerResult
    map_picker_view_model.dart     # MapPickerViewModel — pin selection, reverse geocoding
    map_picker_content.dart        # UI part of the picker
```

## DB Design

### `StoryObjectBox` (ObjectBox entity)

Two **indexed** float columns are added for bounding-box queries:

| Field       | Type      | Index | Purpose                                                     |
| ----------- | --------- | ----- | ----------------------------------------------------------- |
| `latitude`  | `double?` | ❌    | `between()` range query (full scan, fine for journal scale) |
| `longitude` | `double?` | ❌    | `between()` range query (full scan, fine for journal scale) |
| `place`     | `String?` | —     | JSON-encoded `PlaceDbModel`                                 |

> ObjectBox does not support `@Index` on `double?` fields.

`latitude` + `longitude` are unpacked from `PlaceDbModel` at write time. This lets new location fields (e.g. `typeOfPlace`, `region`) be added to `PlaceDbModel` without touching the entity schema.

### `PlaceDbModel` (`@JsonSerializable`)

```dart
class PlaceDbModel {
  final double latitude;
  final double longitude;
  final String? placeName;   // "Knowledge Cafe"
  final String? locality;    // "Phnom Penh"  (DayOne: localityName, Apple Journal: city)
  final String? country;     // "Cambodia"
  final String? address;     // full formatted address
}
```

### `StoryDbModel`

Adds `PlaceDbModel? place` and convenience getters:

```dart
bool get hasLocation => place != null;
SpLatLng? get latLng => place != null ? SpLatLng(place!.latitude, place!.longitude) : null;
```

## Geocoding Service

Follows the platform-adapter pattern:

```
SpGeocodingService (abstract)
    ↓ SpGeocodingService.instance (platform-selected singleton)
SpSystemGeocodingService   ← iOS / Android / macOS  (geocoding package, free)
SpNullGeocodingService     ← Linux / Windows / Web  (offline no-op)
```

API:

- `reverseGeocode(SpLatLng) → Future<PlaceDbModel?>` — coordinates → place (returns `null` when unavailable)
- `searchPlaces(String query) → Future<List<PlaceDbModel>>` — text search (returns empty list when unavailable)

## Map View — Story Loading & Markers

## Initial Camera

The map screens share one initial-camera policy so they do not fall back to a
country-specific default when the user has journals or device location elsewhere.

Fallback order:

1. Map picker editing an existing place: center on that selected place.
2. Device-derived location: regular map uses current location only when permission
   is already available; map picker uses last-known location without prompting.
3. Recent geotagged journals: use a recent, tight cluster when possible; otherwise
   use the most recent geotagged journal instead of averaging far-apart trips.
4. Neutral world camera: final fallback when there is no usable location source.

This keeps a journal set in Cambodia from opening in San Francisco, and prevents
mixed-continent journal locations from producing a misleading midpoint.

### Bounding-box query

```dart
// ObjectBox range query — no @Index on double?, full scan (fine for journal scale)
StoryObjectBox_.latitude.between(bounds.south, bounds.north)
  .and(StoryObjectBox_.longitude.between(bounds.west, bounds.east))
  .and(StoryObjectBox_.latitude.notNull())
  .and(StoryObjectBox_.longitude.notNull())
  .and(StoryObjectBox_.place.notNull())
  .and(StoryObjectBox_.permanentlyDeletedAt.isNull())
```

### Viewport flow

1. Camera moves → `onCameraMove` debounces 50 ms → `MapViewModel.handleViewportChanged`
2. Viewport bounds are expanded by `_viewportFetchExpansionFactor(zoom)` (1.15 × at zoom 4 → 2.2 × at zoom 16) before querying, so panning slightly doesn't re-fetch.
3. `_limitStoriesByDistance` keeps at most 100 stories closest to the viewport centre (Euclidean lat/lon distance).
4. Markers are `SpMapMarker<MapStoryObject>` passed to `SpGoogleMap<T>`.

### Clustering & marker icons

- Google Maps native **`ClusterManager`** (from `google_maps_flutter`) handles marker grouping automatically.
- Custom `BitmapDescriptor` icons are rendered per marker by `_MapStoryMarkerIconFactory` (renders a Flutter widget to an image off-screen).
- `SpGoogleMap` tracks a `_prepareVersion` so stale async icon builds are discarded when markers change.

## Import / Export

### StoryPad backup JSON

```json
{
  "place": {
    "latitude": 11.5793136,
    "longitude": 104.8742554,
    "placeName": "Knowledge Cafe",
    "locality": "Phnom Penh",
    "country": "Cambodia",
    "address": "HVHF+RRM, Phnom Penh, Cambodia"
  }
}
```

`PlaceDbModel` is `@JsonSerializable` so `StoryDbModel.toJson()` / `fromJson()` handle this automatically.

### DayOne field mapping

| DayOne field            | PlaceDbModel field |
| ----------------------- | ------------------ |
| `location.latitude`     | `latitude`         |
| `location.longitude`    | `longitude`        |
| `location.placeName`    | `placeName`        |
| `location.localityName` | `locality`         |
| `location.country`      | `country`          |
| `location.address`      | `address`          |

### Apple Journal field mapping

| Apple Journal field     | PlaceDbModel field   |
| ----------------------- | -------------------- |
| `visits[0].latitude`    | `latitude`           |
| `visits[0].longitude`   | `longitude`          |
| `visits[0].placeName`   | `placeName`          |
| `visits[0].city`        | `locality`           |
| `visits[0].typeOfPlace` | _(ignored / future)_ |

## Implementation Phases

| Phase | Task                                                               | Status |
| ----- | ------------------------------------------------------------------ | ------ |
| 1     | `PlaceDbModel` + `StoryObjectBox` schema + `StoryDbModel` + mapper | ✅     |
| 2     | `SpGeocodingService` abstraction layer                             | ✅     |
| 3     | `MapPickerView` + story editor integration (`SpStoryLabels`)       | ✅     |
| 4     | Map view — `getStoriesWithLocation` + ClusterManager markers       | ✅     |
| 5     | Import/export — DayOne + Apple Journal converters                  | 🔲     |
