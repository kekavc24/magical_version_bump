part of 'finder.dart';

/// Custom counter that increments using [MatchedNodeData]. It uses a file
/// index as cursor that links it with its counter.
///
/// See [Counter].
final class MatchCounter extends CounterWithHistory<int, dynamic, dynamic> {
  MatchCounter({this.limit}) : isStrict = limit != null;

  final bool isStrict;

  final int? limit;

  /// Increments from [ MatchedNodeData ].
  ///
  /// Returns true if all elements are found. Useful if counter was prefilled.
  ///
  /// Always returns false if limit is null.
  bool incrementUsingMatch(MatchedNodeData data) {
    // Add any matched keys
    if (data.matchedKeys.isNotEmpty) {
      final ignoredKeys = increment(data.matchedKeys, origin: Origin.key);

      data.matchedKeys.removeWhere(ignoredKeys.contains); // Remove ignored keys
    }

    // Add matched value if not empty
    if (data.matchedValue.isNotEmpty) {
      if (increment([data.matchedValue], origin: Origin.value).isNotEmpty) {
        data.matchedValue = ''; // Remove value
      }
    }

    // Add all pairs
    if (data.matchedPairs.isNotEmpty) {
      final ignoredPairs = increment(
        data.matchedPairs.entries,
        origin: Origin.pair,
      ) as List<MapEntry<String, String>>;

      data.matchedPairs.removeWhere(
        (key, value) => ignoredPairs.any(
          (element) => element.key == key && element.value == value,
        ),
      );
    }

    /// All must be equal or greater than limit. Other keys may have
    /// been found before more than once.
    ///
    /// Get set of all counts and check if any is below limit
    final anyBelowLimit = limit == null ||
        super.trackerState.values.toSet().any((element) => element < limit!);

    return !anyBelowLimit;
  }

  @override
  List<dynamic> increment(Iterable<dynamic> values, {required Origin origin}) {
    final ignored = <dynamic>[];
    final valuesToAdd = <dynamic>[...values];

    // In strict mode, ensure we only add those below limit
    if (isStrict) {
      for (final value in values) {
        if (getCount(value, origin: origin) == limit) {
          ignored.add(value);
          valuesToAdd.remove(value);
        }
      }
    }

    super.increment(valuesToAdd, origin: origin);
    return ignored;
  }
}
