import 'package:equatable/equatable.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/magical_exception.dart';
import 'package:meta/meta.dart';

part 'tracker_key.dart';

/// A tracker that tracks a value of type [KeyT] and its info of type [ValueT].
///
/// [KeyT] - denotes the value being tracked. Acts as a key to the map used
/// internally. It is wrapped with a [TrackerKey] for equality & hashing ease.
///
/// [ValueT] - denotes the tracking info. Stored as is.
base class SingleValueTracker<KeyT, ValueT> {
  /// Current state of the tracker
  final Map<TrackerKey<KeyT>, ValueT> trackerState = {};

  /// Creates a tracker key tracking a value
  @protected
  TrackerKey<KeyT> createKey(KeyT value, {required Origin origin}) {
    return TrackerKey<KeyT>.fromValue(value, origin);
  }
  
  /// Checks if the map contains the specified [key]
  bool containsTrackerKey(KeyT key, {required Origin origin}) {
    return trackerState.containsKey(
      createKey(key, origin: origin),
    );
  }
}

/// An extension of [SingleValueTracker] which includes an additional value
/// i.e from a [MapEntry] where [KeyT] is its key and [OtherKeyT] its value.
///
/// [KeyT] - denotes the value being tracked. Acts as a key to the map used
/// internally. It is wrapped with a [TrackerKey] for equality & hashing ease.
///
/// [OtherKeyT] - denotes an optional type incase a [MapEntry] is passed. In 
/// which case, the value of [KeyT] & [OtherKeyT] are both wrapped in a 
/// [DualTrackerKey].
///
/// [ValueT] - denotes the tracking info. Stored as is.
///
base class DualTracker<KeyT, OtherKeyT, ValueT>
    extends SingleValueTracker<KeyT, ValueT> {
  @override
  @protected
  TrackerKey<KeyT> createKey(dynamic value, {required Origin origin}) {
    if (value is MapEntry) {
      return DualTrackerKey<KeyT, OtherKeyT>.fromEntry(
        entry: value,
        origin: origin,
      );
    }

    return super.createKey(value as KeyT, origin: origin);
  }
}

/// A mixin to add history functionality to any [SingleValueTracker] class/
/// its subclasses.
///
/// [CursorT] - denotes the cursor type. Think of it as a key linking any 
/// tracker state stored. Can be any data type as long as you make it unique
///
/// [KeyT] - denotes the value being tracked. Acts as a key to the map used
/// internally. It is wrapped with a [TrackerKey] for equality & hashing ease.
///
/// [OtherKeyT] - denotes an optional type incase a [MapEntry] is passed. In 
/// which case, the value of [KeyT] & [OtherKeyT] are both wrapped in a 
/// [DualTrackerKey].
///
/// [ValueT] - denotes the tracking info. Stored as is.
base mixin MapHistory<CursorT, KeyT, OtherKeyT, ValueT>
    on SingleValueTracker<KeyT, ValueT> {
  /// Stores the tracker history for a [SingleValueTracker] or 
  /// [DualTracker]
  final Map<CursorT, Map<TrackerKey<KeyT>, ValueT>> history = {};

  /// Obtains the tracker state linked to this [cursor] from history.
  Map<TrackerKey<KeyT>, ValueT>? getFromHistory(CursorT cursor) =>
      history[cursor];

  /// Stores a Map linked to a cursor and returns current map/tracker state
  /// before clearing it.
  ///
  /// Throws an exception if cursor already exists.
  Map<TrackerKey<KeyT>, ValueT> reset({required CursorT cursor}) {
    if (history.containsKey(cursor)) {
      throw MagicalException(message: 'This cursor is already tracked!');
    }

    final stateToSave = Map<TrackerKey<KeyT>, ValueT>.from(trackerState);
    history[cursor] = stateToSave;
    trackerState.clear();
    return stateToSave;
  }

  /// Removes cursor from history together with any data present
  void dropCursor(CursorT cursor) {
    history.remove(cursor);
  }
}
