import 'dart:convert';
import 'dart:io';

import 'package:magical_version_bump/src/core/enums/enums.dart';
import 'package:magical_version_bump/src/core/extensions/extensions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

/// This mixin reads and updates the yaml file
mixin HandleFile {
  /// Read yaml file from path. If:
  ///   * `requestPath` is true. The user will be prompted for the path-to-file
  ///   * `requestPath` is false. Will check `setPath` before checking
  ///      current directory
  ///
  Future<({String file, FileType type, String path, YamlMap yamlMap})>
      readFile({
    required Logger logger,
    required bool requestPath,
    String? setPath,
  }) async {
    var path = ''; // path to file

    if (requestPath) {
      // Request path to file
      path = logger.prompt(
        'Please enter the path to file:',
        defaultValue: 'pubspec.yaml',
      );
    } else {
      path = setPath ?? 'pubspec.yaml';
    }

    final readProgress = logger.progress('Reading file');

    // Read file
    final file = await File(path).readAsString();

    final yamlMap = _convertToMap(file);

    readProgress.complete('Read file');

    return (
      path: path,
      type: path.split('.').last.toLowerCase().fileType,
      file: file,
      yamlMap: yamlMap,
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
