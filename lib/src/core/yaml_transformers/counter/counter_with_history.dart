part of 'transform_counter.dart';

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
base class CounterWithHistory<C, T> extends Counter<T> {
  CounterWithHistory() : _counterHistory = {};

  /// History of counters.
  ///
  /// Order is based on file number
  final Map<C, Map<TrackerKey<T>, int>> _counterHistory;

  Map<C, Map<TrackerKey<T>, int>> get counterHistory => _counterHistory;

  @override
  int getCountFromKey(
    TrackerKey<T> key, {
    bool useHistory = false,
    C? cursor,
  }) {
    // A valid cursor used as an index must be present
    if (useHistory && cursor == null) {
      throw MagicalException(violation: 'A valid cursor is required');
    }

    int? count;

    // The history should have this value
    if (useHistory) {
      final counterFromHistory = _counterHistory[cursor];

      if (counterFromHistory == null) {
        throw MagicalException(violation: 'This cursor is not being tracked!');
      }

      count = counterFromHistory[key];
    } else {
      count = _counter[key];
    }

    return count ?? 0; // Return 0 if missing
  }

  /// Resets a tracker and returns the state save to history.
  ///
  /// The last tracker state is saved to history. A file number is required
  /// to link this file.
  ///
  ///
  Map<TrackerKey<T>, int> reset({required C cursor}) {
    if (_counterHistory.containsKey(cursor)) {
      throw MagicalException(violation: 'This cursor is already tracked!');
    }

    final stateToSave = {..._counter};
    _counterHistory[cursor] = stateToSave;
    _counter.clear();
    return stateToSave;
  }

  @override
  String toString() => _counter.toString();
}
