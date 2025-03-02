import 'dart:async';

class AvoidDublicatedCallService<T> {
  Completer<T>? _completer;

  Future<T> run(Future<T> Function() callback) async {
    final result = await _execute(callback);
    _completer = null;
    return result;
  }

  Future<T> _execute(Future<T> Function() callback) {
    if (_completer != null) return _completer!.future;
    _completer = Completer<T>();

    callback().then((value) {
      return _completer?.complete(value);
    });

    return _completer!.future;
  }
}
