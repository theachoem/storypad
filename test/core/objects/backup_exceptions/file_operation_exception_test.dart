import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';

void main() {
  group('FileOperationException', () {
    test('creates with correct properties for upload operation', () {
      const exception = FileOperationException(
        'Upload failed',
        FileOperationType.upload,
        context: 'backup.json',
      );

      expect(exception.message, equals('Upload failed'));
      expect(exception.operation, equals(FileOperationType.upload));
      expect(exception.context, equals('backup.json'));
      expect(exception.isRetryable, isTrue);
      expect(exception.userFriendlyMessage, equals('Failed to upload backup. Please try again.'));
    });

    test('creates with correct properties for download operation', () {
      const exception = FileOperationException(
        'Download failed',
        FileOperationType.download,
      );

      expect(exception.message, equals('Download failed'));
      expect(exception.operation, equals(FileOperationType.download));
      expect(exception.context, isNull);
      expect(exception.isRetryable, isTrue);
      expect(
        exception.userFriendlyMessage,
        equals('Failed to download backup. Please check your connection and try again.'),
      );
    });

    test('creates with correct properties for delete operation', () {
      const exception = FileOperationException(
        'Delete failed',
        FileOperationType.delete,
        context: 'old_backup.json',
      );

      expect(exception.message, equals('Delete failed'));
      expect(exception.operation, equals(FileOperationType.delete));
      expect(exception.context, equals('old_backup.json'));
      expect(exception.isRetryable, isTrue);
      expect(exception.userFriendlyMessage, equals('Failed to delete backup file. Please try again.'));
    });

    test('creates with correct properties for list operation', () {
      const exception = FileOperationException(
        'List failed',
        FileOperationType.list,
        context: 'backup_folder',
      );

      expect(exception.message, equals('List failed'));
      expect(exception.operation, equals(FileOperationType.list));
      expect(exception.context, equals('backup_folder'));
      expect(exception.isRetryable, isTrue);
      expect(
        exception.userFriendlyMessage,
        equals('Failed to load backup files. Please check your connection and try again.'),
      );
    });

    test('is retryable by default', () {
      const exception = FileOperationException(
        'Operation failed',
        FileOperationType.upload,
      );
      expect(exception.isRetryable, isTrue);
    });

    test('can be made non-retryable', () {
      const exception = FileOperationException(
        'Operation failed',
        FileOperationType.upload,
        isRetryable: false,
      );
      expect(exception.isRetryable, isFalse);
    });

    test('toString includes operation context', () {
      const exception = FileOperationException(
        'Upload failed',
        FileOperationType.upload,
        context: 'test_file.json',
      );
      expect(exception.toString(), equals('BackupException: Upload failed (test_file.json)'));
    });

    group('FileOperationType enum', () {
      test('has all expected values', () {
        expect(FileOperationType.values, hasLength(4));
        expect(FileOperationType.values, contains(FileOperationType.upload));
        expect(FileOperationType.values, contains(FileOperationType.download));
        expect(FileOperationType.values, contains(FileOperationType.delete));
        expect(FileOperationType.values, contains(FileOperationType.list));
      });
    });
  });
}
