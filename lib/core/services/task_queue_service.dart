import 'dart:async';

class TaskQueueService {
  final List<(Future<void> Function(), void Function())> _tasksQueue = [];
  Future? _currentTask;

  Future<void> addTask(Future<void> Function() task) {
    Completer<void> completer = Completer();
    _tasksQueue.add((task, () => completer.complete()));

    if (_currentTask == null) {
      _processQueue();
    }

    return completer.future;
  }

  void _processQueue() {
    if (_tasksQueue.isEmpty) {
      _currentTask = null;
      return;
    }

    final nextTask = _tasksQueue.removeAt(0);
    _currentTask = nextTask.$1().whenComplete(() {
      nextTask.$2();
      _processQueue();
    });
  }
}
