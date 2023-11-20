part of '../../map_extensions.dart';

/// Recursive Functions for lists nested in maps. This is private utility
/// class for this extension
class RecursiveHelper {
  ///
  /// Recurses a list and searches for a `target` and returns its value. This
  /// is a READ-ONLY version of [ recurseNestedList ].
  ///
  ///   * `nestedList` - denotes list nested in map.
  ///   * `target` - denotes terminal key with value.
  ///   * `path` - denotes list of keys preceding `target`.
  ///
  /// NOTE:
  ///   1. If target key is a value rather than a key, null is returned.
  ///   2. If a target key has no value, null is returned
  ///   3. If a target key is not found, null will (and SHOULD) be returned
  ///      by the caller of this method.
  static T? readNestedList<T>(
    List<dynamic> nestedList, {
    required dynamic target,
    required List<dynamic> path,
  }) {
    final keyWanted = path.isEmpty ? target : path.first;

    // Loop it
    for (final value in nestedList) {
      if (value is String) {
        if (value != keyWanted) continue;

        // If value is string, means there is no value
        return null;
      }

      // For maps check if key exists
      else if (value is Map) {
        if (!value.containsKey(keyWanted)) continue;

        return value.recursiveRead(path: path, target: target);
      }

      // For lists, return this function
      return readNestedList(value as List, target: target, path: path);
    }

    return null;
  }

  ///
  /// Recurses a list and updates any value(s) nested within the list.
  ///
  /// If the value is within a map i.e. the path to target key has not been
  /// exhausted, we recursively call the initial caller that is,
  /// `recursivelyUpdate` in `MapUtility` extension.
  ///
  /// For `String`, value is updated at current index while looping.
  ///
  /// A `List` calls this method (recursively).
  ///
  static RecursiveListOutput recurseNestedList(
    List<dynamic> listToRecurse, {
    required dynamic update,
    required String target,
    required List<String> currentPath,
    required UpdateMode updateMode,
    required KeyAndReplacement keyAndReplacement,
    required String? valueToReplace,
    bool? isTerminal,
  }) {
    // We first make list modifiable
    final modifiableList = [...listToRecurse];

    /// Tracks if the loop managed to modify the desired value.
    var didFindAndModify = false;

    if (isTerminal != null && isTerminal && updateMode == UpdateMode.replace) {
      ///
      /// This section is used by the [UpdateMode.replace] to replace the
      /// first matching value
      for (final (index, valueInList) in modifiableList.indexed) {
        // If we find matching value update it and break loop
        if (valueInList is String && valueInList == valueToReplace) {
          modifiableList[index] = update;

          didFindAndModify = true;
        }

        // If value is list recurse on it
        else if (valueInList is List) {
          final recursedList = recurseNestedList(
            valueInList,
            update: update,
            target: target,
            currentPath: currentPath,
            updateMode: updateMode,
            keyAndReplacement: keyAndReplacement,
            valueToReplace: valueToReplace,
            isTerminal: true,
          );

          if (!recursedList.didModify) continue;

          modifiableList[index] = recursedList.modified;

          didFindAndModify = true;
        }

        // Anything else we ignore, as we are not looking for a key now
        else {
          continue;
        }

        // Both conditions always guarantee an update
        if (didFindAndModify) break;
      }
      //
    }

    /// With [UpdateMode.append] or [UpdateMode.overwrite],
    else {
      ///

      ///
      /// For lists, we want to look for the next key so that we recurse on it
      /// as a map.
      ///
      /// * If the key is a string, we convert to map to recurse on it only if
      ///   append is false. We cannot append to an existing value. We,
      ///   however, can overwrite it.
      ///
      /// * If we find a map, check if it contains the key. If it does, we
      ///   recurse on it.
      ///
      /// * If we find a list, call this function recursively

      // Get the next key
      final wantedKey = currentPath.isEmpty ? target : currentPath.first;

      // Loop it value by value
      for (final (index, valueInList) in modifiableList.indexed) {
        // For strings, only matching values
        if (valueInList is String && valueInList == wantedKey) {
          // We cannot append, only overwrite
          if (updateMode == UpdateMode.append) {
            throw MagicalException(
              violation:
                  '''Cannot append new values at "$valueInList". You need to overwrite this value as it is nested in a list.''',
            );
          }

          // We convert to map
          final mapForString = <dynamic, dynamic>{}.recursivelyUpdate(
            update,
            target: target,
            path: currentPath,
            updateMode: updateMode,
            keyAndReplacement: keyAndReplacement,
            valueToReplace: valueToReplace,
          );

          // Update value with map
          modifiableList[index] = mapForString;

          // Mark as modified
          didFindAndModify = true;
        }

        // For maps. It must contain key
        else if (valueInList is Map && valueInList.containsKey(wantedKey)) {
          // If it does, we know it will be updated if we recurse on the map
          modifiableList[index] = {...valueInList}.recursivelyUpdate(
            update,
            target: target,
            path: currentPath,
            updateMode: updateMode,
            keyAndReplacement: keyAndReplacement,
            valueToReplace: valueToReplace,
          );

          // Mark as modified
          didFindAndModify = true;
        }

        // Call itself till we find key needed
        else if (valueInList is List) {
          final recursedList = recurseNestedList(
            valueInList,
            update: update,
            target: target,
            currentPath: currentPath,
            updateMode: updateMode,
            keyAndReplacement: keyAndReplacement,
            valueToReplace: valueToReplace,
          );

          if (!recursedList.didModify) continue;

          modifiableList[index] = recursedList.modified;

          didFindAndModify = true;
        }

        // Break this loop if was modified
        if (didFindAndModify) break;
      }
    }

    return (
      didModify: didFindAndModify,
      modified: didFindAndModify ? modifiableList : [],
    );
  }
}
