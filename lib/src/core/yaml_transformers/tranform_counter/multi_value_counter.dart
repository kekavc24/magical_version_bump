part of 'transform_counter.dart';

/// A generic tracker class that tracks a specific values and also maintain the
/// history of previously tracked value based on a cursor.
///
/// The cursor point to a previous tracker state stored in history. A cursor
/// can be any data type. It MUST be unique.
///
/// Generic [C] - denotes the strict cursor runtype.
///
/// Generic [T] - denotes strict type of value being tracked.
///
/// Generic [U] - denotes string type of another value to be paired with [T] for
/// tracking in `DualTrackerKey`.
///
/// See also [DualTrackerKey].
base class MultiValueCounter<C, T, U> extends SingleValueCounter<C, T> {
  @override
  TrackerKey<T> createKey(dynamic value, {Origin? origin}) {
    if (value is List) {
      if (value.length == 2) {
        return DualTrackerKey<T, U>.fromValue(
          key: value[0],
          otherKey: value[1],
          origin: origin,
        );
      }
    } else if (value is MapEntry) {
      return DualTrackerKey<T, U>.fromEntry(entry: value, origin: origin);
    }

    return super.createKey(value as T, origin: origin);
  }
}
