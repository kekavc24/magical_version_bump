import 'package:equatable/equatable.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:meta/meta.dart';

part 'tracker_key.dart';

/// A tracker that tracks a value of type [K] and its info of type [V].
///
/// [K] - denotes the value being tracked. Acts as a key to the map used
/// internally. It is wrapped with a [TrackerKey] for equality & hashing ease.
///
/// [V] - denotes the tracking info. Stored as is.
abstract base class SingleValueTracker<K, V> {
  final Map<TrackerKey<K>, V> _tracker = {};

  /// Obtains the current state of the tracker
  Map<TrackerKey<K>, V> get trackerState => _tracker;

  /// Clear map backing this tracker
  void clearTracker() => _tracker.clear();

  /// Creates a tracker key tracking a value
  T createKey<T>(dynamic value, {required Origin origin}) {
    return TrackerKey<K>.fromValue(value, origin) as T;
  }

  /// Add a key to the map backing this tracker
  @protected
  void addKey(
    TrackerKey<K> key,
    V Function(V) update, {
    V Function()? ifAbsent,
  }) {
    _tracker.update(key, update, ifAbsent: ifAbsent);
  }
}

/// An extension of [SingleValueTracker] which includes an additional value
/// i.e from a [MapEntry] where [K] is its key and [L] its value.
///
/// [K] - denotes the value being tracked. Acts as a key to the map used
/// internally. It is wrapped with a [TrackerKey] for equality & hashing ease.
///
/// [L] - denotes an optional type incase a [MapEntry] is passed. In which
/// case, the value of [K] & [L] are both wrapped in a [DualTrackerKey].
///
/// [V] - denotes the tracking info. Stored as is.
///
abstract base class DualTracker<K, L, V> extends SingleValueTracker<K, V> {
  @override
  T createKey<T>(dynamic value, {required Origin origin}) {
    if (value is MapEntry) {
      return DualTrackerKey<K, L>.fromEntry(entry: value, origin: origin) as T;
    }

    return super.createKey(value, origin: origin);
  }
}

/// A mixin to add history functionality to any [SingleValueTracker] class/
/// its subclasses.
///
/// [C] - denotes the cursor type. Think of it as a key linking any tracker
/// state stored. Can be any data type as long as you make it unique
///
/// [H] - denotes the [Map] whose state is being saved
base mixin MapHistory<C, K, L, V> on DualTracker<K, L, V> {
  /// Stores the current
  final Map<C, Map<TrackerKey<K>, V>> _history = {};

  /// Obtains the tracker history
  Map<C, Map<TrackerKey<K>, V>> get history => _history;

  /// Obtains the tracker state linked to this [cursor] from history.
  Map<TrackerKey<K>, V>? getFromHistory(C cursor) => _history[cursor];

  /// Stores a Map linked to a cursor and returns a map just before it was
  /// cleared/reset for next cycle.
  ///
  /// Throws an exception if cursor already exists.
  Map<TrackerKey<K>, V> reset({required C cursor}) {
    if (_history.containsKey(cursor)) {
      throw MagicalException(violation: 'This cursor is already tracked!');
    }

    final stateToSave = Map<TrackerKey<K>, V>.from(_tracker);
    history[cursor] = stateToSave;
    clearTracker();
    return stateToSave;
  }
}
