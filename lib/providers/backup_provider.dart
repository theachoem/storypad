import 'package:flutter/material.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/types/backup_connection_status.dart';
import 'package:storypad/core/services/backup_sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/messenger_service.dart';

class BackupProvider extends ChangeNotifier {
  BackupRepository get backupRepository => BackupRepository.appInstance;

  GoogleUserObject? get currentUser => backupRepository.currentUser;
  bool get isSignedIn => backupRepository.isSignedIn;

  BackupConnectionStatus? _connectionStatus;
  BackupConnectionStatus? get connectionStatus => _connectionStatus;

  Stream<BackupSyncMessage?> get step1MessageStream => backupRepository.step1.message;
  Stream<BackupSyncMessage?> get step2MessageStream => backupRepository.step2.message;
  Stream<BackupSyncMessage?> get step3MessageStream => backupRepository.step3.message;
  Stream<BackupSyncMessage?> get step4MessageStream => backupRepository.step4.message;

  BackupSyncMessage? step1Message;
  BackupSyncMessage? step2Message;
  BackupSyncMessage? step3Message;
  BackupSyncMessage? step4Message;

  bool get syncing => [
        step1Message?.processing,
        step2Message?.processing,
        step3Message?.processing,
        step4Message?.processing,
      ].any((processing) => processing == true);

  BackupProvider() {
    load();

    step1MessageStream.listen((message) {
      step1Message = message;
      notifyListeners();
    });

    step2MessageStream.listen((message) {
      step2Message = message;
      notifyListeners();
    });

    step3MessageStream.listen((message) {
      step3Message = message;
      notifyListeners();
    });

    step4MessageStream.listen((message) {
      step4Message = message;
      notifyListeners();
    });
  }

  Future<void> load() async {
    _connectionStatus = await backupRepository.checkConnection();
    notifyListeners();
    if (_connectionStatus != BackupConnectionStatus.readyToSync || currentUser?.email == null) return;

    await backupRepository.sync(currentUser!.email);
  }

  Future<void> recheckAndSync() async {
    if (_connectionStatus != BackupConnectionStatus.readyToSync) {
      await load();
    }

    if (_connectionStatus == BackupConnectionStatus.readyToSync) {
      await backupRepository.sync(currentUser!.email);
    }
  }

  Future<void> signIn(BuildContext context) async {
    await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#signIn',
      future: () => backupRepository.signIn(),
    );
    notifyListeners();
  }

  Future<void> signOut(BuildContext context) async {
    await backupRepository.signOut();
    notifyListeners();
  }
}
