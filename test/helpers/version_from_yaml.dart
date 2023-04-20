import 'package:yaml/yaml.dart';

/// Get version from file
String getVersion(String file) {
  final yamlMap = loadYaml(file) as YamlMap;

  return yamlMap['version'] as String;
}
