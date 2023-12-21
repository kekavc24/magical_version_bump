part of '../yaml_transformer.dart';

/// Data object with specifically created when a `Finder`
/// finds it based on some predefined condition
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

  /// Get a map of the last index of each matched key and the list of keys.
  ///
  /// Keys matched must not be empty
  Map<String, int> getMatchedKeysIndex() {
    // Get keys
    final keys = super.getKeysAsString();

    final indexMap = matchedKeys.fold(
      <String, int>{},
      (previousValue, element) {
        previousValue.addAll(
          {element: keys.lastIndexOf(element)},
        );
        return previousValue;
      },
    );

    return indexMap;
  }

  /// Get list of keys upto the last renameable key
  Iterable<Key> getUptoLastRenameable() {
    // Get max
    final indexMap = getMatchedKeysIndex();
    final lastIndex = indexMap.values.max;

    // Keys to be taken, include last index plus one
    return super.getKeys().take(lastIndex + 1);
  }

  /// Get path of keys upto the last renameable key
  String getPathToLastKey() {
    return getUptoLastRenameable().map((e) => e.value!).join('/');
  }

  /// 

  @override
  bool operator ==(Object other) =>
      other is MatchedNodeData &&
      super == other &&
      collectionsUnorderedMatch(matchedKeys, other.matchedKeys) &&
      matchedValue == other.matchedValue &&
      collectionsUnorderedMatch(matchedPairs, other.matchedPairs);

  @override
  int get hashCode => Object.hashAll([
        super.precedingKeys,
        super.key,
        super.value,
        matchedKeys,
        matchedValue,
        matchedPairs,
      ]);
}
