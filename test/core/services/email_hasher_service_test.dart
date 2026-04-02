import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/email_hasher_service.dart';

void main() {
  group('EmailHasherService', () {
    late EmailHasherService hasher;

    setUp(() {
      hasher = EmailHasherService(secretKey: 'my_secret_key');
    });

    test('normalizeEmail trims and lowercases', () {
      expect(
        hasher.normalizeEmail('  Foo.Bar@Example.COM  '),
        equals('foo.bar@example.com'),
      );
    });

    test('hmacEmail returns deterministic hash for same email', () {
      const email = 'User@Example.com';
      final hash1 = hasher.hmacEmail(email);
      final hash2 = hasher.hmacEmail(' user@example.COM  '); // same email, different format

      // Should be equal after normalization
      expect(hash1, equals(hash2));

      // Hash should be 64 hex characters (SHA-256 output)
      expect(hash1.length, equals(64));
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(hash1), isTrue);
    });

    test('hmacEmail different emails produce different hashes', () {
      final hash1 = hasher.hmacEmail('user1@example.com');
      final hash2 = hasher.hmacEmail('user2@example.com');

      expect(hash1, isNot(equals(hash2)));
    });

    test('hmacEmail with different secret keys produces different hashes', () {
      final otherHasher = EmailHasherService(secretKey: 'another_secret');

      const email = 'user@example.com';
      final hash1 = hasher.hmacEmail(email);
      final hash2 = otherHasher.hmacEmail(email);

      expect(hash1, isNot(equals(hash2)));
    });

    test('isValidEmailHash accepts valid 64-char hex hash', () {
      const validHash = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
      expect(EmailHasherService.isValidEmailHash(validHash), isTrue);
    });

    test('isValidEmailHash rejects uppercase hex', () {
      // Should only accept lowercase to match SHA256 digest.toString() output
      const invalidHash = '1234567890ABCDEF1234567890abcdef1234567890abcdef1234567890abcdef';
      expect(EmailHasherService.isValidEmailHash(invalidHash), isFalse);
    });

    test('isValidEmailHash rejects non-hex characters', () {
      const invalidHash = 'z234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
      expect(EmailHasherService.isValidEmailHash(invalidHash), isFalse);
    });

    test('isValidEmailHash rejects wrong length', () {
      const tooShort = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcde';
      const tooLong = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef00';

      expect(EmailHasherService.isValidEmailHash(tooShort), isFalse);
      expect(EmailHasherService.isValidEmailHash(tooLong), isFalse);
    });

    test('isValidEmailHash rejects null or empty', () {
      expect(EmailHasherService.isValidEmailHash(null), isFalse);
      expect(EmailHasherService.isValidEmailHash(''), isFalse);
    });

    test('isValidEmailHash validates real hmacEmail output', () {
      final realHash = hasher.hmacEmail('test@example.com');
      expect(EmailHasherService.isValidEmailHash(realHash), isTrue);
    });

    test('isValidEmailHash with RevenueCat anonymous ID format', () {
      // RevenueCat anonymous IDs start with '$RCAnonymousID:' and are much longer
      const rcAnonId = '\$RCAnonymousID:fa0feebeb1d34d2fb9e1e5fbd1903be7';
      expect(EmailHasherService.isValidEmailHash(rcAnonId), isFalse);
    });
  });
}
