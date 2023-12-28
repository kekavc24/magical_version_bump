part of 'finder.dart';

/// Custom counter that increments using [MatchedNodeData]. It uses a file 
/// index as cursor that links it with its counter.
///
/// See [Counter].
final class MatchCounter extends CounterWithHistory<int, dynamic> {
  MatchCounter({required int? limit}) : _limit = limit;

  final int? _limit;

  /// Increments from [ MatchedNodeData ].
  ///
  /// Returns true if all elements are found. Useful if counter was prefilled.
  ///
  /// Always returns false if limit is null.
  bool incrementUsingMatch(MatchedNodeData data) {
    // Add any matched keys
    if (data.matchedKeys.isNotEmpty) {
      increment(data.matchedKeys, origin: Origin.key);
    }

    // Add matched value if not empty
    if (data.matchedValue.isNotEmpty) {
      increment([data.matchedValue], origin: Origin.value);
    }

    // Add all pairs
    if (data.matchedPairs.isNotEmpty) {
      increment(data.matchedPairs.entries, origin: Origin.pair);
    }

    /// All must be equal or greater than limit. Other keys may have
    /// been found before more than once.
    ///
    /// Get set of all counts and check if any is below limit
    final anyBelowLimit = _limit == null ||
        super.counterstate.values.toSet().any((element) => element < _limit!);

    return !anyBelowLimit;
  }
}
