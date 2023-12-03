part of '../yaml_transformer.dart';

/// Every Node has preceding keys and data at the end of it, even if null.
///
/// Typically denotes a terminal node found while indexing a Yaml map or any
/// map
@immutable
class NodeData {
  const NodeData._(this.precedingKeys, this.key, this.value);

  /// Create from the root anchor key
  factory NodeData.fromRoot({required String key, required dynamic value}) {
    return NodeData._(
      const [],
      _createPairType<Key>(isKey: true, value: key),
      _createPairType<Value>(isKey: false, value: value),
    );
  }

  /// Creates from entry in map.
  ///
  /// * By default, the level & index will apply to the key itself rather than
  ///   the value.
  /// * This is because we recursed the list to reach this key rather than the
  ///   value.
  factory NodeData.fromMapEntry({
    required NodeData parent,
    required MapEntry<dynamic, dynamic> current,
    required List<int> indices,
  }) {
    return NodeData._(
      [...parent.precedingKeys, parent.key],
      _createPairType<Key>(
        isKey: true,
        value: current.key,
        level: indices.isEmpty ? Level.normal : Level.nested,
        indices: indices,
      ),
      _createPairType<Value>(isKey: false, value: current.value),
    );
  }

  /// Creates from terminal value at the end of a node
  ///
  /// * By default, the level & index will apply to the value rather than
  ///   the key as we recursed the list to reach this key rather than the
  ///   value.
  ///
  /// * The parent's key will be this terminal value's key too as it's the
  ///   nearest key linking this value to a map.
  factory NodeData.atRootTerminal({
    required NodeData parent,
    required String terminalValue,
    required List<int> indices,
  }) {
    return NodeData._(
      [...parent.precedingKeys],
      parent.key,
      _createPairType<Value>(
        isKey: false,
        value: terminalValue,
        level: indices.isEmpty ? Level.normal : Level.nested,
        indices: indices,
      ),
    );
  }

  /// Any preceding keys for this node
  final List<Key> precedingKeys;

  /// Current key for this node
  final Key key;

  /// Current data at this node
  final Value value;

  /// Gets the actual value rather than the object storing it i.e.
  ///
  /// ```dart
  /// Value.value
  /// ```
  dynamic get data => value.value;

  /// Transform to key value pairs, based on this node data's path.
  ///
  /// Note: the terminal value must be a string
  Map<String, String?> transformToPairs() {
    // Get length of list
    final lastIndex = precedingKeys.length - 1;

    final mapOfPairs = <String, String?>{};

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
    mapOfPairs.addAll({key.toString(): data as String?});
    return mapOfPairs;
  }

  /// Get keys
  List<Key> getKeys() {
    return precedingKeys.isEmpty ? [key] : [...precedingKeys, key];
  }

  /// Get key path for this node
  String getKeyPath() {
    return getKeys().join('/');
  }

  @override
  bool operator ==(Object other) =>
      other is NodeData &&
      other.key == key &&
      other.value == value &&
      collectionsMatch(precedingKeys, other.precedingKeys);

  @override
  int get hashCode => Object.hashAll([key, value, precedingKeys]);

  @override
  String toString() => '${getKeyPath()}/$data';

  /// Checks whether this node is nested
  bool isNested() =>
      key.isNested() ||
      value.isNested() ||
      precedingKeys.isNotEmpty &&
          precedingKeys.any((element) => element.isNested());
}

/// Creates a specialized PairType
T _createPairType<T extends PairType>({
  required bool isKey,
  required dynamic value,
  Level? level,
  List<int>? indices,
}) {
  return isKey
      ? Key(
          value: value as String,
          level: level ?? Level.normal,
          indices: indices ?? [],
        ) as T
      : Value(
          value: isTerminal(value) ? value.toString() : value,
          level: level ?? Level.normal,
          indices: indices ?? [],
        ) as T;
}
