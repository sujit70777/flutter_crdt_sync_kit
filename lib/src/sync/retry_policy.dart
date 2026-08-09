import 'dart:math';

/// Exponential backoff with jitter for [SyncEngine] retry scheduling.
class RetryPolicy {
  final Duration base;
  final double factor;
  final Duration max;
  final Duration jitter;
  final Random _random;

  RetryPolicy({
    this.base = const Duration(seconds: 1),
    this.factor = 2.0,
    this.max = const Duration(minutes: 2),
    this.jitter = const Duration(milliseconds: 500),
    Random? random,
  }) : _random = random ?? Random();

  /// The delay to wait before retrying, given that [attempt] consecutive
  /// failures have already occurred (`attempt` starts at 1 for the first
  /// retry after the first failure).
  Duration delayFor(int attempt) {
    final exponential = base.inMilliseconds * pow(factor, attempt - 1);
    final capped = min(exponential, max.inMilliseconds.toDouble());
    final jitterMillis = jitter.inMilliseconds == 0
        ? 0
        : _random.nextInt(jitter.inMilliseconds);
    return Duration(milliseconds: capped.round() + jitterMillis);
  }
}
