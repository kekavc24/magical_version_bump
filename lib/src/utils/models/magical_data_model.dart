import 'package:yaml/yaml.dart';

/// Base class for all data objects generated in various mixins.
abstract class MagicalData {}

/// This class stores data from processed YAML file.
class YamlFileData extends MagicalData {
  YamlFileData({
    required this.path,
    required this.file,
    required this.yamlMap,
  });

  /// Path to file.
  final String path;

  /// File as a string
  final String file;

  /// Data read from file as YAML map.
  final YamlMap yamlMap;
}

/// This class stores data after all arguments have been read
class PrepCommandData extends MagicalData {
  PrepCommandData({
    required this.absoluteVersioning,
    required this.action,
    required this.versionTargets,
    required this.requestPath,
  });

  /// Whether version will be bumped up/down independent to other versions
  final bool absoluteVersioning;

  /// Current action user want to pursue
  final String action;

  /// List of version targets.
  final List<String> versionTargets;

  /// Whether user indicated they want a custom path
  final bool requestPath;
}

class ModifiedFileData extends MagicalData {
  ModifiedFileData({
    required this.path,
    required this.modifiedFile,
  });

  /// Path to file
  final String path;

  /// Modified file as string
  final String modifiedFile;
}
