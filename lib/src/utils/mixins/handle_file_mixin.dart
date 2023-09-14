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
  Future<
      ({
        String file,
        FileType fileType,
        String path,
        String? version,
      })> readFile({
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

    // Convert file to map
    final fileAsMap = _convertToMap(file);

    readProgress.complete('Read file');

    return (
      path: setPath,
      fileType: setPath.split('.').last.toLowerCase().fileType,
      file: file,
      version: fileAsMap['version'] as String?,
    );
  }

  /// Save file changes
  Future<void> saveFile({
    required String file,
    required String path,
    required Logger logger,
    required FileType type,
  }) async {
    final saveProgress = logger.progress('Saving changes');

    if (type == FileType.json) {
      file = _convertToPrettyJson(file);
    }

    await File(path).writeAsString(file);

    saveProgress.complete('Saved changes');
  }

  /// Convert read file to YAML map
  YamlMap _convertToMap(String file) => loadYaml(file) as YamlMap;

  /// Convert to pretty json
  String _convertToPrettyJson(String file) {
    final indent = ' ' * 4;
    final encoder = JsonEncoder.withIndent(indent);

    return encoder.convert(_convertToMap(file));
  }
}
