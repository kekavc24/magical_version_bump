part of '../yaml_transformer.dart';

/// Data object specifically created when a `Finder` finds it based on some 
/// predefined condition
@immutable
class MatchedNodeData extends NodeData {
  const MatchedNodeData(
    super.precedingKeys,
    super.key,
    super.value,
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
      nodeData.precedingKeys,
      nodeData.key,
      nodeData.value,
      matchedKeys,
      matchedValue,
      matchedPairs,
    );
  }

  /// List of keys in [ NodeData ] path that matched any preset conditions
  final List<String> matchedKeys;

  /// First/Only value matched from any of the values provided
  final String matchedValue;

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
    final keys = super.getKeysAsString();
    final lastIndex = matchedKeys.map(keys.lastIndexOf).max;

    // Keys to be taken, include last index plus one
    return super.getKeys().take(lastIndex + 1);
  }

  /// Get path of keys upto the last renameable key
  String getPathToLastKey() {
    return getUptoLastRenameable().map((key) => key.toString()).join('/');
  }
  
  @override
  List<Object> get props => [
        ...super.props,
        matchedKeys,
        matchedPairs,
        matchedValue,
      ];
}
