part of 'helpers.dart';

/// Read nested nodes
Future<T?> readNestedNodes<T>(String? file, List<String> path) async {
  final yamlMap = loadYaml(
    file ?? await File(getTestFile()).readAsString(),
  ) as YamlMap;

  final depth = path.length - 1;
  final modifiedPath = [...path];
  final target = modifiedPath.removeAt(depth);

  return yamlMap.recursiveRead<T>(
    path: modifiedPath,
    target: target,
  );
}
