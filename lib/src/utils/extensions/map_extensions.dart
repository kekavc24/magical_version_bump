import 'package:magical_version_bump/src/core/yaml_transformers/data/pair_definition/pair_definition.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';

part 'helpers/map_extension/recursive_helper.dart';
part 'helpers/map_extension/recursive_data_mod_helper.dart';
part 'helpers/map_extension/predetermined_updates.dart';

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
      return _readNestedList(
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
  /// `UpdateMode` specifies mode to use while recursively updating
  /// this map. Only `UpdateMode.append` && `UpdateMode.overwrite`
  ///
  /// `update` is dynamic and allows any data type support by `Dart`. With
  /// this package, the value will either be a `String`, `List<String>` or
  /// `Map<String, String>`
  ///
  Map<dynamic, dynamic> recursivelyUpdate(
    dynamic update, {
    required String target,
    required List<String> path,
    required UpdateMode updateMode,
  }) {
    // Throw error if replace
    if (updateMode == UpdateMode.replace) {
      throw MagicalException(
        violation:
            '''This update mode is not supported. Use the "updateIndexedMap()" method instead''',
      );
    }

    // Base condition for our recursive function on reaching end.
    if (path.isEmpty) {
      // Read current value at the end
      final targetKeyValue = this[target];

      final updatedTerminal = _updateTerminalValue(
        updateMode: updateMode,
        update: update,
        currentValue: targetKeyValue,
      );

      // Value to set
      final terminalValueToSet = updatedTerminal is RecursiveListOutput
          ? updatedTerminal.modified
          : updatedTerminal;

      this.update(
        target,
        (value) => terminalValueToSet,
        ifAbsent: () => terminalValueToSet,
      );
      return this;
    }

    /// If path is not empty, just read the next key in sequence and do
    /// another update recursively!
    final currentKey = path.first;

    // Read current value
    final valueAtKey = this[currentKey];

    ///
    /// All [ UpdateMode ]s require the next section.
    ///

    ///
    /// Since we have not exhausted all keys in this path, the value must
    /// either be a:
    ///   * `Map<dynamic, dynamic>`. For `UpdateMode.replace`, this is a
    ///      guarantee as we previously indexed this map.
    ///   * `null` value or `UpdateMode.overwrite`.
    ///
    /// For `null`, we will create missing key as this was a guarantee for
    /// updating the yaml file.
    ///
    /// Thus, a value can never be a string if not at terminal end and
    /// in `UpdateMode.append`. A key must exist!
    if (valueAtKey != null &&
        valueAtKey is String &&
        updateMode == UpdateMode.append) {
      throw MagicalException(
        violation:
            '''Cannot append new values due to an existing value at "$currentKey". You need to overwrite this path key.''',
      );
    }

    // Update path, as this key will be updated
    final updatedPath = [...path]..removeAt(0);

    /// If value is `null`, we recreate the missing keys
    if (valueAtKey == null) {
      this[currentKey] = <dynamic, dynamic>{}.recursivelyUpdate(
        update,
        target: target,
        path: updatedPath,
        updateMode: updateMode,
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
      final recursedOutput = _recurseNestedList(
        modifiableValueAtKey,
        update: update,
        target: target,
        currentPath: updatedPath,
        updateMode: updateMode,
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
          updateMode: updateMode,
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
      updateMode: updateMode,
    );

    return this;
  }

  /// Recurse a known map and update values or swap keys
  Map<dynamic, dynamic> updateIndexedMap(
    dynamic update, {
    required Key target,
    required List<Key> path,
    required KeyAndReplacement keyAndReplacement,
    required Value? value,
  }) {
    ///
    if (path.isEmpty) {
      return _updateIndexedTerminal(
        update,
        target: target,
        keyAndReplacement: keyAndReplacement,
        value: value,
      );
    }

    /// Current key.
    ///
    /// This will always be called on a map, not a list thus we won't
    /// need to recurse list
    final keyFromPath = path.first.value!;

    // Attempt a swap. If replacement is null, no swap.
    final attemptedSwap = _attemptSwap(
      currentKey: keyFromPath,
      replacement: keyAndReplacement[keyFromPath],
      currentMap: this,
    );

    final currentKey = attemptedSwap.key; // Key to used by default
    final recursableMap = attemptedSwap.map; // Map

    // Read value at key
    final valueAtKey = recursableMap[currentKey];

    // Update path
    final updatedPath = [...path]..removeAt(0);

    /// If list, we get the next Key with indices
    if (valueAtKey is List) {
      final nextKey = updatedPath.firstOrNull ?? target;

      recursableMap[currentKey] = _updateIndexedList(
        isTerminal: updatedPath.isEmpty,
        isKey: true,
        list: valueAtKey,
        indices: nextKey.indices,
        update: update,
        target: target,
        path: updatedPath,
        keyAndReplacement: keyAndReplacement,
        value: value,
      );

      return recursableMap;
    }

    // Current value as is from map
    final castedValueAtKey = <dynamic, dynamic>{
      ...valueAtKey as Map<dynamic, dynamic>,
    };

    recursableMap[currentKey] = castedValueAtKey.updateIndexedMap(
      update,
      target: target,
      path: updatedPath,
      keyAndReplacement: keyAndReplacement,
      value: value,
    );

    return recursableMap;
  }

  Map<dynamic, dynamic> _updateIndexedTerminal(
    dynamic update, {
    required Key target,
    required KeyAndReplacement keyAndReplacement,
    required Value? value,
  }) {
    final candidate = target.value!; // Key that may change

    // Attempt a swap to have latest version of this map
    final attemptedSwap = _attemptSwap(
      currentKey: candidate,
      replacement: keyAndReplacement[candidate],
      currentMap: this,
    );

    // No need to update value if none was used as replacement
    if (value == null) return attemptedSwap.map;

    // Get key and map
    final keyAtRoot = attemptedSwap.key;
    final terminalMap = attemptedSwap.map;

    final valueAtRoot = terminalMap[keyAtRoot];

    dynamic valueToSet; // Value to set

    // If list update it as it was indexed before
    if (valueAtRoot is List) {
      valueToSet = _updateIndexedList(
        isTerminal: true,
        isKey: false,
        list: valueAtRoot,
        indices: value.indices,
        update: update,
      );
    } else {
      valueToSet = update;
    }

    terminalMap.update(
      keyAtRoot,
      (value) => valueToSet,
      ifAbsent: () => valueToSet,
    );
    return terminalMap;
  }
}
