import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/objects/sp_latlng.dart';

/// The rules for a place being picked on a map: whether it still needs its details, which name
/// wins once they're looked up, and whether saving it would change anything. Pure: no DB, no geocoder.
class PlaceSelectionService {
  const PlaceSelectionService._();

  /// Whether [place] still lacks its locality/country.
  static bool needsDetails(PlaceDbModel? place) => place != null && place.locality?.trim().isNotEmpty != true;

  /// [place] with the lookups' details: the geocoder's locality/country/address, and a name — its own,
  /// else the user's name for a place nearby ([saved], from their stories), else the geocoder's.
  /// Always at [place]'s own spot. Null if neither lookup found anything.
  static PlaceDbModel? mergeDetails(PlaceDbModel place, {PlaceDbModel? saved, PlaceDbModel? geocoded}) {
    if (saved == null && geocoded == null) return null;

    final ownName = place.placeName?.trim();
    final name = ownName != null && ownName.isNotEmpty ? ownName : saved?.placeName ?? geocoded?.placeName;
    return (geocoded ?? place).copyWith(latitude: place.latitude, longitude: place.longitude, placeName: name);
  }

  /// Within ~11m on both axes.
  static bool isSameSpot(SpLatLng a, SpLatLng b) {
    const double threshold = 0.0001;
    return (a.latitude - b.latitude).abs() < threshold && (a.longitude - b.longitude).abs() < threshold;
  }

  /// Whether saving [selected] would change the story's [saved] place.
  static bool hasChanges(PlaceDbModel selected, PlaceDbModel? saved) {
    if (saved == null) return true;

    String? text(String? value) {
      final trimmed = value?.trim();
      return trimmed == null || trimmed.isEmpty ? null : trimmed;
    }

    return selected.latitude != saved.latitude ||
        selected.longitude != saved.longitude ||
        text(selected.placeName) != text(saved.placeName) ||
        text(selected.locality) != text(saved.locality) ||
        text(selected.country) != text(saved.country) ||
        text(selected.address) != text(saved.address);
  }
}
