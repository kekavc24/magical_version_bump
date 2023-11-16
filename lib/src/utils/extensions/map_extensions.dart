import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';

part 'helpers/map_extension/recursive_helper.dart';
part 'helpers/map_extension/recursive_data_mod_helper.dart';

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
      return RecursiveHelper.readNestedList(
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
  /// this map.
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
    required KeyAndReplacement keyAndReplacement,
    required String? valueToReplace,
  }) {
    // Base condition for our recursive function on reaching end.
    if (path.isEmpty) {
      // Just in case this target key needs to be updated
      final terminalMap = RecursiveDataHelper.getMap(
        updateMode: updateMode,
        current: target,
        replacement: keyAndReplacement[target],
        currentMap: this,
      );

      // If we are in replace mode and no value was pass as replacement
      if (updateMode == UpdateMode.replace && valueToReplace == null) {
        return terminalMap;
      }

      // Now key at root may have changed
      final keyAtRootEnd = RecursiveDataHelper.getKey(
        updateMode: updateMode,
        current: target,
        replacement: keyAndReplacement[target],
      );

      // Read current value at the end
      final targetKeyValue = terminalMap[keyAtRootEnd];

      final updatedTerminal = RecursiveDataHelper.updateTerminalValue(
        updateMode: updateMode,
        update: update,
        currentValue: targetKeyValue,
        valueToReplace: valueToReplace,
      );

      // Value to set
      final terminalValueToSet = updatedTerminal is RecursiveListOutput
          ? updatedTerminal.modified
          : updatedTerminal;

      terminalMap.update(
        keyAtRootEnd,
        (value) => terminalValueToSet,
        ifAbsent: () => terminalValueToSet,
      );
      return terminalMap;
    }

    /// If path is not empty, just read the next key in sequence and do
    /// another update recursively!
    final candidateKey = path.first;

    /// Try swapping if in update mode
    final currentKey = RecursiveDataHelper.getKey(
      updateMode: updateMode,
      current: candidateKey,
      replacement: keyAndReplacement[candidateKey],
    );

    // Get map based on update mode
    final recursableMap = RecursiveDataHelper.getMap(
      updateMode: updateMode,
      current: candidateKey,
      replacement: keyAndReplacement[candidateKey],
      currentMap: this,
    );

    // Read current value
    final valueAtKey = recursableMap[currentKey];

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
      recursableMap[currentKey] = <dynamic, dynamic>{}.recursivelyUpdate(
        update,
        target: target,
        path: updatedPath,
        updateMode: updateMode,
        keyAndReplacement: keyAndReplacement,
        valueToReplace: valueToReplace,
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
      final recursedOutput = RecursiveHelper.recurseNestedList(
        modifiableValueAtKey,
        update: update,
        target: target,
        currentPath: updatedPath,
        updateMode: updateMode,
        keyAndReplacement: keyAndReplacement,
        valueToReplace: valueToReplace,
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
          keyAndReplacement: keyAndReplacement,
          valueToReplace: valueToReplace,
        );

        modifiableValueAtKey.add(wantedKeyUpdate);
      } else {
        modifiableValueAtKey
          ..clear()
          ..addAll(recursedOutput.modified);
      }

      recursableMap[currentKey] = modifiableValueAtKey;

      return recursableMap;
    }

    // Current value as is from map
    final castedValueAtKey = <dynamic, dynamic>{
      ...valueAtKey as Map<dynamic, dynamic>,
    };

    recursableMap[currentKey] = castedValueAtKey.recursivelyUpdate(
      update,
      target: target,
      path: updatedPath,
      updateMode: updateMode,
      keyAndReplacement: keyAndReplacement,
      valueToReplace: valueToReplace,
    );

    return recursableMap;
  }
}
