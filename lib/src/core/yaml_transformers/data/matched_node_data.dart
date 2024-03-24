part of '../yaml_transformer.dart';

/// Data object specifically created when a `Finder` finds it based on some
/// predefined condition
class MatchedNodeData {
  MatchedNodeData(
    this.node,
    this.matchedKeys,
    this.matchedValue,
    this.matchedPairs,
  );

  /// Data from finder
  factory MatchedNodeData.fromFinder({
    required NodeData nodeData,
    required List<String> matchedKeys,
    required String matchedValue,
    required Map<String, String> matchedPairs,
  }) {
    return MatchedNodeData(
      nodeData,
      matchedKeys,
      matchedValue,
      matchedPairs,
    );
  }

  /// Denotes [NodeData] belonging to an indexed node that has been matched
  final NodeData node;

  /// List of keys in [ NodeData ] path that matched any preset conditions
  final List<String> matchedKeys;

  /// First/Only value matched from any of the values provided
  String matchedValue;

  /// Map of pairs that matched any pairs provided
  final Map<String, String> matchedPairs;

  /// Check if valid match, at least one should not be empty
  bool isValidMatch() {
    return matchedKeys.isNotEmpty ||
        matchedValue.isNotEmpty ||
        matchedPairs.isNotEmpty;
  }

  /// Get list of keys upto the last renameable key
  Iterable<Key> getUptoLastRenameable() {
    final keys = node.getKeysAsString();
    final lastIndex = matchedKeys.map(keys.lastIndexOf).max;

    // Keys to be taken, include last index plus one
    return node.getKeys().take(lastIndex + 1);
  }

  /// Get path of keys upto the last renameable key
  String getPathToLastKey() {
    return getUptoLastRenameable().map((key) => key.toString()).join('/');
  }

  @override
  String toString() => node.toString();
}
