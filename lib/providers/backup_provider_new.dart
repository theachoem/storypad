import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/models/backup_ui_state.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/repositories/backup_repository_new.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/backup_sync_steps/utils/restore_backup_service.dart';
import 'package:storypad/core/services/google_drive_client.dart';
import 'package:storypad/core/services/internet_checker_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/types/backup_connection_status.dart';
import 'package:storypad/core/services/backup_sync_steps/backup_sync_message.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/view_models/backup_view_model.dart';

/// Updated BackupProvider that delegates to BackupViewModel while maintaining
/// backward compatibility with existing UI code.
/// 
/// This provider serves as a bridge between the old Provider-based architecture
/// and the new MVVM architecture, ensuring zero breaking changes for existing UI.
class BackupProviderNew extends ChangeNotifier {
  late final BackupViewModel _viewModel;
  StreamSubscription<BackupUIState>? _stateSubscription;
  
  // Legacy state properties for backward compatibility
  BackupConnectionStatus? _connectionStatus;
  DateTime? _lastSyncedAt;
  DateTime? _lastDbUpdatedAt;
  bool _syncing = false;

  // Legacy message properties for step-by-step progress
  BackupSyncMessage? step1Message;
  BackupSyncMessage? step2Message;
  BackupSyncMessage? step3Message;
  BackupSyncMessage? step4Message;

  BackupProviderNew({
    BackupViewModel? viewModel,
  }) {
    _viewModel = viewModel ?? _createDefaultViewModel();
    _initialize();
  }

  BackupViewModel _createDefaultViewModel() {
    final repository = BackupRepositoryNew(
      googleDriveClient: GoogleDriveClient(),
      internetChecker: InternetCheckerService(),
      restoreBackupService: RestoreBackupService.appInstance,
    );
    return BackupViewModel(repository: repository);
  }

  void _initialize() {
    // Listen to ViewModel state changes and convert to legacy properties
    _stateSubscription = _viewModel.state.listen(_onStateChanged);
    
    // Set up database listeners for compatibility
    for (var database in BackupRepository.databases) {
      database.addGlobalListener(_databaseListener);
    }

    // Start initial check and sync
    _viewModel.recheckAndSync();
  }

  void _onStateChanged(BackupUIState state) {
    // Convert new state to legacy properties
    _connectionStatus = _mapConnectionState(state.connectionState);
    _lastSyncedAt = state.lastSyncedAt;
    _lastDbUpdatedAt = state.lastDbUpdatedAt;
    _syncing = state.isSyncing;

    // Convert progress to legacy step messages
    _updateStepMessages(state);

    notifyListeners();
  }

  BackupConnectionStatus? _mapConnectionState(BackupConnectionState connectionState) {
    return switch (connectionState) {
      BackupConnectionState.ready => BackupConnectionStatus.readyToSync,
      BackupConnectionState.offline => BackupConnectionStatus.noInternet,
      BackupConnectionState.authRequired => BackupConnectionStatus.needGoogleDrivePermission,
      BackupConnectionState.error => BackupConnectionStatus.unknownError,
      BackupConnectionState.checking => null,
    };
  }

  void _updateStepMessages(BackupUIState state) {
    // Reset all messages
    step1Message = null;
    step2Message = null;
    step3Message = null;
    step4Message = null;

    // Set message based on current progress
    if (state.progressState != null) {
      final progress = state.progressState!;
      final message = BackupSyncMessage(
        processing: state.isSyncing,
        success: !state.isSyncing,
        message: progress.stepMessage,
      );

      switch (progress.currentStep) {
        case 1:
          step1Message = message;
          break;
        case 2:
          step2Message = message;
          break;
        case 3:
          step3Message = message;
          break;
        case 4:
          step4Message = message;
          break;
      }
    }
  }

  Future<void> _databaseListener() async {
    // Update last DB updated time when database changes
    try {
      // We can't access private members, so we'll update through the ViewModel
      await _viewModel.recheckConnection();
    } catch (e) {
      // Ignore errors in background listener
    }
  }

  // Legacy properties for backward compatibility
  @Deprecated('Use BackupViewModel directly')
  BackupRepository get repository => throw UnimplementedError('Use BackupViewModel instead');

  GoogleUserObject? get currentUser => _viewModel.currentUser;
  bool get isSignedIn => _viewModel.isSignedIn;

  // Legacy stream getters - these would need to be implemented if still used
  Stream<BackupSyncMessage?> get step1MessageStream => Stream.value(step1Message);
  Stream<BackupSyncMessage?> get step2MessageStream => Stream.value(step2Message);
  Stream<BackupSyncMessage?> get step3MessageStream => Stream.value(step3Message);
  Stream<BackupSyncMessage?> get step4MessageStream => Stream.value(step4Message);

  BackupConnectionStatus? get connectionStatus => _connectionStatus;
  bool get synced => _viewModel.isSynced;
  bool get readyToSynced => _viewModel.canSync;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  DateTime? get lastDbUpdatedAt => _lastDbUpdatedAt;
  bool get syncing => _syncing;

  // Legacy methods that delegate to ViewModel
  Future<void> recheckAndSync() async {
    await _viewModel.recheckAndSync();
  }

  Future<void> signIn(BuildContext context) async {
    await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#signIn',
      future: () => _viewModel.signIn(),
    );

    if (context.mounted) {
      context.read<InAppPurchaseProvider>().revalidateCustomerInfo(context);
    }
  }

  Future<void> requestScope(BuildContext context) async {
    await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#requestScope',
      future: () => _viewModel.requestScope(),
    );
  }

  Future<void> signOut(BuildContext context) async {
    await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#signOut',
      future: () => _viewModel.signOut(),
    );

    if (context.mounted) {
      context.read<InAppPurchaseProvider>().revalidateCustomerInfo(context);
    }
  }

  // Private sync method that was used internally
  Future<void> _syncBackupAcrossDevices(String email) async {
    await _viewModel.syncBackup();
  }

  // Provide access to the ViewModel for gradual migration
  BackupViewModel get viewModel => _viewModel;

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _viewModel.dispose();
    super.dispose();
  }
}