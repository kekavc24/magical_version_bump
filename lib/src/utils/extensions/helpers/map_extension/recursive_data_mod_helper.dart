part of '../../map_extensions.dart';

({String key, Map<dynamic, dynamic> map}) _attemptSwap({
  required String currentKey,
  required String? replacement,
  required Map<dynamic, dynamic> currentMap,
}) {
  // Return as is, if replacement is null
  if (replacement == null) {
    return (key: currentKey, map: currentMap);
  }

  return (
    key: replacement,
    map: _swapKey(
      map: currentMap,
      target: currentKey,
      replacement: replacement,
    ),
  );
}

/// Swap a key with another in a map in `UpdateMode.replace`.
Map<dynamic, dynamic> _swapKey({
  required Map<dynamic, dynamic> map,
  required String target,
  required String replacement,
}) {
  /// If map already contains it. Maybe it was replaced earilier
  /// by another key
  if (!map.containsKey(target) && map.containsKey(replacement)) {
    return map;
  }

  // Read existing value
  final valueAtKey = map[target];

  final swapped = <dynamic, dynamic>{};

  // Replace/rename it at existing index. Avoid putting it at the end
  for (final entry in map.entries) {
    entry.key == target
        ? swapped.addAll({replacement: valueAtKey})
        : swapped.addEntries([entry]);
  }
  return swapped;
}

/// Updates a terminal value of node after exhausting all keys in path.
///
/// In `UpdateMode.append`, the value is "appended" to the existing value.
///
/// In `UpdateMode.overwrite`, the entire value held at the terminal key is
/// replaced.
///
/// `NOTE:`
/// Functionality of `UpdateMode.replace` & `UpdateMode.overwrite` may look
/// similar by definition but `UpdateMode.replace` singles out a value
/// if in a list whereas `UpdateMode.overwrite` treats the entire list as a
/// single value.
///
dynamic _updateTerminalValue({
  required UpdateMode updateMode,
  required dynamic update,
  required dynamic currentValue,
}) {
  dynamic updatedTerminal;

  final targetValIsNull = currentValue == null;

  ///
  /// If we are overwriting or value we are appending is null, just set
  /// a value. A guarantee of [UpdateMode.overwrite] & [UpdateMode.append]
  /// is that missing values & keys are created
  ///
  if (updateMode == UpdateMode.append && targetValIsNull ||
      updateMode == UpdateMode.overwrite) {
    return update is String && updateMode == UpdateMode.overwrite
        ? update
        : update is String && updateMode == UpdateMode.append
            ? <String>[update]
            : update is List<String>
                ? <String>[...update]
                : update as Map<String, String>;
  }

  // Convert to list by default since only a single value exists
  if (currentValue is String) {
    updatedTerminal = update is List
        ? <dynamic>[currentValue, ...update]
        : <dynamic>[currentValue, update];
  }

  // For List, just spread in old values
  else if (currentValue is List) {
    updatedTerminal = update is List
        ? [...currentValue, ...update]
        : [...currentValue, update];
  }

  // For maps, anything that is not a map forces it to be list
  else {
    if (update is Map) {
      updatedTerminal = <dynamic, dynamic>{}
        ..addAll(currentValue as Map)
        ..addAll(update as Map<String, String>);
    } else {
      updatedTerminal = update is String
          ? <dynamic>[currentValue, update]
          : <dynamic>[currentValue, ...update as List];
    }
  }

  return updatedTerminal;
}
