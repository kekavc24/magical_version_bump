import 'package:yaml/yaml.dart';

/// Get version from file
String getYamlValue(String file, String node) {
  final yamlMap = loadYaml(file) as YamlMap;

  return yamlMap[node] as String;
}
