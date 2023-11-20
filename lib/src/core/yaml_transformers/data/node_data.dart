part of '../yaml_transformer.dart';

/// Every Node has preceding keys and data at the end of it, even if null.
///
/// Typically denotes a terminal node found while indexing a Yaml map or any
/// map
@immutable
class NodeData {
  const NodeData._(this.key, this.precedingKeys, this.data, this.isNested);

  factory NodeData.fromYaml(String key, List<String> path, dynamic data) {
    return NodeData._(key, path, data, null);
  }

  factory NodeData.entryFromPreceding(
    MapEntry<dynamic, dynamic> entry,
    NodeData oldData,
  ) {
    return NodeData._(
      entry.key as String,
      [...oldData.precedingKeys, oldData.key],
      entry.value,
      null,
    );
  }

  factory NodeData.terminalEntry(String value, NodeData oldData) {
    return NodeData._(
      oldData.key,
      [...oldData.precedingKeys],
      value,
      null,
    );
  }

  factory NodeData.markAsNested(NodeData oldData) {
    return NodeData._(
      oldData.key,
      [...oldData.precedingKeys],
      oldData.data,
      true,
    );
  }

  /// Current key for this node
  final String key;

  /// Any preceding keys of a node
  final List<String> precedingKeys;

  /// Current data at this node
  final dynamic data;

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
  final bool? isNested;

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

  @override
  bool operator ==(Object other) =>
      other is NodeData &&
      key == other.key &&
      _dataIsSame(other.data) &&
      collectionsMatch(precedingKeys, other.precedingKeys) &&
      isNested == other.isNested;

  @override
  int get hashCode => Object.hash(key, precedingKeys, data, isNested);

  bool _dataIsSame(dynamic other) {
    if (data.runtimeType != other.runtimeType) return false;

    if (data is String) return data == other;

    return collectionsMatch(data, other);
  }
}
