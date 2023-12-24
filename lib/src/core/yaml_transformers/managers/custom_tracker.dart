part of 'manager.dart';

final class ManagerTracker extends MultiValueCounter<int, String, String> {
  ManagerTracker({required int? limit}) : _limit = limit;

  final int? _limit;

  /// Increments from [ MatchedNodeData ].
  ///
  /// Returns true if all, elements are within the limit.
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
      increment(data.matchedPairs.entries);
    }

    /// All must be equal or greater than limit. Other keys may have
    /// been found before more than once
    return _limit != null &&
        super.trackerState.values.every((element) => element >= _limit!);
  }
}
