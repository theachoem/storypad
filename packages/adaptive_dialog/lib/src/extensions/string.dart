extension StringEx on String {
  /// Capitalize first letter
  String get capitalized => '${this[0].toUpperCase()}${substring(1)}';

  /// Change to lower case and capitalize first letter
  ///
  /// Used for changing `CANCEL` to `Cancel` typically.
  String get capitalizedForce => toLowerCase().capitalized;
}
