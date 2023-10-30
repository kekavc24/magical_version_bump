import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

class FileHandler {
  FileHandler._(this._requestPath);

  /// Create a file handler based on arguments
  factory FileHandler.fromParsedArgs(ArgResults? argResults, Logger logger) {
    _logger = logger;
    final pathInfo = argResults!.pathInfo;
    final handler = FileHandler._(pathInfo.requestPath);

    // Just set path if user doesn't want prompts
    if (!pathInfo.requestPath) {
      handler.path = pathInfo.path;
    }

    return handler;
  }

  /// File type
  late FileType _fileType;

  /// Path where file is stored
  late String path;

  /// Whether to use path from args/request path
  final bool _requestPath;

  /// Logger for interacting with Command line
  static late Logger _logger;

  /// Read file and return as yaml map
  Future<YamlMap> readFile() async {
    if (_requestPath) {
      // Request path to file
      path = _logger.prompt(
        'Please enter the path to file:',
        defaultValue: 'pubspec.yaml',
      );
    }

    // Update file type
    _fileType = path.split('.').last.toLowerCase().fileType;

    final readProgress = _logger.progress('Reading file');
    final file = await File(path).readAsString();

    readProgress.complete('Read file');

    return _convertToMap(file);
  }

  /// Save file
  Future<void> saveFile(YamlMap updatedYaml) async {
    final saveProgress = _logger.progress('Saving changes');

    final file = _convertMapToString(
      updatedYaml,
      addIndent: _fileType == FileType.json,
    );

    await File(path).writeAsString(file);

    return saveProgress.complete('Saved changes');
  }

  /// Convert read file to YAML map
  YamlMap _convertToMap(String file) => loadYaml(file) as YamlMap;

  /// Convert to pretty json/yaml string
  String _convertMapToString(YamlMap yamlMap, {required bool addIndent}) {
    // Normal yaml files
    if (!addIndent) return json.encode(yamlMap);

    // For json files add indent
    final indent = ' ' * 4;
    final encoder = JsonEncoder.withIndent(indent);

    return encoder.convert(yamlMap);
  }
}
