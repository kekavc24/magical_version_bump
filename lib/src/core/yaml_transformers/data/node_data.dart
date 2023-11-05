part of '../yaml_transformer.dart';

/// Every Node has preceding keys and data at the end of it, even if null.
///
/// Typically denotes a terminal node found while indexing a Yaml map or any
/// map
class NodeData {
  NodeData._(this.key, Iterable<String> path, this.data) {
    precedingKeys = List.from(path);
  }

  factory NodeData.fromYaml(String key, Iterable<String> path, dynamic data) {
    return NodeData._(key, path, data);
  }

  factory NodeData.entryFromPreceding(
    MapEntry<dynamic, dynamic> entry,
    NodeData oldData,
  ) {
    return NodeData._(
      entry.key as String,
      [...oldData.precedingKeys, oldData.key],
      entry.value,
    );
  }

  factory NodeData.terminalEntry(String value, NodeData oldData) {
    return NodeData._(
      oldData.key,
      [...oldData.precedingKeys],
      value,
    );
  }

  /// Current key for this node
  late String key;

  /// Any preceding keys of a node
  late final List<String> precedingKeys;

  /// Current data at this node
  late dynamic data;

  /// Whether to mark this as a start to a list nested in list.
  ///
  /// NOTE: This only applies to JSON files.
  ///
  /// Example:
  ///
  /// ```json
  ///   {
  ///     "key" : [ "normal", ["nested"] ]
  ///   }
  /// ```
  ///
  /// Yaml will need them to be part of a key in the file itself. Will be null
  /// for yaml nodes.
  ///
  bool? isNested;

  void markAsNested() {
    isNested = true;
  }

  /// Transform to key value pairs, based on this node data's path.
  Map<String, String> transformToPairs() {
    // Get length of list
    final lastIndex = precedingKeys.length - 1;

    final mapOfPairs = <String, String>{};

    // Loop all and create keys in tandem
    for (final (index, candidate) in precedingKeys.indexed) {
      // If we reached the last value, pair it with key for this node
      if (index == lastIndex) {
        mapOfPairs.addAll({candidate: key});
      }

      // Just get the next key
      else {
        final nextCandidate = precedingKeys[index + 1];
        mapOfPairs.addAll({candidate: nextCandidate});
      }
    }

    // Add key and value as last pair
    mapOfPairs.addAll({key: data as String});
    return mapOfPairs;
  }
}
