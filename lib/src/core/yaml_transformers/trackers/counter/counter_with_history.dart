part of 'generic_counter.dart';

/// A [Counter] class that tracks a specific values and also maintains the
/// history of previously tracked value based on a cursor.
///
/// [C] - denotes the cursor type. Think of it as a key linking any tracker
/// state stored. Can be any data type as long as you make it unique.
///
/// [K] - denotes the value being tracked. Acts as a key to the map used
/// internally. It is wrapped with a [TrackerKey] for equality & hashing ease.
///
/// [L] - denotes an optional type incase a [MapEntry] is passed. In which
/// case, the value of [K] & [L] are both wrapped in a [DualTrackerKey].
///
/// See [TrackerKey], [DualTrackerKey]
base class CounterWithHistory<C, K, L> extends Counter<K, L>
    with MapHistory<C, K, L, int> {
  int? getCountFromHistory(C cursor, dynamic value, Origin origin) {
    final key = createKey(value, origin: origin);
    return getFromHistory(cursor)?[key];
  }
}
