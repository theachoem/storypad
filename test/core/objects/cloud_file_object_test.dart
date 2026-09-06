import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';

void main() {
  // Only fromDropbox is covered here — the other factories (fromGoogleDrive,
  // fromNextcloud, fromICloud) have no existing test coverage either, and
  // backfilling those is out of scope for this change.
  group('CloudFileObject.fromDropbox', () {
    test('parses id, name, size, and timestamps from live FileMetadata', () {
      final file = CloudFileObject.fromDropbox({
        '.tag': 'file',
        'name': 'Backup__3__2026__1234567890__device__id.zip',
        'id': 'id:abc123',
        'size': 4096,
        'client_modified': '2026-01-01T00:00:00Z',
        'server_modified': '2026-01-02T00:00:00Z',
      });

      expect(file.id, 'id:abc123');
      expect(file.fileName, 'Backup__3__2026__1234567890__device__id.zip');
      expect(file.sizeInBytes, 4096);
      expect(file.createdAt, DateTime.parse('2026-01-01T00:00:00Z'));
      expect(file.modifiedAt, DateTime.parse('2026-01-02T00:00:00Z'));
      expect(file.trashed, isFalse);
    });

    test('falls back to idOverride for deleted metadata, which carries no id field', () {
      final file = CloudFileObject.fromDropbox(
        {'.tag': 'deleted', 'name': 'old_backup.zip'},
        trashed: true,
        idOverride: 'id:the-original-query-key',
      );

      expect(file.id, 'id:the-original-query-key');
      expect(file.trashed, isTrue);
      expect(file.sizeInBytes, isNull);
    });

    test('defaults trashed to false when not specified', () {
      final file = CloudFileObject.fromDropbox({'name': 'a.zip', 'id': 'id:1'});
      expect(file.trashed, isFalse);
    });
  });
}
