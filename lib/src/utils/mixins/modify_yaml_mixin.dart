import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:magical_version_bump/src/utils/extensions/map_extensions.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// This mixin modifies a yaml node to desired option
mixin ModifyYaml {
  /// Bump version by 1. Used by the `Bump` subcommand.
  ///
  /// With absolute,
  /// each version number will be bumped independently.
  ///
  /// 1.1.1 -> bump major version -> 2.1.1
  ///
  /// With relative,
  /// each version is modified relative to its position. This the default
  /// behaviour i.e
  ///
  /// 1.1.1 -> bump major version -> 2.0.0
  Future<({bool buildHadIssues, String version})> dynamicBump(
    String version, {
    required List<String> versionTargets,
    required ModifyStrategy strategy,
  }) async {
    return Version.parse(version).modifyVersion(
      versionTargets: versionTargets,
      strategy: strategy,
    );
  }

  /// Edit yaml file
  Future<String> updateYamlFile(String file, Dictionary dictionary) async {
    // Setup editor
    final editor = YamlEditor(file);

    // Get keys to use in update
    final rootKeys = [...dictionary.rootKeys];

    /// To ensure efficiency, if:
    ///
    /// 1. Only one root key is present
    /// 2. Root is being overwritten
    ///
    /// Update and return updated file
    if (rootKeys.length == 1 && !dictionary.append) {
      editor.update([rootKeys.first], dictionary.data);

      return editor.toString();
    }

    // Convert file to required yaml map
    final fileAsYamlMap = loadYaml(file) as YamlMap;

    /// When more than 1 key is provided, we need to guarantee that:
    ///
    ///   1. Update to yaml file never fails due to a missing root key. If
    ///      absent, create the necessary missing nodes.
    ///   2. Update a node storing a string to list, if append is true
    ///   3. Never append a list to an existing map and vice versa
    ///   4. Never throw an error in our recursive function
    ///
    /// For this we need,
    ///   `depth` - how far deep the node is in yaml map, which is the number
    ///   of keys before the node we want to read
    ///
    final depth = rootKeys.length - 1;

    /// Remove the target key, which is the last element.
    ///
    /// * `removeAt` ensures we never remove duplicate keys which are nested!
    /// * `depth` indicates index of last element too
    /// * `targetKey` is the last element removed
    final targetKey = rootKeys.removeAt(depth);

    final recursiveOutput = updateNestedTarget(
      keys: rootKeys,
      yamlMap: fileAsYamlMap,
      targetKey: targetKey,
      update: dictionary.data,
      append: dictionary.append,
    );

    // If update failed, throw error
    if (recursiveOutput.failed) {
      throw MagicalException(
        violation: recursiveOutput.failedReason!,
      );
    }

    final formattedOutput = formatOutput(
      fileAsYamlMap,
      append: dictionary.append,
      rootKeys: rootKeys,
      output: recursiveOutput,
      fallbackData: {targetKey: dictionary.data},
    );

    editor.update(
      formattedOutput.path,
      formattedOutput.dataToSave,
    );

    return editor.toString();
  }

  ///
  NestedUpdate updateNestedTarget({
    required List<String> keys,
    required YamlMap yamlMap,
    required String targetKey,
    required dynamic update,
    required bool append,
  }) {
    final output = <String, dynamic>{targetKey: null};

    // Value to add to target
    dynamic valueToAppend;

    var tempOutput = <dynamic, dynamic>{}..addAll(yamlMap);

    /// Loop all keys reading values associated with them
    for (final (index, key) in keys.indexed) {
      final depth = keys.length - index;

      // Must have key
      if (!tempOutput.containsKey(key)) {
        return (
          failed: false,
          failedReason: null,
          finalDepth: depth == keys.length ? depth : depth + 1,
          updatedValue: null,
        );
      }

      final valueFromMap = tempOutput[key];

      /// Only return a failed status if user wanted to append and current
      /// value is not a map of other values.
      ///
      /// If append is false, indicates we need to overwrite any existing value
      if (valueFromMap is! Map<dynamic, dynamic>) {
        return (
          failed: valueFromMap != null && append,
          failedReason:
              valueFromMap != null && append ? 'Cannot append at $key' : null,
          finalDepth: valueFromMap != null && append && depth != keys.length
              ? (depth + 1)

              // If maybe value was null or not but we are not appending
              : !append
                  ? depth - 1
                  : depth,
          updatedValue: null,
        );
      }

      tempOutput = valueFromMap;
    }

    // Target must be in map
    if (!tempOutput.containsKey(targetKey)) {
      return (
        failed: false,
        failedReason: null,
        finalDepth: 0,
        updatedValue: null,
      );
    }

    final targetKeyValue = tempOutput[targetKey];
    final targetValIsNull = targetKeyValue == null;

    if (append && targetValIsNull || !append) {
      valueToAppend = update is String && !append
          ? update
          : update is String && append
              ? <String>[update]
              : update is List<String>
                  ? <String>[...update]
                  : update as Map<String, String>;

      output.update(targetKey, (value) => valueToAppend);

      return (
        failed: false,
        failedReason: null,
        finalDepth: 0,
        updatedValue: output,
      );
    }

    // Check for mismatch when target value is not null
    if ((targetKeyValue is String || targetKeyValue is YamlList) &&
        (update is! String && update is! List<String>)) {
      return (
        failed: true,
        failedReason: 'Cannot append new values at $targetKey',
        finalDepth: 0,
        updatedValue: null,
      );
    } else if (targetKeyValue is YamlMap && update is! Map<String, String>) {
      return (
        failed: true,
        failedReason: 'Cannot append new mapped values at $targetKey',
        finalDepth: 0,
        updatedValue: null,
      );
    }

    // Convert all strings to list of strings
    if (targetKeyValue is String) {
      valueToAppend = update is String
          ? <String>[targetKeyValue, update]
          : <String>[targetKeyValue, ...update as List<String>];

      output.update(targetKey, (value) => valueToAppend);
    } else if (targetKeyValue is YamlList) {
      valueToAppend = update is String
          ? [...targetKeyValue, update]
          : [...targetKeyValue, ...update as List<String>];

      output.update(targetKey, (value) => valueToAppend);
    } else {
      valueToAppend = <dynamic, dynamic>{}
        ..addAll(targetKeyValue as YamlMap)
        ..addAll(update as Map<String, String>);

      output.update(targetKey, (value) => valueToAppend);
    }

    return (
      failed: false,
      failedReason: null,
      finalDepth: 0,
      updatedValue: output,
    );
  }

  /// Format recursive output
  ({List<String> path, dynamic dataToSave}) formatOutput(
    YamlMap fileAsMap, {
    required bool append,
    required List<String> rootKeys,
    required NestedUpdate output,
    required Map<String, dynamic> fallbackData,
  }) {
    /// In case recursive function managed to reach the end.
    ///
    /// * If data is null, means the final key doesn't exist and needs to be
    /// created.
    /// * Recursive function will update and return the target key with all
    /// its data if successful
    ///
    /// * Data will always be null if the recursive function never reached the
    /// end.
    final depthDifference = rootKeys.length - output.finalDepth;

    final modifiableKeys = [...rootKeys];

    /// Account for the stopping point. Why?
    /// Consider, array [6 ,5 , 4] with decreaseing order where:
    ///   * `6 -> 3`
    ///   * `5 -> 2`
    ///   * `4 -> 1`
    ///
    /// Thus, first element's order = size of array. This decreases till the
    /// last element has 1.
    ///
    /// Imagine a cursor ran from start of array and stopped randomly at `5`.
    /// To obtain the number of elements it "transversed" including the
    /// stopping point,
    ///
    /// `Number of elements = (Start order - Order of stop) + 1`
    ///
    /// In our case, [depthDifference + 1]
    final unBiasedDiff = depthDifference + 1;

    /// To obtain the non-visited keys,
    ///
    /// 1. The `depthDifference` is the number of elements visited in the
    ///    list and are available as paths.
    /// 3. The `depthDifference` is also the number of elements we need to skip
    ///    to get all elements not visited
    final pathKeys = modifiableKeys.take(unBiasedDiff).toList();
    final otherKeys = modifiableKeys.skip(unBiasedDiff).toList();

    final pathData = convertToDartMap(
      fileAsMap,
      append: append,
      pathKeys: pathKeys,
      missingKeys: otherKeys,
      updatedData: output.updatedValue,
      fallbackData: fallbackData,
    );

    /// We "overwrite" old data with new. Why quotes? Since old data may be
    /// retained when append is true!
    ///
    /// If the anchor is the target, no pathkeys will be available. Get the key
    /// and data from the fallback data
    ///
    final anchorKey =
        pathKeys.isEmpty ? fallbackData.keys.first : pathKeys.first;

    return (
      path: [anchorKey],
      dataToSave: pathKeys.isNotEmpty
          ? pathData[anchorKey]
          : output.updatedValue == null
              ? fallbackData[anchorKey]
              : output.updatedValue![anchorKey],
    );
  }

  /// Convert to map
  Map<dynamic, dynamic> convertToDartMap(
    YamlMap fileAsMap, {
    required bool append,
    required List<String> pathKeys,
    required List<String> missingKeys,
    required Map<String, dynamic>? updatedData,
    required Map<String, dynamic> fallbackData,
  }) {
    var dataAsMap = <dynamic, dynamic>{};

    // Missing keys are not in map currently, need to be created
    if (missingKeys.isEmpty) {
      dataAsMap.addAll(updatedData ?? fallbackData);
    } else {
      for (final (index, value) in missingKeys.reversed.indexed) {
        if (index == 0) {
          dataAsMap.addAll({
            value: updatedData ?? fallbackData,
          });
        } else {
          dataAsMap = {
            value: {...dataAsMap},
          };
        }
      }
    }

    /// Path keys exist and we need to get all data. This prevents any data
    /// from being overwritten. Only the target key changes.

    if (pathKeys.isNotEmpty) {
      final pathsInReverse = pathKeys.reversed;

      // Loop all keys in reverse. Appending or adding data
      for (final (index, currentKey) in pathsInReverse.indexed) {
        ///
        /// The current index indicated number of elements to skip. Add 1 since
        /// we have to include the target key
        final numOfSkippable = index + 1;

        final pathsToTarget = pathsInReverse.skip(numOfSkippable);

        final keyData = fileAsMap.recursiveRead(
          path: pathsToTarget.toList(),
          target: currentKey,
        ) as Map<dynamic, dynamic>?;

        // Data to add
        final existingData = keyData == null || !append
            ? {currentKey: dataAsMap}
            : {
                currentKey: {
                  ...keyData,
                  ...dataAsMap,
                },
              };

        dataAsMap = {...existingData};
      }
    }

    return dataAsMap;
  }
}
