extension StringExtension on String {
  String get capitalize {
    return this[0].toUpperCase() + substring(1);
  }

  /// Removes lone UTF-16 surrogates (U+D800–U+DFFF) that are not part of a
  /// valid surrogate pair. Flutter's native text engine throws an
  /// "Invalid argument(s): string is not well-formed UTF-16" error when such
  /// characters are passed to a [TextSpan] or [Text] widget.
  String get sanitizeUtf16 {
    final units = codeUnits;
    final result = <int>[];
    for (int i = 0; i < units.length; i++) {
      final u = units[i];
      if (u >= 0xD800 && u <= 0xDBFF) {
        // High surrogate — only keep it when followed by a valid low surrogate.
        if (i + 1 < units.length && units[i + 1] >= 0xDC00 && units[i + 1] <= 0xDFFF) {
          result.add(u);
          result.add(units[i + 1]);
          i++;
        }
        // Otherwise drop the lone high surrogate.
      } else if (u >= 0xDC00 && u <= 0xDFFF) {
        // Lone low surrogate — drop it.
      } else {
        result.add(u);
      }
    }
    return String.fromCharCodes(result);
  }
}
