import 'package:equatable/equatable.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:meta/meta.dart';

part 'counter_with_history.dart';
part 'tracker_key.dart';

/// A generic counter class that keeps count of values.
///
/// Generic [T] - denotes strict type of value being tracked.
///
/// See [TrackerKey].
base class Counter<T> {
  Counter() : _counter = {};

  /// A tracker keeping count of each value being added to it
  final Map<TrackerKey<T>, int> _counter;

  /// Get the current state of the tracker
  Map<TrackerKey<T>, int> get counterstate => _counter;

  /// Creates a tracker key tracking
  TrackerKey<T> createKey(T value, {required Origin origin}) {
    if (value is MapEntry) {
      return DualTrackerKey<T, dynamic>.fromEntry(
        entry: value,
      );
    }
    return TrackerKey<T>.fromValue(value, origin);
  }

  /// Adds a key if missing and increments the count if present.
  void _addKey(TrackerKey<T> key, {bool isStartingTracker = false}) {
    _counter.update(
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
      final key = createKey(value as T, origin: origin);
      _addKey(key, isStartingTracker: true);
    }
  }

  /// Increments count with dynamic value
  void increment(Iterable<dynamic> values, {required Origin origin}) {
    for (final candidate in values) {
      final key = createKey(candidate as T, origin: origin);
      _addKey(key);
    }
  }

  /// Obtains count based on a value being being tracked. Returns zero if
  /// value is not being tracked or its count is zero.
  int getCount(T value, {required Origin origin}) {
    final key = createKey(value, origin: origin); // Key to get count using
    return getCountFromKey(key);
  }

  /// Obtains count based on a [TrackerKey] wrapping the value. Returns zero if
  /// [TrackerKey] is not being tracked or its count is zero.
  ///
  /// Internally used by [Counter.getCount] which wraps a value with a
  /// [TrackerKey] before obtaining the count use this method.
  int getCountFromKey(TrackerKey<T> key) {
    return _counter[key] ?? 0; // Return 0 if missing
  }

  /// Obtains the sum of all counts of values being counted
  int getSumOfCount() {
    if (_counter.isEmpty) return 0;
    return _counter.values.reduce((value, element) => value + element);
  }

  @override
  String toString() => _counter.toString();
}
