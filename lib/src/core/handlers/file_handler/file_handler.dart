import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

class FileHandler {
  FileHandler();

  /// Create a file handler based on arguments
  factory FileHandler.fromParsedArgs(ArgResults? argResults, Logger logger) {
    final pathInfo = argResults!.pathInfo;
    final handler = FileHandler()
      ..requestPath = pathInfo.requestPath
      ..fileLogger = logger;

    // Just set path if user doesn't want prompts
    if (!pathInfo.requestPath) {
      handler.path = pathInfo.path;
    }

    return handler;
  }

  /// File type
  @protected
  late FileType fileType;

  /// Path where file is stored
  @protected
  late String path;

  /// Whether to use path from args/request path
  @protected
  late bool requestPath;

  /// Logger for interacting with Command line
  @protected
  late Logger fileLogger;

  /// Read file and return as yaml map
  Future<YamlMap> readFile() async {
    if (requestPath) {
      // Request path to file
      path = fileLogger.prompt(
        'Please enter the path to file:',
        defaultValue: 'pubspec.yaml',
      );
    }

    // Update file type
    fileType = path.split('.').last.toLowerCase().fileType;

    final readProgress = fileLogger.progress('Reading file');
    final file = await File(path).readAsString();

    readProgress.complete('Read file');

    return _convertToMap(file);
  }

  /// Save file
  Future<void> saveFile(YamlMap updatedYaml) async {
    final saveProgress = fileLogger.progress('Saving changes');

    final file = _convertMapToString(
      updatedYaml,
      addIndent: fileType == FileType.json,
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
