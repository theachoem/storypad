import 'dart:async';

class AvoidDublicatedCallService<T> {
  bool get isRunning => _completer != null;

  Completer<T>? _completer;

  Future<T> run(Future<T> Function() callback) async {
    return _execute(callback);
  }

  Future<T> _execute(Future<T> Function() callback) {
    if (_completer != null) return _completer!.future;
    _completer = Completer<T>();

    callback()
        .then((value) {
          _completer?.complete(value);
        })
        .catchError((Object error, StackTrace stackTrace) {
          _completer?.completeError(error, stackTrace);
        })
        .whenComplete(() {
          _completer = null;
        });

    return _completer!.future;
  }
}
