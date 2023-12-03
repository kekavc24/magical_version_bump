/// Custom key/value definition
///
/// `value` - indicates the actual value
/// `indices` - indicates the list of indices when nested in 1 or more lists
typedef PairType<T> = ({T? value, List<int> indices});

/// A key in a custom key/value definition
///
/// See [PairType]
typedef Key = PairType<String>;

/// A value in a custom key/value definition
///
/// See [PairType]
typedef Value = PairType<dynamic>;

T _pairType<T>({
  required dynamic value,
  required List<int> indices,
}) {
  return (value: value, indices: indices) as T;
}

/// Create key
Key createKey({String? value, List<int>? indices}) => _pairType(
      value: value,
      indices: indices ?? [],
    );

/// Creates a list of keys
List<Key> createListOfKeys({
  required List<String> keys,
  required Map<String, List<int>> linkedIndices,
}) {
  return keys
      .map((e) => createKey(value: e, indices: linkedIndices[e]))
      .toList();
}

/// Create value
Value createValue({required dynamic value, List<int>? indices}) => _pairType(
      value: value,
      indices: indices ?? [],
    );

/// Creates a list of keys
List<Value> createListOfValues({
  required List<String> keys,
  required Map<String, List<int>> linkedIndices,
}) {
  return keys
      .map((e) => createValue(value: e, indices: linkedIndices[e]))
      .toList();
}

extension PairTypeExtension<T> on PairType<T> {
  /// Checks if nested in a list
  bool isNested() => this.indices.isNotEmpty;
}
