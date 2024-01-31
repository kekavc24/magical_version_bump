import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

part 'file_handler_util.dart';

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
      handler.files = getFileTypes(pathInfo.paths);
    }

    return handler;
  }

  /// Whether to use path from args/request path
  late bool requestPath;

  /// File paths and their file types
  late Map<String, FileType> files;

  List<String> get filePaths => files.keys.toList();

  /// Logger for interacting with Command line
  late Logger fileLogger;

  /// Read first file only. Used by handlers for commands that read from a
  /// single directory.
  Future<FileOutput> readFile() async {
    final outputs = await readAll();
    return outputs.first;
  }

  /// Read multiple files provided by user. If not provided, requests them.
  ///
  /// `SingleDirectoryCommand`s should use [readFile] as it
  /// returns just one file.
  ///
  Future<List<FileOutput>> readAll({bool multiple = false}) async {
    // Get file paths
    final paths =
        requestPath ? requestPaths(multiple: multiple) : files.keys.toList();

    // Update file type
    final outputs = <FileOutput>[];

    final readProgress = fileLogger.progress(
      "Reading ${multiple ? 'files' : 'file'}",
    );

    // Start reading all files
    for (final path in paths) {
      final file = await File(path).readAsString();
      final output = (file: file, fileAsMap: convertToMap(file));
      outputs.add(output);
    }

    // Set file and their types if not initially set
    if (requestPath) files = getFileTypes(paths);

    readProgress.complete('Read files');
    return outputs;
  }

  /// Save file.
  Future<void> saveFile(
    String modifiedFile, {
    int index = 0,
    bool showProgress = true,
  }) async {
    Progress? saveProgress;

    if (showProgress) saveProgress = fileLogger.progress('Saving changes');

    // File path details
    final fileDetails = files.entries.elementAt(index);

    final fileTosave = fileDetails.value == FileType.json
        ? _convertMapToString(modifiedFile)
        : modifiedFile;

    await File(fileDetails.key).writeAsString(fileTosave);

    return saveProgress?.complete('Saved changes');
  }

  /// Save multiple files.
  ///
  /// NOTE: The order of altered files must match order of their request. All
  /// file outputs must order of file requests/paths provided.
  Future<void> saveAll(List<String> modifiedFiles) async {
    // Loop all
    for (final (index, modifiedFile) in modifiedFiles.indexed) {
      await saveFile(modifiedFile, index: index);
    }
  }

  /// Convert read file to YAML map
  YamlMap convertToMap(String file) => loadYaml(file) as YamlMap;

  /// Convert to pretty json/yaml string
  String _convertMapToString(String file) {
    // Convert to yaml
    final yamlMap = convertToMap(file);

    // For json files add indent
    final indent = ' ' * 4;
    final encoder = JsonEncoder.withIndent(indent);

    return encoder.convert(yamlMap);
  }

  /// Request file paths from user
  @protected
  List<String> requestPaths({required bool multiple}) {
    // Request input from user
    final request = multiple
        ? 'Please enter all paths to files (use comma to separate): '
        : 'Please enter the path to file: ';

    final userInput = fileLogger.prompt(
      request,
      defaultValue: 'pubspec.yaml',
    );

    // Return lists of path
    return multiple
        ? userInput.splitAndTrim(',').retainNonEmpty()
        : [userInput];
  }
}
