part of '../yaml_transformer.dart';

/// Data object with specifically created when a `Finder`
/// finds it based on some predefined condition
@immutable
class MatchedNodeData {
  const MatchedNodeData._(
    this.nodeData,
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
    return MatchedNodeData._(nodeData, matchedKeys, matchedValue, matchedPairs);
  }

  /// Node data that matched any preset conditions
  final NodeData nodeData;

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
  ({Map<String, int> indexMap, List<Key> keys}) getMatchedKeysIndex() {
    // Get keys
    final keys = nodeData.getKeys();

    final indexMap = keys.fold(
      <String, int>{},
      (previousValue, element) {
        previousValue.addAll(
          {element.toString(): keys.lastIndexOf(element)},
        );
        return previousValue;
      },
    );

    return (indexMap: indexMap, keys: keys);
  }

  /// Get path of keys upto the last renameable key
  String getPathToLastKey() {
    final keyRecord = getMatchedKeysIndex();
    final lastIndex = keyRecord.indexMap.values.max; // Get max

    // Keys to be taken, include last index plus one
    return keyRecord.keys.take(lastIndex + 1).join('/');
  }

  @override
  bool operator ==(Object other) =>
      other is MatchedNodeData &&
      nodeData == other.nodeData &&
      collectionsUnorderedMatch(matchedKeys, other.matchedKeys) &&
      matchedValue == other.matchedValue &&
      collectionsUnorderedMatch(matchedPairs, other.matchedPairs);

  @override
  int get hashCode => Object.hash(
        nodeData,
        matchedKeys,
        matchedValue,
        matchedPairs,
      );
}
