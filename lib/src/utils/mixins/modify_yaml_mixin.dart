import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
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

    final recursiveOutput = recursiveUpdate(
      depth: depth,
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
      rootKeys: rootKeys,
      targetKey: targetKey,
      data: dictionary.data,
      output: recursiveOutput,
    );

    editor.update(
      formattedOutput.path,
      formattedOutput.dataToSave,
    );
    return editor.toString();
  }

  /// Read & update yaml map recursively
  RecursiveOutput recursiveUpdate({
    required int depth,
    required List<String> keys,
    required YamlMap yamlMap,
    required String targetKey,
    required dynamic update,
    required bool append,
  }) {
    /// Base condition
    if (depth == 0) {
      // Must be in map
      if (!yamlMap.containsKey(targetKey)) {
        return (
          failed: false,
          failedReason: null,
          finalDepth: depth,
          updatedValue: null,
        );
      }

      final recursiveOutput = <String, dynamic>{targetKey: null};
      dynamic valueToAppend;

      final targetKeyValue = yamlMap[targetKey];
      final targetValIsNull = targetKeyValue.runtimeType.toString() == 'null';

      if (append && targetValIsNull || !append) {
        valueToAppend = update is String && !append
            ? update
            : update is String && append
                ? <String>[update]
                : update is List<String>
                    ? <String>[...update]
                    : update as Map<String, String>;

        recursiveOutput.update(targetKey, (value) => valueToAppend);

        return (
          failed: false,
          failedReason: null,
          finalDepth: 0,
          updatedValue: recursiveOutput,
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

        recursiveOutput.update(targetKey, (value) => valueToAppend);
      } else if (targetKeyValue is YamlList) {
        valueToAppend = update is String
            ? [...targetKeyValue, update]
            : [...targetKeyValue, ...update as List<String>];

        recursiveOutput.update(targetKey, (value) => valueToAppend);
      } else {
        valueToAppend = <dynamic, dynamic>{}
          ..addAll(targetKeyValue as YamlMap)
          ..addAll(update as Map<String, String>);

        recursiveOutput.update(targetKey, (value) => valueToAppend);
      }

      return (
        failed: false,
        failedReason: null,
        finalDepth: 0,
        updatedValue: recursiveOutput,
      );
    }

    /// Another base condition that terminates at current stage if no such key
    /// is present
    final currentKey = keys.first;

    if (!yamlMap.containsKey(currentKey)) {
      return (
        failed: false,
        failedReason: null,
        finalDepth: depth,
        updatedValue: null,
      );
    }

    // Reduce depth, as the current is present
    final currentDepth = depth - 1;

    // Check if value is a yaml map
    final currentValue = yamlMap[currentKey];

    if (currentValue is YamlMap) {
      final retainedKeys = [...keys]..removeAt(0);

      return recursiveUpdate(
        depth: currentDepth,
        keys: retainedKeys,
        yamlMap: currentValue,
        targetKey: targetKey,
        update: update,
        append: append,
      );
    }

    final didFail = currentValue.runtimeType.toString() != 'null';

    /// Only return a failed status if user wanted to append and current
    /// value is not a map of other values.
    ///
    /// If append is false, indicates we need to overwrite any existing value
    return (
      failed: didFail && append,
      failedReason: didFail && append ? 'Cannot append at $currentKey' : null,
      finalDepth: didFail && append ? depth : currentDepth,
      updatedValue: null,
    );
  }

  /// Format recursive output
  ({List<String> path, Map<String, dynamic> dataToSave}) formatOutput({
    required List<String> rootKeys,
    required String targetKey,
    required dynamic data,
    required RecursiveOutput output,
  }) {
    final terminalDepth = output.finalDepth;

    /// In case recursive function managed to reach the end.
    ///
    /// * If data is null, means the final key doesn't exist and needs to be
    /// created.
    /// * Recursive function will update and return the target key with all
    /// its data if successful
    if (terminalDepth == 0) {
      return (
        path: rootKeys,
        dataToSave: output.updatedValue == null
            ? {targetKey: data}
            : output.updatedValue!,
      );
    }

    /// Data will always be null if the recursive function never reached the
    /// end.
    final depthDifference = rootKeys.length - output.finalDepth;

    final modifiableKeys = [...rootKeys];

    /// Means the root key is absent and we need to create the whole
    /// "tree" of values
    if (depthDifference == 0) {
      final anchorKey = modifiableKeys.removeAt(0);

      // In case no more keys are left, means target key is just 1 level deep
      if (modifiableKeys.isEmpty) {
        return (
          path: [anchorKey],
          dataToSave: {targetKey: data},
        );
      }

      final convertedMap = convertToDartMap(
        otherKeys: modifiableKeys,
        targetKey: targetKey,
        data: data,
      );

      return (
        path: [anchorKey],
        dataToSave: convertedMap,
      );
    }

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
      otherKeys: otherKeys,
      targetKey: targetKey,
      data: data,
    );

    return (
      path: pathKeys,
      dataToSave: pathData,
    );
  }

  /// Convert to map
  Map<String, dynamic> convertToDartMap({
    required List<String> otherKeys,
    required String targetKey,
    required dynamic data,
  }) {
    var map = <String, dynamic>{};

    if (otherKeys.isEmpty) {
      map.addAll({targetKey: data});
      return map;
    }

    for (final (index, value) in otherKeys.reversed.indexed) {
      if (index == 0) {
        map.addAll({
          value: {targetKey: data},
        });
      } else {
        map = {
          value: {...map},
        };
      }
    }

    return map;
  }
}
