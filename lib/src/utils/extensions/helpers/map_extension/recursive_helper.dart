part of '../../map_extensions.dart';

/// Recursive Functions for lists nested in maps. This is private utility
/// class for this extension
///

/// Check if a value is terminal. A terminal value can ONLY be null or a
/// string.
bool isTerminal(dynamic data) =>
    data == null ||
    data is String ||
    data is int ||
    data is double ||
    data is bool;

///
/// Recurses a list and searches for a `target` and returns its value. This
/// is a READ-ONLY version of [ _recurseNestedList ].
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
T? _readNestedList<T>(
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
    return _readNestedList(value as List, target: target, path: path);
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
RecursiveListOutput _recurseNestedList(
  List<dynamic> listToRecurse, {
  required dynamic update,
  required String target,
  required List<String> currentPath,
  required UpdateMode updateMode,
}) {
  // We first make list modifiable
  final modifiableList = [...listToRecurse];

  /// Tracks if the loop managed to modify the desired value.
  var didFindAndModify = false;

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
          message:
              '''Cannot append new values at "$valueInList". You need to overwrite this value as it is nested in a list.''',
        );
      }

      // We convert to map
      final mapForString = <dynamic, dynamic>{}.recursivelyUpdate(
        update,
        target: target,
        path: currentPath,
        updateMode: updateMode,
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
      );

      // Mark as modified
      didFindAndModify = true;
    }

    // Call itself till we find key needed
    else if (valueInList is List) {
      final recursedList = _recurseNestedList(
        valueInList,
        update: update,
        target: target,
        currentPath: currentPath,
        updateMode: updateMode,
      );

      if (!recursedList.didModify) continue;

      modifiableList[index] = recursedList.modified;

      didFindAndModify = true;
    }

    // Break this loop if was modified
    if (didFindAndModify) break;
  }

  return (
    didModify: didFindAndModify,
    modified: didFindAndModify ? modifiableList : [],
  );
}
