import 'package:firebase_performance/firebase_performance.dart';

import '../logging/performance_trace.dart';

class PerformanceTracerCollector {
  FirebasePerformance? _performance;
  // Collect traces before firebase is initialized
  final List<PerformanceTrace> setupTracers = [];

  PerformanceTrace addTracer(String traceName) {
    // Set the (potentially null) performance on the trace
    final newTracer = PerformanceTrace(
      traceName: traceName,
      performance: _performance,
    );
    setupTracers.add(newTracer);
    return newTracer;
  }

  /// This should be called exactly once (once firebase is initialized)
  /// It'll set the the Firebase on instance on all traces created before it
  /// was initialized
  void setTraces(final FirebasePerformance performance) {
    _performance = performance;
    for (final trace in setupTracers) {
      trace.setFirebase(performance);
    }
    setupTracers.clear();
  }
}
