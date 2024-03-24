part of 'replacer.dart';

/// Exclusively replaces values
class ValueReplacer extends Replacer {
  ValueReplacer(super.substituteToMatchers);

  @override
  T getTargets<T>() {
    return super.generateTargets<ValuesToFind>(areKeys: false) as T;
  }

  @override
  ReplacementOutput replace(
    Map<dynamic, dynamic> map, {
    required MatchedNodeData matchedNodeData,
  }) {
    final modifiable = {...map}; // Make modifiable

    // Get replacement
    final replacement = super.getReplacement<String>(
      matchedNodeData,
      checkForKey: false,
    );

    final updatedMap = modifiable.updateIndexedMap(
      replacement,
      target: matchedNodeData.node.key,
      path: matchedNodeData.node.precedingKeys,
      keyAndReplacement: {},
      value: matchedNodeData.node.value,
    );

    return (
      mapping: {matchedNodeData.node.data: replacement},
      updatedMap: YamlMap.wrap(updatedMap),
    );
  }
}
