import 'package:magical_version_bump/src/utils/extensions/map_extensions.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:meta/meta.dart';

part 'pair_subtypes.dart';

/// Custom key/value definition
@immutable
abstract base class PairType {
  PairType({required dynamic value, List<int>? indices})
      : _value = value,
        _indices = indices ?? [];

  /// Indicates the actual value
  final dynamic _value;

  /// Indicates the list of indices when nested in 1 or more lists
  final List<int> _indices;

  /// Obtains the actual value stored here at runtime.
  dynamic get rawValue => _value;

  /// Obtains the list of indices when nested in 1 or more lists
  List<int> get indices => _indices;

  @override
  bool operator ==(Object other) {
    return other is PairType &&
        _hasSameValue(other.rawValue) &&
        collectionsMatch(indices, other.indices);
  }

  bool _hasSameValue(dynamic other) {
    if (rawValue.runtimeType != other.runtimeType) return false;
    if (isTerminal(rawValue)) return rawValue == other;
    return collectionsMatch(rawValue, other);
  }

  @override
  int get hashCode => Object.hashAll([rawValue, indices]);

  /// Returns the value stored at this node as a string
  @override
  String toString() {
    return _value.toString();
  }

  /// Checks if nested in a list
  bool isNested() => _indices.isNotEmpty;
}

/// Creates desired pair type on the fly.
T createPair<T extends PairType>({
  required dynamic value,
  List<int>? indices,
}) {
  if (T == Key) return Key(value: value, indices: indices) as T;
  return Value(value: value, indices: indices) as T;
}

/// Creates a list of desired pairs.
List<T> createListOfPair<T extends PairType>({
  required List<dynamic> values,
  required Map<String, List<int>> indices,
}) {
  return values
      .map((value) => createPair<T>(value: value, indices: indices[value]))
      .toList();
}
