import 'package:equatable/equatable.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/magical_exception.dart';
import 'package:meta/meta.dart';

part 'tracker_key.dart';

/// A tracker that tracks a value of type [K] and its info of type [V].
///
/// [K] - denotes the value being tracked. Acts as a key to the map used
/// internally. It is wrapped with a [TrackerKey] for equality & hashing ease.
///
/// [V] - denotes the tracking info. Stored as is.
base class SingleValueTracker<K, V> {
  final Map<TrackerKey<K>, V> _tracker = {};

  /// Obtains the current state of the tracker
  Map<TrackerKey<K>, V> get trackerState => _tracker;

  /// Creates a tracker key tracking a value
  @protected
  TrackerKey<K> createKey(dynamic value, {required Origin origin}) {
    return TrackerKey<K>.fromValue(value, origin);
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
base class DualTracker<K, L, V> extends SingleValueTracker<K, V> {
  @override
  @protected
  TrackerKey<K> createKey(dynamic value, {required Origin origin}) {
    if (value is MapEntry) {
      return DualTrackerKey<K, L>.fromEntry(entry: value, origin: origin);
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
/// [K] - denotes the value being tracked. Acts as a key to the map used
/// internally. It is wrapped with a [TrackerKey] for equality & hashing ease.
///
/// [L] - denotes an optional type incase a [MapEntry] is passed. In which
/// case, the value of [K] & [L] are both wrapped in a [DualTrackerKey].
///
/// [V] - denotes the tracking info. Stored as is.
base mixin MapHistory<C, K, L, V> on SingleValueTracker<K, V> {
  /// Stores the current
  final Map<C, Map<TrackerKey<K>, V>> _history = {};

  /// Obtains the tracker history
  Map<C, Map<TrackerKey<K>, V>> get history => _history;

  /// Obtains the tracker state linked to this [cursor] from history.
  Map<TrackerKey<K>, V>? getFromHistory(C cursor) => _history[cursor];

  /// Stores a Map linked to a cursor and returns current map/tracker state
  /// before clearing it.
  ///
  /// Throws an exception if cursor already exists.
  Map<TrackerKey<K>, V> reset({required C cursor}) {
    if (_history.containsKey(cursor)) {
      throw MagicalException(message: 'This cursor is already tracked!');
    }

    final stateToSave = Map<TrackerKey<K>, V>.from(_tracker);
    history[cursor] = stateToSave;
    _tracker.clear();
    return stateToSave;
  }

  /// Removes cursor from history together with any data present
  void dropCursor(C cursor) {
    _history.remove(cursor);
  }
}
