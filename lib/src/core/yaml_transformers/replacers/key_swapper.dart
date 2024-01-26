part of 'replacer.dart';

/// Exclusively renames keys
class KeySwapper extends Replacer {
  KeySwapper(super.substituteToMatchers);

  @override
  T getTargets<T>() {
    return super.generateTargets<KeysToFind>(areKeys: true) as T;
  }

  @override
  ReplacementOutput replace(
    YamlMap yamlMap, {
    required MatchedNodeData matchedNodeData,
  }) {
    final modifiable = {...yamlMap}; // Make modifiable

    // Get replacement pair
    final replacementPair = super.getReplacement<Map<String, String>>(
      matchedNodeData,
      checkForKey: true,
    );

    // Get path to last renameable key inclusive of last key to be renamed
    final pathToLastKey = [...matchedNodeData.getUptoLastRenameable()];

    // Remove last which will act as our pseudo target
    final target = pathToLastKey.removeLast();

    final updatedMap = modifiable.updateIndexedMap(
      null,
      target: target,
      path: pathToLastKey,
      keyAndReplacement: replacementPair,
      value: null,
    );

    return (
      mapping: replacementPair,
      updatedMap: YamlMap.wrap(updatedMap),
    );
  }
}
