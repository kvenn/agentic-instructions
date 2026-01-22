import 'package:firebase_performance/firebase_performance.dart';

import '../flavors_util.dart';
import '../ping/map/countdown_latch.dart';
import 'logger.dart';

/// The public API is
/// - [PerformanceTrace] - Takes an optional firebase instance + starts the timer
/// - [setFirebase] - Sets the firebase instance if not initially provided
/// - [stop] - Stops the trace and timer
class PerformanceTrace {
  final String _traceName;
  final Stopwatch _stopwatch = Stopwatch();

  /// Only actually log if we're on prod
  final _shouldSendToFirebase = BuildFlavor.isProd;

  FirebasePerformance? _performance;
  Trace? _trace;

  /// If we were initialized with Firebase, we start / stop the trace normally
  bool _initializedWithFirebase = false;

  /// Only used in the case we weren't initialized with Firebase.
  /// It will start and send an artificial trace when both finish
  /// - the timer is done
  /// - firebase is ready
  final CountdownLatch _artificialTraceLatch = CountdownLatch(2);

  /// We only check this to ignore a noisy warning in one context.
  /// Shouldn't be necessary elsewhere.
  @Deprecated("Don't use unless for testing")
  bool get isRunning => _stopwatch.isRunning;

  PerformanceTrace({
    required String traceName,
    FirebasePerformance? performance,
  }) : _traceName = traceName {
    _performance = performance;
    _stopwatch.start();

    if (_performance != null) {
      // Firebase was ready by the time we wanted to start. Business as usual
      _initializedWithFirebase = true;
      _startTrace();
    } else {
      // Firebase isn't ready, so we rely on the latch. When it's complete,
      // we start an artificial trace for the duration of the finished timer
      _artificialTraceLatch.whenComplete.then((_) async {
        await _sendArtificialTrace();
      });
    }
  }

  void setFirebase(FirebasePerformance performance) {
    if (_performance != null) {
      logger.warning('Firebase performance already set for trace: $_traceName');
      return;
    }
    _performance = performance;
    _artificialTraceLatch.countDown();
  }

  void stop() {
    if (!_stopwatch.isRunning) {
      logger.warning('Stopwatch already stopped for trace: $_traceName');
      return;
    }

    // Stop the stopwatch regardless of the situation (so the time is correct)
    _stopwatch.stop();
    if (_initializedWithFirebase) {
      _stopTrace();
    } else {
      _artificialTraceLatch.countDown();
    }
  }

  Future<void> _sendArtificialTrace() async {
    if (_stopwatch.isRunning) {
      // This shouldn't happen (based on the latch)
      logger.warning(
        'Stopwatch still running in artificial trace. Sending trace anyway: $_traceName',
      );
    }
    _startTrace();
    await Future.delayed(
      Duration(milliseconds: _stopwatch.elapsedMilliseconds),
    );
    _stopTrace();
  }

  void _startTrace() {
    if (!_shouldSendToFirebase) {
      return;
    }

    final firebasePerformance = _performance;
    if (firebasePerformance == null) {
      logger.warning('Firebase performance not set for trace');
      return;
    }
    final trace = firebasePerformance.newTrace(_traceName);
    _trace = trace;
    trace.start();
  }

  void _stopTrace() {
    // Log regardless if we're in prod or not
    final duration = _stopwatch.elapsedMilliseconds;
    logger.debug('[Trace] $_traceName: $duration');

    if (!_shouldSendToFirebase) {
      return;
    }

    final trace = _trace;
    if (trace == null) {
      logger.warning('Trace not started for trace: $_traceName');
      return;
    }
    // We send this for legacy reasons (so we can compare to historical
    // values)
    trace.setMetric('totalDuration', duration);
    trace.stop();
  }
}
