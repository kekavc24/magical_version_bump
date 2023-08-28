part of 'helpers.dart';

/// Get version from file
String getNodeValue(String file, String node) {
  final yamlMap = loadYaml(file) as YamlMap;

  return yamlMap[node] as String;
}
