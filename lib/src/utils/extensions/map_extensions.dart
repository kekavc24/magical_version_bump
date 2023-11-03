import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';

/// Extension to help read nested values
extension MapUtility on Map<dynamic, dynamic> {
  /// Read nested values recursively
  T? recursiveRead<T>({
    required List<dynamic> path,
    required dynamic target,
  }) {
    if (path.isEmpty) {
      return this[target] as T?;
    }
    final currentKey = path.first;

    if (!containsKey(currentKey)) return null;

    final currentValue = this[currentKey];

    if (currentValue is String) return null;

    final modifiedPath = [...path]..removeAt(0);

    if (currentValue is List) {
      return _NestedMapHelper.readNestedList(
        currentValue,
        target: target,
        path: modifiedPath,
      );
    }

    return (currentValue as Map<dynamic, dynamic>).recursiveRead(
      path: modifiedPath,
      target: target,
    ) as T?;
  }

  /// Recursively update a [target] key specified based on the [path] of
  /// preceding keys.
  ///
  /// `append` is boolean which specifies whether to add to existing values if
  /// `true` or overwriting any existing values if `false`.
  ///
  /// `update` is dynamic and allows any data type support by `Dart`. With
  /// this package, the value will either be a `String`, `List<String>` or
  /// `Map<String, String>`
  ///
  Map<dynamic, dynamic> recursivelyUpdate(
    dynamic update, {
    required String target,
    required List<String> path,
    required bool append,
  }) {
    // Base condition for our function
    if (path.isEmpty) {
      // Read current value at the end
      final targetKeyValue = this[target];
      final targetValIsNull = targetKeyValue == null;

      if (append && targetValIsNull || !append) {
        final directUpdate = update is String && !append
            ? update
            : update is String && append
                ? <String>[update]
                : update is List<String>
                    ? <String>[...update]
                    : update as Map<String, String>;

        this.update(
          target,
          (value) => directUpdate,
          ifAbsent: () => directUpdate,
        );

        return this;
      }

      // Due to many checks
      dynamic valueToAppend;

      // Convert to list by default since only a single value exists
      if (targetKeyValue is String) {
        valueToAppend = update is List
            ? <dynamic>[targetKeyValue, ...update]
            : <dynamic>[targetKeyValue, update];
      }

      // For List, just spread in old values
      else if (targetKeyValue is List) {
        valueToAppend = update is List
            ? [...targetKeyValue, ...update]
            : [...targetKeyValue, update];
      }

      // For maps, anything that is not a map forces it to be list
      else {
        if (update is Map) {
          valueToAppend = <dynamic, dynamic>{}
            ..addAll(targetKeyValue as Map)
            ..addAll(update as Map<String, String>);
        } else {
          valueToAppend = update is String
              ? <dynamic>[targetKeyValue, update]
              : <dynamic>[targetKeyValue, ...update as List];
        }
      }

      this.update(target, (value) => valueToAppend);

      return this;
    }

    /// If path is not empty, just read the next key in sequence and do
    /// another update recursively!
    final currentKey = path.first;

    final valueAtKey = this[currentKey];

    /// Since we have not exhausted all keys in this path, the value must
    /// either be a `Map<dynamic, dynamic>` or `null` or `append` is false
    ///
    /// For `null`, we will create missing key as this was a guarantee for
    /// updating the yaml file, a guaranteed fallback.
    ///
    /// However, if `append` is `false`, means we are overwriting the whole
    /// path.
    if (valueAtKey != null && valueAtKey is String && append) {
      throw MagicalException(
        violation:
            '''Cannot append new values due to an existing value at "$currentKey". You need to overwrite this path key.''',
      );
    }

    // Update path, as this key will be updated
    final updatedPath = [...path]..removeAt(0);

    /// If value is `null` OR `append` is false
    if (valueAtKey == null) {
      this[currentKey] = <dynamic, dynamic>{}.recursivelyUpdate(
        update,
        target: target,
        path: updatedPath,
        append: append,
      );

      return this;
    }

    ///
    /// As earlier stated, we guarantee that a missing key will always be
    /// recreated. Thus:
    ///
    /// * If a String is encountered, we force it into a list and iterate it.
    ///   and create the key if missing
    /// * If value is a list, we iterate and look for our key
    if (valueAtKey is List || valueAtKey is String) {
      final modifiableValueAtKey = valueAtKey is String
          ? <dynamic>[valueAtKey]
          : <dynamic>[...valueAtKey as List];

      // Recursive read all values of list
      final recursedOutput = _NestedMapHelper.recurseNestedList(
        modifiableValueAtKey,
        update: update,
        target: target,
        currentPath: updatedPath,
        append: append,
      );

      ///
      /// If after recursing it wasn't modified, we add the wanted key as a
      /// null map, which guarantees further recursions will update it.
      ///
      /// Thus, guarantee-ing our guarantee of creating any missing keys we
      /// find missing while recursing
      ///
      if (!recursedOutput.didModify) {
        final wantedKeyUpdate = <dynamic, dynamic>{}.recursivelyUpdate(
          update,
          target: target,
          path: updatedPath,
          append: append,
        );

        modifiableValueAtKey.add(wantedKeyUpdate);
      } else {
        modifiableValueAtKey
          ..clear()
          ..addAll(recursedOutput.modified);
      }

      this[currentKey] = modifiableValueAtKey;

      return this;
    }

    // Current value as is from map
    final castedValueAtKey = <dynamic, dynamic>{
      ...valueAtKey as Map<dynamic, dynamic>,
    };

    this[currentKey] = castedValueAtKey.recursivelyUpdate(
      update,
      target: target,
      path: updatedPath,
      append: append,
    );

    return this;
  }
}

/// Recursive Functions for lists nested in maps. This class is for useful for
/// this extension
class _NestedMapHelper {
  ///
  /// Function for solely reading keys nested in lists
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

      // For maps check if value matches
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
  /// Function solely for recursing the nested list in map. Not to be
  /// used outside this extension.
  static ({bool didModify, List<dynamic> modified}) recurseNestedList(
    List<dynamic> listToRecurse, {
    required dynamic update,
    required String target,
    required List<String> currentPath,
    required bool append,
  }) {
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

    // We first make list modifiable
    final modifiableList = [...listToRecurse];

    /// If the loop, managed to modify the desired value.
    var didFindAndModify = false;

    // Loop it value by value
    for (final (index, valueInList) in modifiableList.indexed) {
      // For strings, only matching values
      if (valueInList is String && valueInList == wantedKey) {
        // We cannot append, only overwrite
        if (append) {
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
          append: append,
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
          append: append,
        );

        // Mark as modified
        didFindAndModify = true;
      }

      // Call itself till we find key needed
      else {
        final recursedList = recurseNestedList(
          valueInList as List,
          update: update,
          target: target,
          currentPath: currentPath,
          append: append,
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
}
