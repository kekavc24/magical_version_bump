import 'dart:io';

import 'package:magical_version_bump/src/utils/models/magical_data_model.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

/// This mixin reads and updates the yaml file
mixin HandleFile {
  /// Read yaml file from path. If:
  ///   1. [requestPath] is true. The user will be prompted for the path-to-file
  ///   2. [requestPath] is false. Will assume its the current directory and
  ///      load using relative path.
  ///
  /// Returns the path and YAML map
  ///
  /// Note: Must provide also yaml file in path incase the file name has been
  /// changed.
  Future<YamlFileData> readFile({
   bool requestPath = false,
    required Logger logger,
  }) async {
    var path = ''; // path to file

    if (requestPath) {
      // Request path to file
      path = logger.prompt(
        'Please enter the path to file:',
        defaultValue: 'pubspec.yaml',
      );
    } else {
      path = 'pubspec.yaml';
    }

    final readProgress = logger.progress('Reading file');

    // Read file
    final file = await File(path).readAsString();

    final yamlMap = _convertToMap(file);

    readProgress.complete('Read file');

    return YamlFileData(path: path, file: file, yamlMap: yamlMap);
  }

  /// Save file changes
  Future<void> saveFile({
    required String data,
    required String path,
    required Logger logger,
  }) async {
    final saveProgress = logger.progress('Saving changes');

    await File(path).writeAsString(data);

    saveProgress.complete('Saved changes');
  }

  /// Convert read file to YAML map
  YamlMap _convertToMap(String file) => loadYaml(file) as YamlMap;
}
