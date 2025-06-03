import 'dart:async';
import 'dart:convert';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/services/backup/google_user_storage.dart';

// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

enum GoogleSignInRenewResponse {
  success,
  failedUnknown,
  noInternet,
  signInRequired;

  bool get isSuccess => this == success;
  bool get isFailedUnknown => this == failedUnknown;
  bool get isNoInternet => this == noInternet;
  bool get isSignInRequired => this == signInRequired;
}

class GoogleSignInService {
  final GoogleSignIn googleSignIn = GoogleSignIn.standard(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  GoogleUserObject? currentUser;
  bool get isSignedIn => currentUser != null;

  Future<GoogleSignInRenewResponse> renewToken() async {
    currentUser = await GoogleUserStorage().readObject();
    if (currentUser == null || !await googleSignIn.isSignedIn()) return GoogleSignInRenewResponse.signInRequired;

    try {
      final account = await googleSignIn.signInSilently(
        reAuthenticate: true,
        suppressErrors: false,
      );

      if (account != null) {
        currentUser = GoogleUserObject(
          id: account.id,
          email: account.email,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
          accessToken: await account.authentication.then((e) => e.accessToken),
          refreshedAt: DateTime.now(),
        );

        await GoogleUserStorage().writeObject(currentUser!);
        return GoogleSignInRenewResponse.success;
      }

      return GoogleSignInRenewResponse.failedUnknown;
    } on PlatformException catch (error) {
      switch (error.code) {
        case GoogleSignIn.kSignInRequiredError:
          return GoogleSignInRenewResponse.signInRequired;
        case GoogleSignIn.kNetworkError:
          return GoogleSignInRenewResponse.noInternet;
        case GoogleSignIn.kSignInFailedError:
        default:
          return GoogleSignInRenewResponse.failedUnknown;
      }
    } catch (error) {
      FirebaseCrashlytics.instance.recordError("$runtimeType#renewToken failed: $error", null);
      return GoogleSignInRenewResponse.failedUnknown;
    }
  }

  Future<bool> signIn() async {
    final GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account == null) return false;

    currentUser = GoogleUserObject(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      accessToken: await account.authentication.then((e) => e.accessToken),
      refreshedAt: DateTime.now(),
    );

    await GoogleUserStorage().writeObject(currentUser!);
    return true;
  }

  Future<void> signOut() async {
    await googleSignIn.disconnect();
    await GoogleUserStorage().remove();
  }

  Future<bool> requestScope() async {
    if (isSignedIn) return false;
    if (await _canAccessRequestedScope()) return true;

    await googleSignIn.requestScopes(googleSignIn.scopes);
    bool success = await _canAccessRequestedScope();

    // after request, access token might be renew.
    final account = googleSignIn.currentUser;
    if (success && account != null) {
      await GoogleUserStorage().writeObject(
        GoogleUserObject(
          id: account.id,
          email: account.email,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
          accessToken: await account.authentication.then((e) => e.accessToken),
          refreshedAt: DateTime.now(),
        ),
      );
    }

    return success;
  }

  Future<bool> _canAccessRequestedScope() async {
    final user = googleSignIn.currentUser;
    if (user == null) return false;

    final accessToken = (await user.authentication).accessToken;
    if (accessToken == null) return false;

    String? accessedScopes;
    try {
      http.Response response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v3/tokeninfo?access_token=$accessToken'),
      );
      if (response.statusCode != 200) return false;
      final Map<String, dynamic> tokenInfo = json.decode(response.body);
      accessedScopes = tokenInfo['scope'] as String?;
    } catch (e) {
      return false;
    }

    return googleSignIn.scopes.every((requestedScope) {
      return accessedScopes?.contains(requestedScope) ?? false;
    });
  }
}
