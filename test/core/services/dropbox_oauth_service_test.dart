import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/backups/dropbox_oauth_service.dart';

void main() {
  // Pure over its input (no network/browser), so it's testable directly —
  // the one thing standing between a fresh sign-in and Dropbox rejecting the
  // whole OAuth flow with an opaque "bad request" if it's ever wrong.
  group('DropboxOAuthService.codeChallengeFor', () {
    test('matches the official RFC 7636 Appendix B.1 test vector', () {
      // https://datatracker.ietf.org/doc/html/rfc7636#appendix-B
      const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
      const expectedChallenge = 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM';

      expect(DropboxOAuthService.codeChallengeFor(verifier), expectedChallenge);
    });

    test('is deterministic for the same verifier', () {
      const verifier = 'some-random-code-verifier-value-1234567890';
      expect(
        DropboxOAuthService.codeChallengeFor(verifier),
        DropboxOAuthService.codeChallengeFor(verifier),
      );
    });

    test('differs for different verifiers', () {
      expect(
        DropboxOAuthService.codeChallengeFor('verifier-a'),
        isNot(DropboxOAuthService.codeChallengeFor('verifier-b')),
      );
    });

    test('never contains base64 padding or non-URL-safe characters', () {
      final challenge = DropboxOAuthService.codeChallengeFor('any-verifier-value');
      expect(challenge, isNot(contains('=')));
      expect(challenge, isNot(contains('+')));
      expect(challenge, isNot(contains('/')));
    });
  });
}
