part of '../yaml_transformer.dart';

/// Every Node has preceding keys and data at the end of it, even if null.
///
/// Typically denotes a terminal node found while indexing a Yaml map or any
/// map
@immutable
class NodeData extends Equatable {
  const NodeData(this.precedingKeys, this.key, this.value);

  /// Create with default constructor
  const NodeData.skeleton({
    required List<Key> precedingKeys,
    required Key key,
    required Value value,
  }) : this(precedingKeys, key, value);

  /// Create using List<String> path and key
  NodeData.stringSkeleton({
    required List<String> path,
    required String key,
    required String value,
  }) : this.skeleton(
          precedingKeys: path.map((e) => createPair<Key>(value: e)).toList(),
          key: createPair<Key>(value: key),
          value: createPair<Value>(value: value),
        );

  /// Create from the root anchor key
  NodeData.fromRoot({required dynamic key, required dynamic value})
      : this.skeleton(
          precedingKeys: const [],
          key: createPair<Key>(value: key),
          value: createPair<Value>(value: value),
        );

  /// Creates from entry in map.
  ///
  /// * By default, the level & index will apply to the key itself rather than
  ///   the value.
  /// * This is because we recursed the list to reach this key rather than the
  ///   value.
  NodeData.fromMapEntry({
    required NodeData parent,
    required MapEntry<dynamic, dynamic> current,
    required List<int> indices,
  }) : this.skeleton(
          precedingKeys: [...parent.precedingKeys, parent.key],
          key: createPair<Key>(value: current.key, indices: indices),
          value: createPair<Value>(value: current.value),
        );

  /// Creates from terminal value at the end of a node
  ///
  /// * By default, the level & index will apply to the value rather than
  ///   the key as we recursed the list to reach this key rather than the
  ///   value.
  ///
  /// * The parent's key will be this terminal value's key too as it's the
  ///   nearest key linking this value to a map.
  NodeData.atRootTerminal({
    required NodeData parent,
    required dynamic terminalValue,
    required List<int> indices,
  }) : this.skeleton(
          precedingKeys: [...parent.precedingKeys],
          key: parent.key,
          value: createPair<Value>(value: terminalValue, indices: indices),
        );

  /// Any preceding keys for this node
  final List<Key> precedingKeys;

  /// Current key for this node
  final Key key;

  /// Current data at this node
  final Value value;

  /// Gets the actual value at terminal end as a string. A null value will be
  /// returned as 'null'.
  String get data => value.toString();

  /// Transform to key value pairs, based on this node data's path.
  ///
  /// Note: the terminal value must be a string
  Map<String, String> transformToPairs() {
    // Get length of list
    final lastIndex = precedingKeys.length - 1;

    final mapOfPairs = <String, String>{};

    // Loop all and create keys in tandem
    for (final (index, candidate) in precedingKeys.indexed) {
      // If we reached the last value, pair it with key for this node
      if (index == lastIndex) {
        mapOfPairs.addAll({candidate.toString(): key.toString()});
      }

      // Just get the next key
      else {
        final nextCandidate = precedingKeys[index + 1];
        mapOfPairs.addAll({candidate.toString(): nextCandidate.toString()});
      }
    }

    // Add key and value as last pair
    mapOfPairs.addAll({key.toString(): data});
    return mapOfPairs;
  }

  /// Obtains the keys as they were indexed.
  ///
  /// Typically includes any indices if the key was nested in a list for
  /// easy access when reading
  List<Key> getKeys() {
    return precedingKeys.isEmpty ? [key] : [...precedingKeys, key];
  }

  /// Obtains the keys as string. Ignores any indices present
  List<String> getKeysAsString() {
    return getKeys().map((e) => e.toString()).toList();
  }

  /// Get key path for this node
  String getKeyPath() {
    return getKeysAsString().join('/');
  }

  @override
  List<Object> get props => [precedingKeys, key, value];

  /// Obtains full path to terminal value of this node
  @override
  String toString() => '${getKeyPath()}/$data';

  /// Checks whether this node is nested
  bool isNestedInList() =>
      key.isNested() ||
      value.isNested() ||
      precedingKeys.isNotEmpty &&
          precedingKeys.any((element) => element.isNested());
}
