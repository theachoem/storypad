import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:storypad/core/constants/app_constants.dart';

/// Result of a completed OAuth2 code exchange (initial sign-in) or refresh.
class DropboxTokenResponse {
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;

  DropboxTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });
}

/// Runs Dropbox's OAuth2 **PKCE flow for public/native clients** — no client
/// secret anywhere in this file, by design. [kDropboxAppKey] (the "App key")
/// is not a secret; both the authorization-code exchange and the
/// refresh-token exchange are plain unauthenticated-client requests per
/// Dropbox's own docs, which is what lets this whole feature run fully
/// client-side with no backend. See docs/app/architecture/backup-sync.md.
class DropboxOAuthService {
  static const _authorizeUrl = 'https://www.dropbox.com/oauth2/authorize';
  static const _tokenUrl = 'https://api.dropboxapi.com/oauth2/token';

  /// Fixed loopback port for the desktop (Linux) flow — flutter_web_auth_2's
  /// `useWebview: false` path requires the callback to literally be
  /// `http://localhost:{port}`, and Dropbox does exact redirect-URI matching,
  /// so this must match whatever port is registered in the Dropbox app
  /// console for the loopback redirect URI (see plans/2026-09-06-dropbox-backup-provider).
  static const _linuxLoopbackPort = 8763;

  /// Plain custom-scheme deep link for iOS/Android/macOS — deliberately not a
  /// hosted HTTPS redirect (e.g. a `dropbox.storypad.me` Universal Link
  /// endpoint): that pattern exists mainly to defend against a malicious app
  /// intercepting the authorization code via the same custom scheme, which is
  /// exactly what PKCE (the `code_challenge`/`code_verifier` pair below)
  /// already defeats — an intercepted `code` is useless without the
  /// `code_verifier`, which never leaves this process. So a hosted redirect
  /// would add real infrastructure (Cloudflare Worker, DNS, and — to actually
  /// get the security property back — Associated Domains/App Links
  /// entitlements and `assetlinks.json`/AASA files per flavor) for no benefit
  /// PKCE doesn't already provide.
  ///
  /// One literal scheme per flavor, matching the `dropboxCallbackScheme`
  /// Gradle manifest placeholder in `android/app/build.gradle.kts`'s
  /// `productFlavors` block and whatever's registered as the redirect URI in
  /// the Dropbox app console. iOS/macOS need no matching Info.plist entry —
  /// `ASWebAuthenticationSession` ties the callback to the session that
  /// opened it, not to a system-wide URL-scheme registration.
  String get _callbackUrlScheme {
    if (kStoryPad) return 'storypad';
    if (kCommunity) return 'spookycommunity';
    if (kSpooky) return 'spooky';
    throw StateError('Unknown flavor — no Dropbox OAuth callback scheme registered for this package');
  }

  String get _redirectUri {
    if (!kIsWeb && io.Platform.isLinux) return 'http://localhost:$_linuxLoopbackPort/callback';
    return '$_callbackUrlScheme://oauth/dropbox';
  }

  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _codeChallengeFor(String codeVerifier) {
    final digest = sha256.convert(utf8.encode(codeVerifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// Runs the full interactive flow: opens the system browser / OS auth
  /// session, waits for the redirect, then exchanges the code for tokens.
  /// Throws on cancellation or any HTTP failure — callers classify via the
  /// same [DropboxCloudService] exception mapping used for every other call.
  Future<DropboxTokenResponse> authenticate() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _codeChallengeFor(codeVerifier);
    final redirectUri = _redirectUri;
    final useWebview = !(!kIsWeb && io.Platform.isLinux);

    final authorizeUri = Uri.parse(_authorizeUrl).replace(
      queryParameters: {
        'client_id': kDropboxAppKey,
        'response_type': 'code',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        // Requests a long-lived refresh_token alongside the short-lived
        // access_token — without this Dropbox only issues an access_token,
        // forcing an interactive re-consent every few hours.
        'token_access_type': 'offline',
        'redirect_uri': redirectUri,
      },
    );

    final result = await FlutterWebAuth2.authenticate(
      url: authorizeUri.toString(),
      callbackUrlScheme: Uri.parse(redirectUri).scheme,
      options: FlutterWebAuth2Options(useWebview: useWebview),
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) {
      throw const FormatException('Dropbox redirect did not include an authorization code');
    }

    return _exchangeCodeForTokens(code: code, codeVerifier: codeVerifier, redirectUri: redirectUri);
  }

  Future<DropboxTokenResponse> _exchangeCodeForTokens({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    final response = await http.post(
      Uri.parse(_tokenUrl),
      body: {
        'code': code,
        'grant_type': 'authorization_code',
        'client_id': kDropboxAppKey,
        'code_verifier': codeVerifier,
        'redirect_uri': redirectUri,
      },
    );

    return _parseTokenResponse(response);
  }

  /// Silent refresh — no browser, no user interaction. Returns null (rather
  /// than throwing) only when Dropbox confirms the refresh token itself is
  /// dead (`invalid_grant`), so callers can distinguish "needs a fresh
  /// interactive sign-in" from a transient network/server failure.
  Future<DropboxTokenResponse?> refresh({required String refreshToken}) async {
    final response = await http.post(
      Uri.parse(_tokenUrl),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': kDropboxAppKey,
      },
    );

    if (response.statusCode == 400) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['error'] == 'invalid_grant') return null;
    }

    return _parseTokenResponse(response, fallbackRefreshToken: refreshToken);
  }

  DropboxTokenResponse _parseTokenResponse(http.Response response, {String? fallbackRefreshToken}) {
    if (response.statusCode != 200) {
      throw http.ClientException('Dropbox token request failed (${response.statusCode}): ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final expiresInSeconds = body['expires_in'] as int;

    return DropboxTokenResponse(
      accessToken: body['access_token'] as String,
      // A refresh response only includes refresh_token if Dropbox happens to
      // rotate it — otherwise the original one is still valid and must be
      // kept, or the next refresh would have nothing to refresh with.
      refreshToken: body['refresh_token'] as String? ?? fallbackRefreshToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresInSeconds)),
    );
  }
}
