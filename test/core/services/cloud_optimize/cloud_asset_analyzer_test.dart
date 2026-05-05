import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/cloud_optimize/cloud_asset_analyzer.dart';
import 'package:storypad/core/types/asset_type.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _serviceId = 'google_drive';
const _email = 'user@example.com';
const _otherEmail = 'other@example.com';

CloudFileObject _file(String id, String fileName) => CloudFileObject(fileName: fileName, id: id, description: null);

/// Create an [AssetDbModel] with the given [cloudDestinations].
AssetDbModel _asset(
  int id, {
  Map<String, Map<String, Map<String, String>>> cloudDestinations = const {},
}) {
  final now = DateTime(2024, 1, 1);
  return AssetDbModel(
    id: id,
    originalSource: 'images/$id.jpg',
    cloudDestinations: cloudDestinations,
    createdAt: now,
    updatedAt: now,
    lastSavedDeviceId: null,
    permanentlyDeletedAt: null,
    type: AssetType.image,
    tags: null,
  );
}

/// Build a typical destination map: one email pointing to [fileId].
Map<String, Map<String, Map<String, String>>> _destinations(
  String fileId, {
  String email = _email,
  String serviceId = _serviceId,
}) => {
  serviceId: {
    email: {'file_id': fileId, 'file_name': '$fileId.jpg'},
  },
};

CloudAssetAnalysisResult _analyze(
  List<CloudFileObject> cloudFiles,
  Map<int, AssetDbModel> recordById,
) => CloudAssetAnalyzer.analyze(
  cloudFiles: cloudFiles,
  recordById: recordById,
  serviceTypeId: _serviceId,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CloudAssetAnalyzer', () {
    // -----------------------------------------------------------------------
    // Basic cases
    // -----------------------------------------------------------------------

    test('empty input produces empty results', () {
      final result = _analyze([], {});
      expect(result.detached, isEmpty);
      expect(result.stale, isEmpty);
      expect(result.clean, isEmpty);
    });

    test('clean — file ID matches stored destination', () {
      final cloudFile = _file('cloud-abc', '1001.jpg');
      final record = _asset(1001, cloudDestinations: _destinations('cloud-abc'));
      final result = _analyze([cloudFile], {1001: record});

      expect(result.clean.map((f) => f.id), contains('cloud-abc'));
      expect(result.detached, isEmpty);
      expect(result.stale, isEmpty);
    });

    test('detached — no DB record for parsed asset ID', () {
      final cloudFile = _file('cloud-xyz', '9999.jpg');
      final result = _analyze([cloudFile], {}); // recordById is empty

      expect(result.detached.map((f) => f.id), contains('cloud-xyz'));
      expect(result.clean, isEmpty);
      expect(result.stale, isEmpty);
    });

    test('stale — record exists, file not attached, live copy IS in fetched set', () {
      // cloud-old is a stale duplicate; cloud-new is the live copy
      final staleFile = _file('cloud-old', '1002.jpg');
      final liveFile = _file('cloud-new', '1002.jpg');
      final record = _asset(1002, cloudDestinations: _destinations('cloud-new'));

      final result = _analyze([staleFile, liveFile], {1002: record});

      expect(result.stale.map((f) => f.id), contains('cloud-old'));
      expect(result.clean.map((f) => f.id), contains('cloud-new'));
      expect(result.detached, isEmpty);
    });

    test('orphan guard — record exists, no live copy in fetched set → not stale', () {
      // The stored file_id points to a file NOT present in our fetch — could be
      // from a different folder or already deleted. We must not delete this one.
      final unknownFile = _file('cloud-unknown', '1003.jpg');
      // Stored destination points to 'cloud-missing', which is absent from the fetch
      final record = _asset(1003, cloudDestinations: _destinations('cloud-missing'));

      final result = _analyze([unknownFile], {1003: record});

      expect(result.stale, isEmpty);
      // Should end up in clean (conservative — do not delete)
      expect(result.clean.map((f) => f.id), contains('cloud-unknown'));
      expect(result.detached, isEmpty);
    });

    // -----------------------------------------------------------------------
    // Multiple accounts
    // -----------------------------------------------------------------------

    test("multi-account — each email's file is clean", () {
      final fileA = _file('cloud-A', '2001.jpg');
      final fileB = _file('cloud-B', '2001.jpg');
      final record = _asset(
        2001,
        cloudDestinations: {
          _serviceId: {
            _email: {'file_id': 'cloud-A', 'file_name': '2001.jpg'},
            _otherEmail: {'file_id': 'cloud-B', 'file_name': '2001.jpg'},
          },
        },
      );

      final result = _analyze([fileA, fileB], {2001: record});

      expect(result.clean.map((f) => f.id), containsAll(['cloud-A', 'cloud-B']));
      expect(result.stale, isEmpty);
      expect(result.detached, isEmpty);
    });

    test('multi-account — unattached file is stale when live copy exists', () {
      final liveFileA = _file('cloud-A', '2002.jpg');
      final liveFileB = _file('cloud-B', '2002.jpg');
      final staleFile = _file('cloud-old', '2002.jpg');
      final record = _asset(
        2002,
        cloudDestinations: {
          _serviceId: {
            _email: {'file_id': 'cloud-A', 'file_name': '2002.jpg'},
            _otherEmail: {'file_id': 'cloud-B', 'file_name': '2002.jpg'},
          },
        },
      );

      final result = _analyze([liveFileA, liveFileB, staleFile], {2002: record});

      expect(result.stale.map((f) => f.id), contains('cloud-old'));
      expect(result.clean.map((f) => f.id), containsAll(['cloud-A', 'cloud-B']));
      expect(result.detached, isEmpty);
    });

    // -----------------------------------------------------------------------
    // Multiple duplicates for same asset ID
    // -----------------------------------------------------------------------

    test('3 files for same ID — 1 attached (clean), 2 stale', () {
      final liveFile = _file('cloud-live', '3001.jpg');
      final stale1 = _file('cloud-dup1', '3001.jpg');
      final stale2 = _file('cloud-dup2', '3001.jpg');
      final record = _asset(3001, cloudDestinations: _destinations('cloud-live'));

      final result = _analyze([liveFile, stale1, stale2], {3001: record});

      expect(result.clean.map((f) => f.id), contains('cloud-live'));
      expect(result.stale.map((f) => f.id), containsAll(['cloud-dup1', 'cloud-dup2']));
      expect(result.detached, isEmpty);
    });

    test('all 3 files detached when no DB record exists', () {
      final files = [
        _file('cloud-a', '4001.jpg'),
        _file('cloud-b', '4001.jpg'),
        _file('cloud-c', '4001.jpg'),
      ];

      final result = _analyze(files, {}); // no DB records

      expect(result.detached.map((f) => f.id), containsAll(['cloud-a', 'cloud-b', 'cloud-c']));
      expect(result.stale, isEmpty);
      expect(result.clean, isEmpty);
    });

    // -----------------------------------------------------------------------
    // Mixed assets in one batch
    // -----------------------------------------------------------------------

    test('mixed batch — correct classification per asset', () {
      // Asset 5001: clean
      final cleanFile = _file('cf-5001', '5001.jpg');
      final cleanRecord = _asset(5001, cloudDestinations: _destinations('cf-5001'));

      // Asset 5002: detached (no record)
      final detachedFile = _file('cf-5002', '5002.jpg');

      // Asset 5003: stale + live
      final staleFile = _file('cf-5003-old', '5003.jpg');
      final liveFile = _file('cf-5003-live', '5003.jpg');
      final staleRecord = _asset(5003, cloudDestinations: _destinations('cf-5003-live'));

      final result = _analyze(
        [cleanFile, detachedFile, staleFile, liveFile],
        {5001: cleanRecord, 5003: staleRecord},
      );

      expect(result.clean.map((f) => f.id), contains('cf-5001'));
      expect(result.clean.map((f) => f.id), contains('cf-5003-live'));
      expect(result.detached.map((f) => f.id), contains('cf-5002'));
      expect(result.stale.map((f) => f.id), contains('cf-5003-old'));
    });

    // -----------------------------------------------------------------------
    // Edge cases
    // -----------------------------------------------------------------------

    test('unparseable filename is excluded from all result lists', () {
      final badFile = _file('cloud-backup', 'backup.zip');
      final result = _analyze([badFile], {});

      expect(result.detached, isEmpty);
      expect(result.stale, isEmpty);
      expect(result.clean, isEmpty);
    });

    test('null filename is excluded from all result lists', () {
      final nullNameFile = CloudFileObject(fileName: null, id: 'cloud-null', description: null);
      final result = _analyze([nullNameFile], {});

      expect(result.detached, isEmpty);
      expect(result.stale, isEmpty);
      expect(result.clean, isEmpty);
    });

    test('record has no entry for this service — orphan guard applies', () {
      // cloudDestinations has only 'web_dav', not 'google_drive'
      final cloudFile = _file('cf-6001', '6001.jpg');
      final record = _asset(
        6001,
        cloudDestinations: {
          'web_dav': {
            'storypad': {'file_id': 'wd-6001', 'file_name': '6001.jpg'},
          },
        },
      );

      final result = _analyze([cloudFile], {6001: record});

      // destinations for google_drive is null → hasLiveCopy = false → orphan guard → clean
      expect(result.clean.map((f) => f.id), contains('cf-6001'));
      expect(result.stale, isEmpty);
      expect(result.detached, isEmpty);
    });

    test('counts are correct for total detached and stale', () {
      final files = [
        _file('live-1', '7001.jpg'),
        _file('stale-1', '7001.jpg'),
        _file('stale-2', '7001.jpg'),
        _file('det-1', '7002.jpg'),
        _file('det-2', '7003.jpg'),
      ];
      final record7001 = _asset(7001, cloudDestinations: _destinations('live-1'));

      final result = _analyze(files, {7001: record7001});

      expect(result.clean.length, 1); // live-1
      expect(result.stale.length, 2); // stale-1, stale-2
      expect(result.detached.length, 2); // det-1, det-2
    });

    // -----------------------------------------------------------------------
    // Re-verification (safety) scenarios
    //
    // These simulate what happens if cloudDestinations changed between the
    // analysis step and the actual deletion step — e.g. another device just
    // re-uploaded and updated the record.
    // -----------------------------------------------------------------------

    group('re-verification safety', () {
      test('file promoted to attached between analysis and deletion → classified clean', () {
        // Scenario: analysis said "stale", but by the time we re-verify, the
        // record now points to this file_id (another device updated it).
        final nowAttachedFile = _file('cloud-now-live', '8001.jpg');
        final record = _asset(8001, cloudDestinations: _destinations('cloud-now-live'));

        // Re-verification uses a fresh record that points to this file.
        final result = _analyze([nowAttachedFile], {8001: record});

        // Must be clean — do NOT delete.
        expect(result.clean.map((f) => f.id), contains('cloud-now-live'));
        expect(result.stale, isEmpty);
        expect(result.detached, isEmpty);
      });

      test('live copy disappeared between analysis and deletion → orphan guard keeps file', () {
        // Scenario: at analysis time the live copy existed, so this was stale.
        // By re-verification time, the live copy is gone from the batch
        // (e.g. it was deleted externally). We must NOT delete this copy either.
        final onlySurvivorFile = _file('cloud-survivor', '8002.jpg');
        // The stored destination points to 'cloud-gone', which is NOT in the batch.
        final record = _asset(8002, cloudDestinations: _destinations('cloud-gone'));

        final result = _analyze([onlySurvivorFile], {8002: record});

        // Orphan guard: no live copy confirmed → keep.
        expect(result.clean.map((f) => f.id), contains('cloud-survivor'));
        expect(result.stale, isEmpty);
      });

      test('record deleted from DB between analysis and deletion → now detached', () {
        // Scenario: local DB record was deleted (e.g. story deleted while optimize ran).
        // Without a record, the file is detached — safe to delete.
        final file = _file('cloud-orphan', '8003.jpg');

        // No record in fresh map.
        final result = _analyze([file], {});

        expect(result.detached.map((f) => f.id), contains('cloud-orphan'));
        expect(result.clean, isEmpty);
        expect(result.stale, isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // isDetachedEligibleForCleanup
    // -----------------------------------------------------------------------

    group('isDetachedEligibleForCleanup', () {
      CloudFileObject fileWithAge(String id, String name, {DateTime? createdAt}) =>
          CloudFileObject(fileName: name, id: id, description: null, createdAt: createdAt);

      AssetDbModel tombstone(int id, {DateTime? permanentlyDeletedAt}) {
        final now = DateTime(2024, 1, 1);
        return AssetDbModel(
          id: id,
          originalSource: 'images/$id.jpg',
          cloudDestinations: const {},
          createdAt: now,
          updatedAt: now,
          lastSavedDeviceId: null,
          permanentlyDeletedAt: permanentlyDeletedAt,
          type: AssetType.image,
          tags: null,
        );
      }

      test('null createdAt → not eligible', () {
        final file = fileWithAge('f1', '1.jpg', createdAt: null);
        expect(CloudAssetAnalyzer.isDetachedEligibleForCleanup(file), isFalse);
      });

      test('file created today → not eligible', () {
        final file = fileWithAge('f2', '2.jpg', createdAt: DateTime.now());
        expect(CloudAssetAnalyzer.isDetachedEligibleForCleanup(file), isFalse);
      });

      test('file created 29 days ago → not eligible', () {
        final file = fileWithAge('f3', '3.jpg', createdAt: DateTime.now().subtract(const Duration(days: 29)));
        expect(CloudAssetAnalyzer.isDetachedEligibleForCleanup(file), isFalse);
      });

      test('file created 31 days ago → eligible (no tombstone)', () {
        final file = fileWithAge('f4', '4.jpg', createdAt: DateTime.now().subtract(const Duration(days: 31)));
        expect(CloudAssetAnalyzer.isDetachedEligibleForCleanup(file), isTrue);
      });

      test('old cloud file with recent filename timestamp → not eligible', () {
        final recentAssetId = DateTime.now().millisecondsSinceEpoch;
        final file = fileWithAge(
          'f4b',
          '$recentAssetId.jpg',
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
        );

        expect(CloudAssetAnalyzer.isDetachedEligibleForCleanup(file), isFalse);
      });

      test('old cloud file with old filename timestamp → eligible', () {
        final oldAssetId = DateTime.now().subtract(const Duration(days: 60)).millisecondsSinceEpoch;
        final file = fileWithAge(
          'f4c',
          '$oldAssetId.jpg',
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
        );

        expect(CloudAssetAnalyzer.isDetachedEligibleForCleanup(file), isTrue);
      });

      test('file old enough but tombstone deleted 5 days ago → not eligible', () {
        final file = fileWithAge('f5', '5.jpg', createdAt: DateTime.now().subtract(const Duration(days: 60)));
        final ts = tombstone(5, permanentlyDeletedAt: DateTime.now().subtract(const Duration(days: 5)));
        expect(CloudAssetAnalyzer.isDetachedEligibleForCleanup(file, tombstone: ts), isFalse);
      });

      test('file old enough, tombstone deleted 31 days ago → eligible', () {
        final file = fileWithAge('f6', '6.jpg', createdAt: DateTime.now().subtract(const Duration(days: 60)));
        final ts = tombstone(6, permanentlyDeletedAt: DateTime.now().subtract(const Duration(days: 31)));
        expect(CloudAssetAnalyzer.isDetachedEligibleForCleanup(file, tombstone: ts), isTrue);
      });

      test('tombstone with null permanentlyDeletedAt → not eligible', () {
        final file = fileWithAge('f7', '7.jpg', createdAt: DateTime.now().subtract(const Duration(days: 60)));
        final ts = tombstone(7, permanentlyDeletedAt: null);
        expect(CloudAssetAnalyzer.isDetachedEligibleForCleanup(file, tombstone: ts), isFalse);
      });

      test('custom grace period is respected', () {
        final file = fileWithAge('f8', '8.jpg', createdAt: DateTime.now().subtract(const Duration(days: 10)));
        expect(
          CloudAssetAnalyzer.isDetachedEligibleForCleanup(file, gracePeriod: const Duration(days: 7)),
          isTrue,
        );
      });
    });
  });
}
