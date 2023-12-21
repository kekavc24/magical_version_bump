part of 'replacer.dart';

/// Exclusively renames keys
class MagicalRenamer extends Replacer {
  MagicalRenamer(List<ReplacementTargets> targets) : super(targets: targets);

  @override
  KeysToFind getTargets() {
    return super.generateTargets<KeysToFind>(areKeys: true);
  }

  /// Dry run a replacement of keys.
  ///
  /// PS: Matches here will never have empty matched keys
  ///
  /// A node is usually indexed to the terminal value, in certain instances
  /// multiple node values may be yielded from the same node with the same
  /// keys. This happens to values in a list along the same key path.
  ///
  /// Stick out point is, we only return the ideal path upto the last key
  /// to be renamed i.e the path to the last key being renamed. That guarantees
  /// a certain uniqueness that allows us to track and optimize for
  /// unnecessary recursions for deeply nested keys along the same path.
  ///
  String replaceDryRun(MatchedNodeData matchedNodeData) {
    // Get replacement pair
    final replacementPair = super.getReplacement<Map<String, String>>(
      matchedNodeData,
      checkForKey: true,
    );

    // Key path to last key
    var keyPath = matchedNodeData.getPathToLastKey();

    for (final pair in replacementPair.entries) {
      keyPath = keyPath.replaceAll(pair.key, pair.value);
    }

    return keyPath;
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
