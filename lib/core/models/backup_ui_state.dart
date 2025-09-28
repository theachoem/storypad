import 'package:storypad/core/models/backup_state.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/types/backup_error.dart';

/// Immutable UI state for backup screens and widgets.
/// 
/// This class encapsulates all the state needed by backup-related UI components,
/// providing a single source of truth for the backup system's state.
class BackupUIState {
  /// Current connection status.
  final BackupConnectionState connectionState;
  
  /// Current sync status.
  final BackupSyncState syncState;
  
  /// Progress information for current sync operation.
  final BackupProgressState? progressState;
  
  /// Current error, if any.
  final BackupError? error;
  
  /// Currently signed-in Google user.
  final GoogleUserObject? currentUser;
  
  /// Last successful sync timestamp.
  final DateTime? lastSyncedAt;
  
  /// Last database update timestamp.
  final DateTime? lastDbUpdatedAt;
  
  /// Whether user data is synced across devices.
  final bool isSynced;

  const BackupUIState({
    required this.connectionState,
    required this.syncState,
    this.progressState,
    this.error,
    this.currentUser,
    this.lastSyncedAt,
    this.lastDbUpdatedAt,
    required this.isSynced,
  });

  /// Creates an initial state for the backup system.
  factory BackupUIState.initial() => const BackupUIState(
        connectionState: BackupConnectionState.checking,
        syncState: BackupSyncState.idle,
        isSynced: false,
      );

  /// Creates a state indicating connection check in progress.
  factory BackupUIState.checkingConnection() => const BackupUIState(
        connectionState: BackupConnectionState.checking,
        syncState: BackupSyncState.idle,
        isSynced: false,
      );

  /// Creates a state indicating ready to sync.
  factory BackupUIState.readyToSync({
    required GoogleUserObject currentUser,
    DateTime? lastSyncedAt,
    DateTime? lastDbUpdatedAt,
  }) =>
      BackupUIState(
        connectionState: BackupConnectionState.ready,
        syncState: BackupSyncState.idle,
        currentUser: currentUser,
        lastSyncedAt: lastSyncedAt,
        lastDbUpdatedAt: lastDbUpdatedAt,
        isSynced: lastSyncedAt != null && lastSyncedAt == lastDbUpdatedAt,
      );

  /// Creates a state indicating sync in progress.
  factory BackupUIState.syncing({
    required GoogleUserObject currentUser,
    required BackupProgressState progressState,
    DateTime? lastSyncedAt,
    DateTime? lastDbUpdatedAt,
  }) =>
      BackupUIState(
        connectionState: BackupConnectionState.ready,
        syncState: BackupSyncState.syncing,
        progressState: progressState,
        currentUser: currentUser,
        lastSyncedAt: lastSyncedAt,
        lastDbUpdatedAt: lastDbUpdatedAt,
        isSynced: false,
      );

  /// Creates a state indicating sync completed successfully.
  factory BackupUIState.syncSuccess({
    required GoogleUserObject currentUser,
    required DateTime lastSyncedAt,
    required DateTime lastDbUpdatedAt,
  }) =>
      BackupUIState(
        connectionState: BackupConnectionState.ready,
        syncState: BackupSyncState.success,
        currentUser: currentUser,
        lastSyncedAt: lastSyncedAt,
        lastDbUpdatedAt: lastDbUpdatedAt,
        isSynced: true,
      );

  /// Creates a state indicating sync failed with an error.
  factory BackupUIState.syncError({
    required BackupError error,
    GoogleUserObject? currentUser,
    DateTime? lastSyncedAt,
    DateTime? lastDbUpdatedAt,
  }) =>
      BackupUIState(
        connectionState: BackupConnectionState.ready,
        syncState: BackupSyncState.error,
        error: error,
        currentUser: currentUser,
        lastSyncedAt: lastSyncedAt,
        lastDbUpdatedAt: lastDbUpdatedAt,
        isSynced: lastSyncedAt != null && lastSyncedAt == lastDbUpdatedAt,
      );

  /// Creates a state indicating offline.
  factory BackupUIState.offline({
    GoogleUserObject? currentUser,
    DateTime? lastSyncedAt,
    DateTime? lastDbUpdatedAt,
  }) =>
      BackupUIState(
        connectionState: BackupConnectionState.offline,
        syncState: BackupSyncState.idle,
        currentUser: currentUser,
        lastSyncedAt: lastSyncedAt,
        lastDbUpdatedAt: lastDbUpdatedAt,
        isSynced: lastSyncedAt != null && lastSyncedAt == lastDbUpdatedAt,
      );

  /// Creates a state indicating authentication required.
  factory BackupUIState.authRequired({
    BackupError? error,
  }) =>
      BackupUIState(
        connectionState: BackupConnectionState.authRequired,
        syncState: BackupSyncState.idle,
        error: error,
        isSynced: false,
      );

  /// Creates a state indicating a connection error.
  factory BackupUIState.connectionError({
    required BackupError error,
    GoogleUserObject? currentUser,
    DateTime? lastSyncedAt,
    DateTime? lastDbUpdatedAt,
  }) =>
      BackupUIState(
        connectionState: BackupConnectionState.error,
        syncState: BackupSyncState.idle,
        error: error,
        currentUser: currentUser,
        lastSyncedAt: lastSyncedAt,
        lastDbUpdatedAt: lastDbUpdatedAt,
        isSynced: lastSyncedAt != null && lastSyncedAt == lastDbUpdatedAt,
      );

  /// Returns true if user is signed in to Google Drive.
  bool get isSignedIn => currentUser != null;

  /// Returns true if ready to perform sync operations.
  bool get canSync =>
      connectionState == BackupConnectionState.ready &&
      syncState != BackupSyncState.syncing &&
      isSignedIn;

  /// Returns true if currently syncing.
  bool get isSyncing => syncState == BackupSyncState.syncing;

  /// Returns true if last sync was successful.
  bool get lastSyncSuccessful => syncState == BackupSyncState.success;

  /// Returns true if there's an active error.
  bool get hasError => error != null;

  /// Returns user-friendly status message.
  String get statusMessage {
    if (hasError) {
      return error!.userFriendlyMessage;
    }

    return switch ((connectionState, syncState)) {
      (BackupConnectionState.checking, _) => 'Checking connection...',
      (BackupConnectionState.offline, _) => 'No internet connection',
      (BackupConnectionState.authRequired, _) => 'Sign in required',
      (BackupConnectionState.error, _) => 'Connection error',
      (BackupConnectionState.ready, BackupSyncState.idle) => isSynced
          ? 'All data synced'
          : 'Ready to sync',
      (BackupConnectionState.ready, BackupSyncState.syncing) =>
        progressState?.stepMessage ?? 'Syncing...',
      (BackupConnectionState.ready, BackupSyncState.success) =>
        'Sync completed successfully',
      (BackupConnectionState.ready, BackupSyncState.error) =>
        'Sync failed',
    };
  }

  /// Creates a copy of this state with updated values.
  BackupUIState copyWith({
    BackupConnectionState? connectionState,
    BackupSyncState? syncState,
    BackupProgressState? progressState,
    BackupError? error,
    GoogleUserObject? currentUser,
    DateTime? lastSyncedAt,
    DateTime? lastDbUpdatedAt,
    bool? isSynced,
    bool clearError = false,
    bool clearProgress = false,
  }) {
    return BackupUIState(
      connectionState: connectionState ?? this.connectionState,
      syncState: syncState ?? this.syncState,
      progressState: clearProgress ? null : (progressState ?? this.progressState),
      error: clearError ? null : (error ?? this.error),
      currentUser: currentUser ?? this.currentUser,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastDbUpdatedAt: lastDbUpdatedAt ?? this.lastDbUpdatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupUIState &&
          connectionState == other.connectionState &&
          syncState == other.syncState &&
          progressState == other.progressState &&
          error == other.error &&
          currentUser == other.currentUser &&
          lastSyncedAt == other.lastSyncedAt &&
          lastDbUpdatedAt == other.lastDbUpdatedAt &&
          isSynced == other.isSynced;

  @override
  int get hashCode => Object.hash(
        connectionState,
        syncState,
        progressState,
        error,
        currentUser,
        lastSyncedAt,
        lastDbUpdatedAt,
        isSynced,
      );

  @override
  String toString() {
    return 'BackupUIState('
        'connectionState: $connectionState, '
        'syncState: $syncState, '
        'progressState: $progressState, '
        'error: $error, '
        'currentUser: ${currentUser?.email}, '
        'lastSyncedAt: $lastSyncedAt, '
        'lastDbUpdatedAt: $lastDbUpdatedAt, '
        'isSynced: $isSynced)';
  }
}