# Map Journal

Location-aware journal entries: manual pin-drop, reverse geocoding, map view with clustering, and cross-platform import/export.

## Architecture

```
Story Editor
    ↓ (user taps "Add Location")
MapPickerView (full-screen map, tap to pin)
    ↓ (confirm)
SpGeocodingService.reverseGeocode(SpLatLng) → SpPlaceResult
    ↓
StoryDbModel.place (PlaceDbModel)
    ↓ (persisted as JSON in StoryObjectBox.place, lat/lon indexed separately)
StoryObjectBox: latitude, longitude (range-queryable), place (JSON string)
```

```
Map View
    ↓ (camera idle → visible bounds)
StoriesBox.fetchWithinBounds(LatLngBounds)  ← ObjectBox bounding-box query on indexed lat/lon
    ↓
Client-side grid clustering (zoom-aware cell size)
    ↓
SpWidgetMapMarker per cluster/pin
```

## Files

```
lib/core/databases/models/
  place_db_model.dart              # PlaceDbModel — lat, lon, placeName, locality, country, address

lib/core/databases/adapters/objectbox/
  entities.dart                    # StoryObjectBox: +latitude, +longitude, +place fields

lib/core/services/geocoding/
  sp_geocoding_service.dart        # abstract SpGeocodingService + singleton factory
  sp_place_result.dart             # value object returned by geocoding
  system/
    sp_system_geocoding_service.dart  # iOS / Android / macOS (geocoding package)
  sp_null_geocoding_service.dart   # Linux / Windows / Web no-op stub

lib/views/map/
  picker/
    map_picker_view.dart           # full-screen map, tap to pin, confirm
    map_picker_view_model.dart
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

Follows the `SpMapAdapter` factory pattern:

```
SpGeocodingService (abstract)
    ↓ singleton factory
SpSystemGeocodingService   ← iOS / Android / macOS  (geocoding package, free)
SpNullGeocodingService     ← Linux / Windows / Web  (offline no-op)
```

API:

- `reverseGeocode(SpLatLng) → Future<SpPlaceResult?>` — coordinates → place name
- `searchPlaces(String query) → Future<List<SpPlaceResult>>` — for search in location picker

## Map View — Clustering

### Bounding-box query

```dart
// ObjectBox range query on indexed lat/lon
box.query(
  StoryObjectBox_.latitude.between(bounds.sw.latitude, bounds.ne.latitude)
    .and(StoryObjectBox_.longitude.between(bounds.sw.longitude, bounds.ne.longitude))
    .and(StoryObjectBox_.permanentlyDeletedAt.isNull()),
).build().findAsync();
```

### Grid-based clustering

1. Camera idle → debounced ~300 ms
2. Compute `cellSize = baseDegrees / pow(2, zoom - baseZoom)` from current zoom
3. Group entries by `(lat / cellSize).floor(), (lon / cellSize).floor()`
4. 1 entry → `SpWidgetMapMarker` with story preview chip
5. 2+ entries → `SpWidgetMapMarker` with count badge
6. Tap pin → navigate to story; tap cluster → `mapController.animateTo(center, zoom + 2)`

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
| 1     | `PlaceDbModel` + `StoryObjectBox` schema + `StoryDbModel` + mapper | 🔲     |
| 2     | `SpGeocodingService` abstraction layer                             | 🔲     |
| 3     | `MapPickerView` + story editor integration                         | 🔲     |
| 4     | Map view — `fetchWithinBounds` + clustering                        | 🔲     |
| 5     | Import/export — DayOne + Apple Journal converters                  | 🔲     |
