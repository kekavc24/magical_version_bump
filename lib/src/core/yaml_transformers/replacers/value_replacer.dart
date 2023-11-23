part of 'replacer.dart';

/// Exclusively replaces values
class MagicalReplacer extends Replacer {
  MagicalReplacer(List<ReplacementTargets> targets) : super(targets: targets);

  @override
  ValuesToFind getTargets() {
    return super.generateTargets<ValuesToFind>(areKeys: false);
  }

  @override
  YamlMap replace(
    YamlMap yamlMap, {
    required MatchedNodeData matchedNodeData,
  }) {
    final modifiable = {...yamlMap}; // Make modifiable

    // Get replacement
    final replacement = super.getReplacement<String>(
      matchedNodeData,
      checkForKey: false,
    );

    final updatedMap = modifiable.recursivelyUpdate(
      replacement,
      target: matchedNodeData.nodeData.key,
      path: matchedNodeData.nodeData.precedingKeys,
      updateMode: UpdateMode.replace,
      keyAndReplacement: {},
      valueToReplace: matchedNodeData.nodeData.data as String,
    );

    return YamlMap.wrap(updatedMap);
  }
}
