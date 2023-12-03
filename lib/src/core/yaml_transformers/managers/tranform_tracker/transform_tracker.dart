import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:meta/meta.dart';

part 'tracker_key.dart';

class TransformTracker {
  TransformTracker({required this.limit})
      : _countTracker = {},
        _counterHistory = [];

  /// A tracker keeping count of each value being added to it
  final Map<TrackerKey, int> _countTracker;

  /// History of counters.
  ///
  /// Order is based on tracking order
  final List<Map<TrackerKey, int>> _counterHistory;

  /// The max count required to allow additions
  final int? limit;

  List<Map<TrackerKey, int>> get trackerHistory => _counterHistory;

  /// Set up all trackable keys.
  ///
  /// Important when we want to track an exact number for each key/value
  void prefill(List<dynamic> keys, {Origin? origin}) {
    for (final value in keys) {
      final key = createKey(value, origin: origin);
      _addKey(key, isStartingTracker: true);
    }
  }

  /// Get the current state of the tracker
  Map<TrackerKey, int> get trackerState => _countTracker;

  TrackerKey createKey(dynamic value, {Origin? origin}) {
    if (value is String) {
      return TrackerKey(key: value, origin: origin!);
    } else if (value is MapEntry<String, String>) {
      return DualTrackerKey.fromMapEntry(value);
    }

    throw MagicalException(
      violation:
          'Not a valid key. Must be of type String or Map<String, String>',
    );
  }

  /// Adds a key if missing and increments the count if present.
  void _addKey(TrackerKey key, {bool isStartingTracker = false}) {
    _countTracker.update(
      key,
      (value) => ++value,
      ifAbsent: () => isStartingTracker ? 0 : 1,
    );
  }

  /// Increment with dynamic value
  void increment(Iterable<dynamic> values, {Origin? origin}) {
    for (final candidate in values) {
      final key = createKey(candidate, origin: origin);
      _addKey(key);
    }
  }

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
    return limit != null &&
        _countTracker.values.every((element) => element >= limit!);
  }

  int getCount(dynamic value, {required Origin origin}) {
    final key = value is MapEntry<String, String>
        ? DualTrackerKey.fromMapEntry(value)
        : TrackerKey(key: value as String, origin: origin);
    return _countTracker[key] ?? 0; // Return 0 if missing
  }

  /// Resets a tracker.
  ///
  /// The last tracker state is saved to history.
  void reset() {
    _counterHistory.add({..._countTracker});
    _countTracker.clear();
  }

  @override
  String toString() => _countTracker.toString();
}