import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';

part 'counter_with_history.dart';

/// A generic counter class that keeps count of values.
///
/// [K] - denotes the value being tracked. Acts as a key to the map used
/// internally. It is wrapped with a [TrackerKey] for equality & hashing ease.
///
/// [L] - denotes an optional type incase a [MapEntry] is passed. In which
/// case, the value of [K] & [L] are both wrapped in a [DualTrackerKey].
///
/// See [TrackerKey].
base class Counter<K, L> extends DualTracker<K, L, int> {
  /// Adds a key if missing and increments the count if present.
  void _addKey(TrackerKey<K> key, {bool isStartingTracker = false}) {
    trackerState.update(
      key,
      (value) => ++value,
      ifAbsent: () => isStartingTracker ? 0 : 1,
    );
  }

  /// Prefills counter with values we need to accurately keep count of. Use
  /// when you know each value being counted before hand.
  void prefill(List<dynamic>? keys, {required Origin origin}) {
    if (keys == null) return;
    for (final value in keys) {
      final key = createKey(value, origin: origin);
      _addKey(key, isStartingTracker: true);
    }
  }

  /// Increments count with dynamic value
  void increment(Iterable<dynamic> values, {required Origin origin}) {
    for (final candidate in values) {
      final key = createKey(candidate, origin: origin);
      _addKey(key);
    }
  }

  /// Obtains count based on a value being being tracked. Returns zero if
  /// value is not being tracked or its count is zero.
  int getCount(dynamic value, {required Origin origin}) {
    final key = createKey(value, origin: origin);
    return getCountFromKey(key);
  }

  /// Obtains count based on a [TrackerKey] wrapping the value. Returns zero if
  /// [TrackerKey] is not being tracked or its count is zero.
  ///
  /// Internally used by [Counter.getCount] which wraps a value with a
  /// [TrackerKey] before obtaining the count use this method.
  int getCountFromKey(TrackerKey<K> key) {
    return trackerState[key] ?? 0; // Return 0 if missing
  }

  /// Obtains the sum of all counts of values being counted
  int getSumOfCount() {
    if (trackerState.isEmpty) return 0;
    return trackerState.values.reduce((value, element) => value + element);
  }

  @override
  String toString() => trackerState.toString();
}
