class TagIdGeneratorService {
  /// Cutoff boundary:
  /// - All timestamp IDs will be < cutoff
  /// - All emoji IDs will be >= cutoff
  ///
  /// 1 << 60 ≈ 1.15e18
  /// Gives ~36,000 years before timestamps reach this value
  static const int cutoff = 1 << 60;

  // ==============================
  // TIME ID (unique)
  // ==============================
  /// Generates a unique ID based on current time (microseconds)
  /// Always less than cutoff
  static int timeId() {
    return DateTime.now().microsecondsSinceEpoch;
  }

  // ==============================
  // EMOJI ID (deterministic)
  // ==============================
  /// Generates a reproducible ID from emoji
  /// Same emoji → same ID
  /// Always >= cutoff
  static int emojiId(String emoji) {
    int hash = 0;

    // Use runes (important for emoji correctness)
    for (final r in emoji.runes) {
      hash = hash * 31 + r;
    }

    // Keep hash inside safe range (below cutoff)
    hash = hash & (cutoff - 1);

    return cutoff + hash;
  }

  // ==============================
  // HELPERS
  // ==============================
  static bool isEmoji(int id) => id >= cutoff;
  static bool isTime(int id) => id < cutoff;
}
