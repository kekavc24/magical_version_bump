part of 'helpers.dart';

/// Read nested nodes
Future<dynamic> readNestedNodes(String? file, List<String> path) async {
  final yamlMap = loadYaml(
    file ?? await File(getTestFile()).readAsString(),
  ) as YamlMap;

  final depth = path.length - 1;
  final modifiedPath = [...path];
  final target = modifiedPath.removeAt(depth);

  return yamlMap.recursiveRead(
    path: modifiedPath,
    target: target,
  );
}
