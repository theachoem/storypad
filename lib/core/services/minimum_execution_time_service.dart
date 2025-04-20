class MinimumExecutionTimeService {
  static Future<T> call<T>({
    required Future<T> Function() callback,
    Duration duration = const Duration(seconds: 1),
  }) async {
    final startAt = DateTime.now();
    final result = await callback();
    final endAt = DateTime.now();

    final runDuration = endAt.difference(startAt);
    final remaining = duration - runDuration;

    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    return result;
  }
}
