enum SyncStep {
  uploadAssets,
  checkLatest,
  importChanges,
  uploadBackup;

  int get stepNumber => index + 1;
}
