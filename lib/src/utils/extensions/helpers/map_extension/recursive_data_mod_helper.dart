part of '../../map_extensions.dart';

class RecursiveDataHelper {
  /// Get key
  static String getKey({
    required UpdateMode updateMode,
    required String current,
    required String? replacement,
  }) {
    return updateMode == UpdateMode.replace && replacement != null
        ? replacement
        : current;
  }

  /// Obtains the current working map.
  /// 
  /// In `UpdateMode.replace`, a key may need to be renamed. For this, we swap
  /// it. Otherwise, just return map "as-is".
  static Map<dynamic, dynamic> getMap({
    required UpdateMode updateMode,
    required String current,
    required String? replacement,
    required Map<dynamic, dynamic> currentMap,
  }) {
    // If  & replacement is present, swap it
    if (updateMode == UpdateMode.replace && replacement != null) {
      return _swapKeyInMap(
        map: currentMap,
        target: current,
        replacement: replacement,
      );
    }
    return currentMap;
  }

  /// Swap a key with another in a map in `UpdateMode.replace`.
  static Map<dynamic, dynamic> _swapKeyInMap({
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
  /// In `UpdateMode.replace`, the first matching value is replaced and an
  /// `RecursiveListOutput` returned.
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
  static dynamic updateTerminalValue({
    required UpdateMode updateMode,
    required dynamic update,
    required dynamic currentValue,
    required String? valueToReplace,
  }) {
    dynamic updatedTerminal;

    /// [UpdateMode.replace]
    if (updateMode == UpdateMode.replace) {
      ///
      /// If value is a [String] just swap.
      ///
      /// If value is [List], recurse till we find first matching value.
      /// The pre-indexed [ NodeData ] guarantees this method that the value
      /// will always exist!
      ///
      /// The value will never be in a [Map] as we have reached the 'terminal',
      /// we just have to look for the value in the list
      ///
      if (currentValue is String) {
        updatedTerminal = update;
      } else {
        updatedTerminal = RecursiveHelper.recurseNestedList(
          currentValue as List,
          update: update,
          target: '',
          currentPath: [],
          updateMode: updateMode,
          keyAndReplacement: {},
          valueToReplace: valueToReplace,
          isTerminal: true,
        );
      }
    }

    /// Other just run [UpdateMode.overwrite] & [UpdateMode.append]
    else {
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
    }

    return updatedTerminal;
  }
}
