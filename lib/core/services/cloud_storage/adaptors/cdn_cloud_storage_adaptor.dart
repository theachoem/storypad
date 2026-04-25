import 'dart:typed_data';

// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:storypad/core/services/cloud_storage/adaptors/base_cloud_storage_adaptor.dart';

class CdnCloudStorageAdaptor extends BaseCloudStorageAdaptor {
  final String baseUrl;
  final http.Client _httpClient;

  CdnCloudStorageAdaptor({required this.baseUrl, http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  @override
  Future<Uint8List?> downloadBytes(String hashPath) async {
    try {
      final response = await _httpClient.get(Uri.parse('$baseUrl$hashPath'));
      if (response.statusCode == 200) return response.bodyBytes;
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw CloudStorageUnauthorizedException('HTTP ${response.statusCode}: $hashPath');
      }
      return null;
    } on CloudStorageUnauthorizedException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getDownloadUrl(String hashPath) async => '$baseUrl$hashPath';
}
