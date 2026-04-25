// ignore_for_file: depend_on_referenced_packages

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:storypad/core/services/cloud_storage/adaptors/base_cloud_storage_adaptor.dart';
import 'package:storypad/core/services/cloud_storage/adaptors/cdn_cloud_storage_adaptor.dart';

CdnCloudStorageAdaptor _adapterWith(http.Client client) {
  return CdnCloudStorageAdaptor(baseUrl: 'https://cdn.example.com', httpClient: client);
}

void main() {
  group('CdnCloudStorageAdaptor', () {
    group('getDownloadUrl', () {
      test('returns baseUrl + hashPath', () async {
        final adaptor = CdnCloudStorageAdaptor(baseUrl: 'https://cdn.example.com');
        final url = await adaptor.getDownloadUrl('/sounds/forest.mp3');
        expect(url, equals('https://cdn.example.com/sounds/forest.mp3'));
      });
    });

    group('downloadBytes', () {
      test('returns body bytes on HTTP 200', () async {
        final expected = Uint8List.fromList([1, 2, 3]);
        final adaptor = _adapterWith(
          MockClient((_) async => http.Response.bytes(expected, 200)),
        );
        final bytes = await adaptor.downloadBytes('/file.bin');
        expect(bytes, equals(expected));
      });

      test('throws CloudStorageUnauthorizedException on HTTP 401', () async {
        final adaptor = _adapterWith(
          MockClient((_) async => http.Response('Unauthorized', 401)),
        );
        await expectLater(
          adaptor.downloadBytes('/secure.bin'),
          throwsA(isA<CloudStorageUnauthorizedException>()),
        );
      });

      test('throws CloudStorageUnauthorizedException on HTTP 403', () async {
        final adaptor = _adapterWith(
          MockClient((_) async => http.Response('Forbidden', 403)),
        );
        await expectLater(
          adaptor.downloadBytes('/private.bin'),
          throwsA(isA<CloudStorageUnauthorizedException>()),
        );
      });

      test('returns null on non-200 non-401/403 status', () async {
        final adaptor = _adapterWith(
          MockClient((_) async => http.Response('Not Found', 404)),
        );
        final bytes = await adaptor.downloadBytes('/missing.bin');
        expect(bytes, isNull);
      });

      test('returns null on network error', () async {
        final adaptor = _adapterWith(
          MockClient((_) async => throw Exception('Network error')),
        );
        final bytes = await adaptor.downloadBytes('/file.bin');
        expect(bytes, isNull);
      });
    });
  });
}
