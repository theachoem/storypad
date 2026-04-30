# Map Abstraction Layer

Cross-platform map rendering and camera control behind `SpMapAdapter` / `SpMapController` interfaces, mirroring the `RichTextAdapter` pattern.

## Architecture

```
View / ViewModel
    ↓ (calls mapAdapter.buildMap / mapAdapter.createController)
SpMapAdapter (abstract)
    ↓ (singleton selects by platform)
SpGoogleMapsAdapter   ← iOS / Android  (google_maps_flutter)
SpFlutterMapAdapter   ← macOS / Windows / Linux  (flutter_map + MapTiler)
```

## Files

```
lib/core/map/
  sp_map_adapter.dart              # abstract SpMapAdapter + mapAdapter singleton
  sp_map_controller.dart           # abstract SpMapController
  sp_map_marker.dart               # sealed SpMapMarker hierarchy
  sp_map_tile_style.dart           # SpMapTileStyle enum (streets / satellite) — no URLs
  sp_latlng.dart                   # package-agnostic LatLng value type
  flutter_map/
    sp_flutter_map_adapter.dart    # desktop implementation (owns maptilerUrl)
    sp_flutter_map_controller.dart # wraps flutter_map MapController
  google_maps/
    sp_google_maps_adapter.dart    # iOS/Android implementation
    sp_google_maps_controller.dart # wraps google_maps_flutter GoogleMapController
```

> **`sp_` file prefix** avoids name collisions with `flutter_map` and `google_maps_flutter`
> which export their own `Marker`, `MapController`, `LatLng`, etc.

## Usage

```dart
// ViewModel — create controller once
final SpMapController mapController = mapAdapter.createController();

// Widget — build the map
mapAdapter.buildMap(
  context: context,
  markers: [
    SpWidgetMapMarker(
      position: SpLatLng(11.5625, 104.916),
      builder: (context) => Icon(SpIcons.map),
    ),
  ],
  tileStyle: SpMapTileStyle.streets,
  controller: mapController,
)

// Programmatic camera move
await mapController.animateTo(SpLatLng(11.5625, 104.916), zoom: 14);
await mapController.moveTo(SpLatLng(11.5625, 104.916));  // instant
```

## Tile URL Responsibility

`SpMapTileStyle` only declares **what** the style is (`streets` / `satellite`) and its
display `label`. It knows nothing about URLs or map packages.

Each adapter owns its own tile resolution:
- `SpFlutterMapAdapter._tileUrl(style)` → MapTiler URL (private, desktop-only)
- `SpGoogleMapsAdapter` → passes `MapType` to the native Google Maps SDK (no URL needed)

## Marker System

`SpMapMarker` is `sealed` — add new subtypes without touching the adapter interface:

| Subtype | Use case |
|---------|----------|
| `SpWidgetMapMarker` | Any Flutter widget as pin (icon, badge, image, count chip, …) |

## Controller Lifecycle

| Platform | Controller type | Ready when? |
|----------|----------------|-------------|
| Desktop | `SpFlutterMapController` | Immediately after creation |
| Mobile | `SpGoogleMapsController` | After `onMapCreated` callback fires |

Calls to `animateTo` / `moveTo` before the native map is ready are silently dropped on mobile.

## Tile Styles

| Style | Desktop (MapTiler) | Mobile (Google Maps) |
|-------|-------------------|---------------------|
| `streets` | MapTiler streets tiles | `MapType.normal` |
| `satellite` | MapTiler hybrid tiles | `MapType.satellite` |

## API Keys

### Android
Set `GOOGLE_MAPS_ANDROID_API_KEY` in `private_keys/dart_defines/*.json`.
`build.gradle.kts` reads it via `dartDefines` and injects it into `AndroidManifest.xml` as a manifest placeholder.

### iOS
Set `GOOGLE_MAPS_IOS_API_KEY` in `private_keys/dart_defines/*.json`.
Expose as an Xcode build setting (xcconfig) so `$(GOOGLE_MAPS_IOS_API_KEY)` is substituted in `Info.plist`,
then `AppDelegate.swift` passes it to `GMSServices.provideAPIKey(...)`.

### Desktop
No key required — MapTiler tiles use the hardcoded key inside `SpFlutterMapAdapter._tileUrl()`.
