// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'package:crypto/crypto.dart';

class EmailHasherService {
  final String secretKey;

  EmailHasherService({
    required this.secretKey,
  });

  String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  String hmacEmail(String email) {
    final normalized = normalizeEmail(email);
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(normalized);

    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);

    return digest.toString();
  }

  /// Check if a string looks like a valid legacy email hash.
  /// Legacy hashes are SHA-256 HMAC outputs: exactly 64 lowercase hex characters.
  static bool isValidEmailHash(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.length == 64 && RegExp(r'^[a-f0-9]{64}$').hasMatch(value);
  }
}
