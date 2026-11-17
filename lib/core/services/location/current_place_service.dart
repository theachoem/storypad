import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/location/place_details_service.dart';
import 'package:storypad/core/services/location/sp_location_service.dart';
import 'package:storypad/core/services/map/place_selection_service.dart';

/// Sets the phone's current location as a story's place without making the user wait — the pin on a
/// story dated today, and a story started from the map.
///
/// 1. Coordinates first: the last known position when it's recent (instant, no GPS), else a fresh fix. Near
///    one of the user's named places, that place itself (its spot and name, as tapping its dot on the map
///    would; see [PlaceDetailsService.savedPlaceAtCurrentLocation]): local, so offline too.
/// 2. Then quietly: a fresh fix replaces a last known position that's off by more than [_movedEnough] (or
///    lands at another of the user's places), and the details are looked up (offline: what's there stays).
///
/// Each later step applies only while the story's place is still the one set before it: a place the user
/// changed or renamed meanwhile is never overwritten.
class CurrentPlaceService {
  const CurrentPlaceService._();

  static const Duration _recentEnough = Duration(minutes: 5);
  static const double _movedEnough = 50.0;

  static final ValueNotifier<Set<String>> _locating = ValueNotifier(const {});

  /// Spots set from the current location whose name is still being looked up (see [isLocating]).
  static ValueListenable<Set<String>> get locating => _locating;

  /// Whether [place] was set from the current location and its name is still being looked up:
  /// shown as "Current location" meanwhile, rather than bare coordinates.
  static bool isLocating(PlaceDbModel place) => _locating.value.contains(PlaceDetailsService.spotKey(place.latLng));

  /// Returns once the coordinates are set — or false, with nothing set, when there's no location access
  /// (asks for it if undecided) or no position. [currentPlace] is the story's place now; [setPlace] saves one.
  static Future<bool> add({
    required PlaceDbModel? Function() currentPlace,
    required Future<void> Function(PlaceDbModel place) setPlace,
  }) async {
    if (await SpLocationService.checkAccess() != .success) return false;

    final recent = await SpLocationService.fetchLastKnownLocation(maxAge: _recentEnough);
    final latLng = recent ?? await SpLocationService.fetchFreshLatLng();
    if (latLng == null) return false;

    final place = await _placeAt(latLng);
    _mark(place, locating: true);
    await setPlace(place);

    unawaited(_refine(place, freshFix: recent != null, currentPlace: currentPlace, setPlace: setPlace));
    return true;
  }

  static Future<void> _refine(
    PlaceDbModel place, {
    required bool freshFix,
    required PlaceDbModel? Function() currentPlace,
    required Future<void> Function(PlaceDbModel place) setPlace,
  }) async {
    bool isStill(PlaceDbModel place) {
      final current = currentPlace();
      return current != null && !PlaceSelectionService.hasChanges(current, place);
    }

    try {
      if (freshFix) {
        final fresh = await SpLocationService.fetchFreshLatLng();
        final moved = fresh != null && isStill(place) ? await _placeAt(fresh) : null;
        if (moved != null && isStill(place) && _hasMoved(from: place, to: moved, fresh: fresh!)) {
          _mark(moved, locating: true);
          _mark(place, locating: false);
          place = moved;
          await setPlace(moved);
        }
      }

      final details = await PlaceDetailsService.details(place);
      if (details != null && isStill(place)) await setPlace(details);
    } finally {
      _mark(place, locating: false);
    }
  }

  static Future<PlaceDbModel> _placeAt(SpLatLng latLng) async {
    final saved = await PlaceDetailsService.savedPlaceAtCurrentLocation(latLng);
    return saved ?? PlaceDbModel(latitude: latLng.latitude, longitude: latLng.longitude);
  }

  // Another of the user's places, or far enough from where the rougher position put it.
  static bool _hasMoved({required PlaceDbModel from, required PlaceDbModel to, required SpLatLng fresh}) {
    if (PlaceSelectionService.isSameSpot(from.latLng, to.latLng)) return false;
    if (to.placeName?.trim().isNotEmpty == true) return true;
    return SpLocationService.distanceBetween(fresh, from.latLng) > _movedEnough;
  }

  static void _mark(PlaceDbModel place, {required bool locating}) {
    final key = PlaceDetailsService.spotKey(place.latLng);
    _locating.value = locating ? {..._locating.value, key} : ({..._locating.value}..remove(key));
  }
}
