import 'dart:math';

import 'package:retry/retry.dart';

/// Returns exponential back off in ms
/// After 8 retries the delay will fallback to 30s
int retryDelayMs(int retries, int maxRetryWaitMs) {
  const int multiplier = 100;
  const int exponent = 2;
  return min(multiplier * pow(exponent, retries).round(), maxRetryWaitMs);
}

/// Delay after [attempt] number of attempts.
///
/// This is computed as `pow(2, attempt) * delayFactor`, then is multiplied by
/// between `-randomizationFactor` and `randomizationFactor` at random.
Duration delay(
  int attempt, {
  Duration delayFactor = const Duration(milliseconds: 200),
  double randomizationFactor = 0.25,
  Duration maxDelay = const Duration(seconds: 30),
}) {
  return RetryOptions(
    delayFactor: delayFactor,
    randomizationFactor: randomizationFactor,
    maxDelay: maxDelay,
  ).delay(attempt);
}
