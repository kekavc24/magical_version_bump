part of 'helpers.dart';

/// Read nested nodes
dynamic readNestedNodes(String file, List<String> path) {
  final yamlMap = loadYaml(file) as YamlMap;

  final depth = path.length - 1;
  final modifiedPath = [...path];
  final target = modifiedPath.removeAt(depth);

  return recursiveRead(yamlMap, depth, modifiedPath, target);
}

dynamic recursiveRead(
  YamlMap yamlMap,
  int depth,
  List<String> path,
  String target,
) {
  if (depth == 0) {
    return yamlMap[target];
  }
  final currentKey = path.first;

  if (!yamlMap.containsKey(currentKey)) return null;

  final currentValue = yamlMap[currentKey];

  if (currentValue is! YamlMap) return null;

  final modifiedPath = [...path]..removeAt(0);
  final currentDepth = depth - 1;
  return recursiveRead(currentValue, currentDepth, modifiedPath, target);
}
