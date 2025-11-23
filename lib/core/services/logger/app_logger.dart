import 'package:flutter/foundation.dart';

enum AppLogLevel { debug, info, warning, error, critical }

class AppLogger {
  AppLogger._();
  static final AppLogger _instance = AppLogger._();

  final List<String> _logBuffer = [];
  static const int _maxLogs = 50;

  static List<String> get logs => List.unmodifiable(_instance._logBuffer);

  void log(
    String message, {
    AppLogLevel level = AppLogLevel.info,
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase();
    final logTag = tag != null ? '[$tag]' : '';
    final errorStr = error != null ? ' | Error: $error' : '';
    final stackStr = stackTrace != null ? ' | StackTrace: $stackTrace' : '';
    final formattedMessage = '$timestamp | $levelStr $logTag: $message$errorStr$stackStr';

    if (_logBuffer.length >= _maxLogs) _logBuffer.removeAt(0);
    _logBuffer.add(formattedMessage);

    if (kDebugMode) print(formattedMessage);
  }

  static void d(String message, {String? tag}) => _instance.log(message, level: AppLogLevel.debug, tag: tag);
  static void debug(String message, {String? tag}) => _instance.log(message, level: AppLogLevel.debug, tag: tag);
  static void info(String message, {String? tag}) => _instance.log(message, level: AppLogLevel.info, tag: tag);
  static void warning(String message, {String? tag}) => _instance.log(message, level: AppLogLevel.warning, tag: tag);
  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) =>
      _instance.log(message, level: AppLogLevel.error, tag: tag, error: error, stackTrace: stackTrace);
  static void critical(String message, {String? tag, dynamic error, StackTrace? stackTrace}) =>
      _instance.log(message, level: AppLogLevel.critical, tag: tag, error: error, stackTrace: stackTrace);
}
