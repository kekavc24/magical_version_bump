part of 'replacer.dart';

/// Exclusively renames keys
class MagicalRenamer extends Replacer {
  MagicalRenamer(List<ReplacementTargets> targets) : super(targets: targets);

  @override
  KeysToFind getTargets() {
    return super.generateTargets<KeysToFind>(areKeys: true);
  }

  @override
  YamlMap replace(
    YamlMap yamlMap, {
    required MatchedNodeData matchedNodeData,
  }) {
    final modifiable = {...yamlMap}; // Make modifiable

    // Get replacement pair
    final replacementPair = super.getReplacement<Map<String, String>>(
      matchedNodeData,
      checkForKey: true,
    );

    final updatedMap = modifiable.recursivelyUpdate(
      null,
      target: matchedNodeData.nodeData.key,
      path: matchedNodeData.nodeData.precedingKeys,
      updateMode: UpdateMode.replace,
      keyAndReplacement: replacementPair,
      valueToReplace: null,
    );

    return YamlMap.wrap(updatedMap);
  }
}
