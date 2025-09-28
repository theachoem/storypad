import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/models/backup_state.dart';
import 'package:storypad/core/models/backup_ui_state.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/repositories/backup_repository_new.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/types/backup_error.dart';
import 'package:storypad/core/types/result.dart';

/// ViewModel for backup functionality following MVVM architecture.
/// 
/// This ViewModel manages UI state for backup screens, handles user interactions,
/// converts repository results to UI states, and provides reactive streams for
/// UI updates. It also handles analytics and crash reporting.
class BackupViewModel extends ChangeNotifier {
  final BackupRepositoryNew _repository;
  
  final StreamController<BackupUIState> _stateController = 
      StreamController<BackupUIState>.broadcast();
      
  BackupUIState _currentState = BackupUIState.initial();
  StreamSubscription<BackupProgressState>? _progressSubscription;
  Timer? _autoCheckTimer;

  BackupViewModel({
    required BackupRepositoryNew repository,
  }) : _repository = repository {
    _initialize();
  }

  /// Current UI state.
  BackupUIState get currentState => _currentState;

  /// Stream of UI state changes.
  Stream<BackupUIState> get state => _stateController.stream;

  /// Whether user is signed in to Google Drive.
  bool get isSignedIn => _repository.isSignedIn;

  /// Currently signed-in Google user.
  GoogleUserObject? get currentUser => _repository.currentUser;

  /// Whether backup sync can be performed.
  bool get canSync => _currentState.canSync;

  /// Whether currently syncing.
  bool get isSyncing => _currentState.isSyncing;

  /// Whether data is synced across devices.
  bool get isSynced => _currentState.isSynced;

  void _initialize() {
    // Start with checking connection
    _updateState(BackupUIState.checkingConnection());
    
    // Listen to backup progress updates
    _progressSubscription = _repository.progressStream.listen(_onProgressUpdate);
    
    // Perform initial connection check
    recheckConnection();
    
    // Set up periodic connection checks (every 30 seconds when not syncing)
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!isSyncing) {
        recheckConnection();
      }
    });
  }

  /// Signs in to Google Drive.
  Future<void> signIn() async {
    if (isSyncing) return;

    _updateState(_currentState.copyWith(
      connectionState: BackupConnectionState.checking,
      clearError: true,
    ));

    final result = await _repository.signIn();
    
    await result.fold(
      success: (success) async {
        if (success) {
          AnalyticsService.instance.logSignInWithGoogle();
          
          // After successful sign-in, check connection and potentially sync
          await recheckAndSync();
        } else {
          _updateState(BackupUIState.authRequired(
            error: BackupError.signInFailed('Sign in was cancelled'),
          ));
        }
      },
      error: (error) async {
        _reportError(error, 'signIn');
        _updateState(BackupUIState.authRequired(error: error));
      },
    );
  }

  /// Signs out from Google Drive.
  Future<void> signOut() async {
    if (isSyncing) return;

    final result = await _repository.signOut();
    
    result.fold(
      success: (_) {
        AnalyticsService.instance.logSignOut();
        _updateState(BackupUIState.authRequired());
      },
      error: (error) {
        _reportError(error, 'signOut');
        // Even if sign out fails, update UI to reflect signed out state
        _updateState(BackupUIState.authRequired(error: error));
      },
    );
  }

  /// Requests Google Drive permissions.
  Future<void> requestScope() async {
    if (isSyncing || !isSignedIn) return;

    _updateState(_currentState.copyWith(
      connectionState: BackupConnectionState.checking,
      clearError: true,
    ));

    final result = await _repository.requestScope();
    
    await result.fold(
      success: (granted) async {
        if (granted) {
          AnalyticsService.instance.logRequestGoogleDriveScope();
          await recheckAndSync();
        } else {
          _updateState(BackupUIState.authRequired(
            error: BackupError.insufficientPermissions(),
          ));
        }
      },
      error: (error) async {
        _reportError(error, 'requestScope');
        _updateState(BackupUIState.authRequired(error: error));
      },
    );
  }

  /// Manually triggers backup sync.
  Future<void> syncBackup() async {
    if (!canSync) return;

    AnalyticsService.instance.logBackupSync();
    
    _updateState(_currentState.copyWith(
      syncState: BackupSyncState.syncing,
      clearError: true,
      clearProgress: true,
    ));

    final result = await _repository.syncBackup();
    
    result.fold(
      success: (_) {
        _updateState(_currentState.copyWith(
          syncState: BackupSyncState.success,
          lastSyncedAt: DateTime.now(),
          isSynced: true,
          clearProgress: true,
        ));

        // Auto-revert to idle state after showing success briefly
        Timer(const Duration(seconds: 2), () {
          if (_currentState.syncState == BackupSyncState.success) {
            _updateState(_currentState.copyWith(
              syncState: BackupSyncState.idle,
            ));
          }
        });
      },
      error: (error) {
        _reportError(error, 'syncBackup');
        _updateState(_currentState.copyWith(
          syncState: BackupSyncState.error,
          error: error,
          clearProgress: true,
        ));
      },
    );
  }

  /// Rechecks connection status without syncing.
  Future<void> recheckConnection() async {
    if (isSyncing) return;

    _updateState(_currentState.copyWith(
      connectionState: BackupConnectionState.checking,
      clearError: true,
    ));

    final result = await _repository.checkConnection();
    
    result.fold(
      success: (connectionState) {
        final lastDbUpdatedAt = _getLastDbUpdatedAt();
        
        switch (connectionState) {
          case BackupConnectionState.ready:
            _updateState(BackupUIState.readyToSync(
              currentUser: currentUser!,
              lastSyncedAt: _currentState.lastSyncedAt,
              lastDbUpdatedAt: lastDbUpdatedAt,
            ));
            break;
          case BackupConnectionState.offline:
            _updateState(BackupUIState.offline(
              currentUser: currentUser,
              lastSyncedAt: _currentState.lastSyncedAt,
              lastDbUpdatedAt: lastDbUpdatedAt,
            ));
            break;
          case BackupConnectionState.authRequired:
            _updateState(BackupUIState.authRequired());
            break;
          case BackupConnectionState.error:
            _updateState(BackupUIState.connectionError(
              error: BackupError.unknown('Connection check failed'),
              currentUser: currentUser,
              lastSyncedAt: _currentState.lastSyncedAt,
              lastDbUpdatedAt: lastDbUpdatedAt,
            ));
            break;
          case BackupConnectionState.checking:
            // Should not happen, but handle gracefully
            break;
        }
      },
      error: (error) {
        _reportError(error, 'recheckConnection');
        _updateState(BackupUIState.connectionError(
          error: error,
          currentUser: currentUser,
          lastSyncedAt: _currentState.lastSyncedAt,
          lastDbUpdatedAt: _getLastDbUpdatedAt(),
        ));
      },
    );
  }

  /// Rechecks connection and automatically syncs if ready.
  Future<void> recheckAndSync() async {
    await recheckConnection();
    
    // Auto-sync if ready and data is not synced
    if (canSync && !isSynced) {
      await syncBackup();
    }
  }

  /// Updates the current state and notifies listeners.
  void _updateState(BackupUIState newState) {
    _currentState = newState;
    _stateController.add(newState);
    notifyListeners();
  }

  /// Handles backup progress updates.
  void _onProgressUpdate(BackupProgressState progress) {
    if (isSyncing) {
      _updateState(_currentState.copyWith(progressState: progress));
    }
  }

  /// Gets the last database update timestamp.
  Future<DateTime?> _getLastDbUpdatedAt() async {
    try {
      return await _repository.getLastDbUpdatedAt();
    } catch (e) {
      debugPrint('Failed to get last DB updated time: $e');
      return null;
    }
  }

  /// Reports errors to analytics and crash reporting.
  void _reportError(BackupError error, String operation) {
    debugPrint('BackupViewModel.$operation error: $error');
    
    // Report to Firebase Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      StackTrace.current,
      reason: 'Backup $operation failed: ${error.code}',
      fatal: false,
    );

    // Log to analytics
    AnalyticsService.instance.logEvent('backup_error', parameters: {
      'operation': operation,
      'error_type': error.type.name,
      'error_code': error.code,
      'error_message': error.message,
    });
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _autoCheckTimer?.cancel();
    _stateController.close();
    _repository.dispose();
    super.dispose();
  }
}