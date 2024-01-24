part of 'replacer.dart';

/// Exclusively replaces values
class ValueReplacer extends Replacer {
  ValueReplacer(List<ReplacementTargets> targets) : super(targets: targets);

  @override
  T getTargets<T>() {
    return super.generateTargets<ValuesToFind>(areKeys: false) as T;
  }

  @override
  ReplacementOutput replace(
    YamlMap yamlMap, {
    required MatchedNodeData matchedNodeData,
  }) {
    final modifiable = {...yamlMap}; // Make modifiable

    // Get replacement
    final replacement = super.getReplacement<String>(
      matchedNodeData,
      checkForKey: false,
    );

    final updatedMap = modifiable.updateIndexedMap(
      replacement,
      target: matchedNodeData.key,
      path: matchedNodeData.precedingKeys,
      keyAndReplacement: {},
      value: matchedNodeData.value,
    );

    return (
      mapping: {matchedNodeData.data: replacement},
      updatedMap: YamlMap.wrap(updatedMap),
    );
  }
}
