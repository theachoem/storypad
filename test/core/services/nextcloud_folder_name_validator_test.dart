import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/backups/nextcloud_folder_name_validator.dart';

void main() {
  group('NextcloudFolderNameValidator', () {
    test('null input is valid (use the default)', () {
      expect(NextcloudFolderNameValidator.validate(null), isNull);
    });

    test('blank input is valid', () {
      expect(NextcloudFolderNameValidator.validate(''), isNull);
      expect(NextcloudFolderNameValidator.validate('   '), isNull);
    });

    test('a plain name is valid', () {
      expect(NextcloudFolderNameValidator.validate('myjournal'), isNull);
    });

    test('a nested relative path is valid', () {
      expect(NextcloudFolderNameValidator.validate('Journals/MyDiary'), isNull);
    });

    test('ignores blank/./.. segments rather than erroring on them', () {
      expect(NextcloudFolderNameValidator.validate('Journals//MyDiary'), isNull);
      expect(NextcloudFolderNameValidator.validate('./myjournal'), isNull);
      expect(NextcloudFolderNameValidator.validate('../myjournal'), isNull);
    });

    for (final forbidden in [r'\', '<', '>', ':', '"', '|', '?', '*']) {
      test('rejects the forbidden character "$forbidden"', () {
        expect(
          NextcloudFolderNameValidator.validate('my${forbidden}journal'),
          NextcloudFolderNameValidationError.invalidCharacters,
        );
      });
    }

    test('rejects a control character', () {
      expect(
        NextcloudFolderNameValidator.validate('my\x00journal'),
        NextcloudFolderNameValidationError.invalidCharacters,
      );
    });

    test('rejects a single segment over the length limit', () {
      final tooLong = 'a' * 251;
      expect(
        NextcloudFolderNameValidator.validate(tooLong),
        NextcloudFolderNameValidationError.segmentTooLong,
      );
    });

    test('accepts a segment right at the length limit', () {
      final atLimit = 'a' * 250;
      expect(NextcloudFolderNameValidator.validate(atLimit), isNull);
    });

    test('checks every segment, not just the first', () {
      expect(
        NextcloudFolderNameValidator.validate('fine/bad*name'),
        NextcloudFolderNameValidationError.invalidCharacters,
      );
    });

    test('checks UTF-8 byte length, not UTF-16 code units', () {
      // Each 'あ' is one UTF-16 code unit (so String.length undercounts it)
      // but three UTF-8 bytes — 250 of them is 750 bytes, well past what a
      // WebDAV server/filesystem actually allows for one path segment.
      final segment = 'あ' * 250;
      expect(segment.length, 250); // would have passed the old (buggy) check
      expect(
        NextcloudFolderNameValidator.validate(segment),
        NextcloudFolderNameValidationError.segmentTooLong,
      );
    });

    test('accepts a multi-byte segment within the real byte limit', () {
      final segment = 'あ' * 83; // 249 bytes
      expect(NextcloudFolderNameValidator.validate(segment), isNull);
    });

    test('rejects a multi-byte segment just over the real byte limit', () {
      final segment = 'あ' * 84; // 252 bytes
      expect(
        NextcloudFolderNameValidator.validate(segment),
        NextcloudFolderNameValidationError.segmentTooLong,
      );
    });
  });
}
