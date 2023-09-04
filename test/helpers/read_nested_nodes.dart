part of 'helpers.dart';

/// Read nested nodes
dynamic readNestedNodes(String file, List<String> path) {
  final yamlMap = loadYaml(file) as YamlMap;

  final depth = path.length - 1;
  final modifiedPath = [...path];
  final target = modifiedPath.removeAt(depth);

  return yamlMap.recursiveRead(
    path: modifiedPath,
    target: target,
  );
}
