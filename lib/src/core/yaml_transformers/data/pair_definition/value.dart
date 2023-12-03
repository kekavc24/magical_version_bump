part of 'pair_definition.dart';

/// Defines the value of a key/value pair
@immutable
final class Value extends PairType {
  Value({
    required this.value,
    required super.level,
    required super.indices,
  });

  /// Value of this value
  final dynamic value;

  @override
  bool operator ==(Object other) =>
      other is Value && _dataIsSame(other.value) && super._isSameLevel(other);

  @override
  int get hashCode => Object.hashAll([super.level, super.indices, value]);

  bool _dataIsSame(dynamic other) {
    if (value.runtimeType != other.runtimeType) return false;

    if (value is String) return value == other;

    return collectionsMatch(value, other);
  }

  @override
  String toString() => value.toString();
}
