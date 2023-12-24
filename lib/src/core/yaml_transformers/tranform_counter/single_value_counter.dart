part of 'transform_counter.dart';

base class CounterWithNoHistory<T> {
  CounterWithNoHistory() : _counter = {};

  /// A tracker keeping count of each value being added to it
  final Map<TrackerKey<T>, int> _counter;

  /// Get the current state of the tracker
  Map<TrackerKey<T>, int> get trackerState => _counter;

  /// Creates a tracker key tracking
  TrackerKey<T> createKey(T value, {Origin? origin}) {
    return TrackerKey<T>.fromValue(value, origin!);
  }

  /// Adds a key if missing and increments the count if present.
  void _addKey(TrackerKey<T> key, {bool isStartingTracker = false}) {
    _counter.update(
      key,
      (value) => ++value,
      ifAbsent: () => isStartingTracker ? 0 : 1,
    );
  }

  /// Set up all trackable keys.
  ///
  /// Important when we want to track an exact number for each key/value
  void prefill(List<dynamic> keys, {Origin? origin}) {
    for (final value in keys) {
      final key = createKey(value as T, origin: origin);
      _addKey(key, isStartingTracker: true);
    }
  }

  /// Increment with dynamic value
  void increment(Iterable<dynamic> values, {Origin? origin}) {
    for (final candidate in values) {
      final key = createKey(candidate as T, origin: origin);
      _addKey(key);
    }
  }

  /// 
  int getCount(T value, {required Origin origin}) {
    final key = createKey(value); // Key to get count using
    return getCountFromKey(key);
  }

  int getCountFromKey(TrackerKey<T> key) {
    return _counter[key] ?? 0; // Return 0 if missing
  }
}

/// A generic tracker class that tracks a specific values and also maintain the
/// history of previously tracked value based on a cursor.
///
/// The cursor point to a previous tracker state stored in history. A cursor
/// can be any data type. It should, however be unique.
///
/// Generic [C] - denotes the strict cursor runtype.
///
/// Generic [T] - denotes strict type of value being tracked.
///
/// See [TrackerKey]
base class SingleValueCounter<C, T> extends CounterWithNoHistory<T> {
  SingleValueCounter() : _counterHistory = {};

  /// History of counters.
  ///
  /// Order is based on file number
  final Map<C, Map<TrackerKey<T>, int>> _counterHistory;

  Map<C, Map<TrackerKey<T>, int>> get trackerHistory => _counterHistory;

  @override
  int getCountFromKey(
    TrackerKey<T> key, {
    bool useHistory = false,
    C? cursor,
  }) {
    // A valid cursor used as an index must be present
    if (useHistory && cursor == null) {
      throw MagicalException(violation: 'A valid file index is required');
    }

    int? count;

    // The history should have this value
    if (useHistory) {
      final counterFromHistory = _counterHistory[cursor];

      if (counterFromHistory == null) {
        throw MagicalException(
          violation: 'This file index is not being tracked!',
        );
      }

      count = counterFromHistory[key];
    } else {
      count = _counter[key];
    }

    return count ?? 0; // Return 0 if missing
  }

  /// Resets a tracker.
  ///
  /// The last tracker state is saved to history. A file number is required
  /// to link this file
  void reset({required C cursor}) {
    if (_counterHistory.containsKey(cursor)) {
      throw MagicalException(violation: 'This file is already tracked!');
    }

    _counterHistory[cursor] = {..._counter};
    _counter.clear();
  }

  @override
  String toString() => _counter.toString();
}
