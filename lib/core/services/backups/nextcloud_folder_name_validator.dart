import 'dart:convert';

/// Validates a user-typed Nextcloud storage folder name *before* it's handed
/// to [NextcloudCloudService.connect] — catches characters/lengths a WebDAV
/// server (or the filesystem underneath it) would reject, so the user gets
/// immediate, specific feedback instead of a generic "could not connect"
/// after a failed `mkdirAll`/`ping`.
///
/// Deliberately separate from [NextcloudCloudService.sanitizeFolderName]:
/// sanitizing silently cleans up slashes/`.`/`..` (harmless, no need to
/// bother the user about it), whereas the errors here are things only the
/// user can actually fix by typing something different.
enum NextcloudFolderNameValidationError {
  /// Contains a character no common filesystem/WebDAV server allows in a
  /// path segment: `\ < > : " | ? *` or a control character. These are the
  /// Windows-reserved set — Nextcloud's own server-side validation rejects
  /// several of them too, regardless of the client platform.
  invalidCharacters,

  /// A single path segment (the part between slashes) is longer than most
  /// filesystems allow for one file/directory name.
  segmentTooLong,
}

class NextcloudFolderNameValidator {
  NextcloudFolderNameValidator._();

  static final RegExp _forbiddenCharacterPattern = RegExp(r'[\\<>:"|?*\x00-\x1F]');

  /// Most filesystems (ext4, NTFS, APFS) cap a single path component at 255
  /// *bytes* — checked against the UTF-8 encoding, not [String.length]
  /// (UTF-16 code units), which would undercount multi-byte characters and
  /// let through segments the filesystem actually rejects (e.g. 250 CJK
  /// characters is ~750 bytes). 250 leaves headroom below the 255 cap.
  static const int _maxSegmentLength = 250;

  /// Null/blank input is always valid — it means "use the default".
  /// Segments that are already blank/`.`/`..` are skipped here too, since
  /// [NextcloudCloudService.sanitizeFolderName] silently drops those rather
  /// than erroring.
  static NextcloudFolderNameValidationError? validate(String? input) {
    if (input == null) return null;

    for (final rawSegment in input.split('/')) {
      final segment = rawSegment.trim();
      if (segment.isEmpty || segment == '.' || segment == '..') continue;

      if (_forbiddenCharacterPattern.hasMatch(segment)) {
        return NextcloudFolderNameValidationError.invalidCharacters;
      }
      if (utf8.encode(segment).length > _maxSegmentLength) {
        return NextcloudFolderNameValidationError.segmentTooLong;
      }
    }

    return null;
  }
}
