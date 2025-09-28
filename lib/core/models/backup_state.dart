/// Connection status for backup functionality.
enum BackupConnectionState {
  /// Checking connection status.
  checking,
  
  /// Ready to sync with Google Drive.
  ready,
  
  /// No internet connection available.
  offline,
  
  /// Authentication required or permissions missing.
  authRequired,
  
  /// Unknown error occurred.
  error,
}

/// Synchronization status for backup operations.
enum BackupSyncState {
  /// No sync operation in progress.
  idle,
  
  /// Sync operation is in progress.
  syncing,
  
  /// Sync completed successfully.
  success,
  
  /// Sync failed with an error.
  error,
}

/// Progress information for backup sync operations.
class BackupProgressState {
  final int currentStep;
  final int totalSteps;
  final String stepName;
  final String? stepMessage;
  final double? progressPercentage;

  const BackupProgressState({
    required this.currentStep,
    required this.totalSteps,
    required this.stepName,
    this.stepMessage,
    this.progressPercentage,
  });

  /// Creates a progress state for step 1: Images upload.
  factory BackupProgressState.uploadingImages({
    String? message,
    double? progress,
  }) =>
      BackupProgressState(
        currentStep: 1,
        totalSteps: 4,
        stepName: 'Uploading Images',
        stepMessage: message,
        progressPercentage: progress,
      );

  /// Creates a progress state for step 2: Checking latest backup.
  factory BackupProgressState.checkingLatestBackup({
    String? message,
  }) =>
      BackupProgressState(
        currentStep: 2,
        totalSteps: 4,
        stepName: 'Checking Latest Backup',
        stepMessage: message,
      );

  /// Creates a progress state for step 3: Importing backup data.
  factory BackupProgressState.importingBackup({
    String? message,
    double? progress,
  }) =>
      BackupProgressState(
        currentStep: 3,
        totalSteps: 4,
        stepName: 'Importing Backup',
        stepMessage: message,
        progressPercentage: progress,
      );

  /// Creates a progress state for step 4: Uploading new backup.
  factory BackupProgressState.uploadingBackup({
    String? message,
  }) =>
      BackupProgressState(
        currentStep: 4,
        totalSteps: 4,
        stepName: 'Uploading Backup',
        stepMessage: message,
      );

  /// Returns the overall progress as a percentage (0.0 to 1.0).
  double get overallProgress {
    final stepProgress = progressPercentage ?? 0.0;
    final completedSteps = currentStep - 1;
    return (completedSteps + stepProgress) / totalSteps;
  }

  BackupProgressState copyWith({
    int? currentStep,
    int? totalSteps,
    String? stepName,
    String? stepMessage,
    double? progressPercentage,
  }) {
    return BackupProgressState(
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      stepName: stepName ?? this.stepName,
      stepMessage: stepMessage ?? this.stepMessage,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupProgressState &&
          currentStep == other.currentStep &&
          totalSteps == other.totalSteps &&
          stepName == other.stepName &&
          stepMessage == other.stepMessage &&
          progressPercentage == other.progressPercentage;

  @override
  int get hashCode => Object.hash(
        currentStep,
        totalSteps,
        stepName,
        stepMessage,
        progressPercentage,
      );

  @override
  String toString() {
    return 'BackupProgressState('
        'currentStep: $currentStep, '
        'totalSteps: $totalSteps, '
        'stepName: $stepName, '
        'stepMessage: $stepMessage, '
        'progressPercentage: $progressPercentage)';
  }
}