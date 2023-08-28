import 'dart:convert';
import 'dart:io';

import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

/// This mixin reads and updates the yaml file
mixin HandleFile {
  /// Read yaml file from path. If:
  ///   * `requestPath` is true. The user will be prompted for the path-to-file
  ///   * `requestPath` is false. Uses default `setPath`
  ///
  Future<({String file, FileType type, String path, YamlMap yamlMap})>
      readFile({
    required bool requestPath,
    required Logger logger,
    required String setPath,
  }) async {
    if (requestPath) {
      // Request path to file
      setPath = logger.prompt(
        'Please enter the path to file:',
        defaultValue: 'pubspec.yaml',
      );
    }

    final readProgress = logger.progress('Reading file');
    final file = await File(setPath).readAsString();
    readProgress.complete('Read file');

    return (
      path: setPath,
      type: setPath.split('.').last.toLowerCase().fileType,
      file: file,
      yamlMap: _convertToMap(file),
    );
  }

  /// Save file changes
  Future<void> saveFile({
    required String data,
    required String path,
    required Logger logger,
    required FileType type,
  }) async {
    final saveProgress = logger.progress('Saving changes');

    if (type == FileType.json) {
      data = json.encode(_convertToMap(data));
    }

    await File(path).writeAsString(data);

    saveProgress.complete('Saved changes');
  }

  /// Convert read file to YAML map
  YamlMap _convertToMap(String file) => loadYaml(file) as YamlMap;
}
