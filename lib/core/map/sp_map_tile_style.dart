/// Map tile/style type used across all [SpMapAdapter] implementations.
enum SpMapTileStyle {
  streets,
  satellite
  ;

  String get label {
    switch (this) {
      case SpMapTileStyle.streets:
        return 'Streets';
      case SpMapTileStyle.satellite:
        return 'Satellite';
    }
  }

  SpMapTileStyle get toggled {
    switch (this) {
      case SpMapTileStyle.streets:
        return SpMapTileStyle.satellite;
      case SpMapTileStyle.satellite:
        return SpMapTileStyle.streets;
    }
  }
}
