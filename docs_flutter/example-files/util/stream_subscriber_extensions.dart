// ignore_for_file: prefer_match_file_name
import 'dart:async';

extension CancelAll on List<StreamSubscription> {
  void cancelAll() {
    for (final subscription in this) {
      subscription.cancel();
    }
  }
}
