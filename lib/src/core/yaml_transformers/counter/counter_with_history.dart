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

  int? getCountFromHistory(C cursor, T value, Origin origin) {
    // Get history of this cursor
    final counterFromHistory = _counterHistory[cursor];

    if (counterFromHistory != null) {
      final key = createKey(value, origin: origin);
      return counterFromHistory[key];
    }

    return null;
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
