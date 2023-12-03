part of 'pair_definition.dart';

/// Defines the key of a key/value pair in a Map
@immutable
final class Key extends PairType {
  Key({
    required this.value,
    required super.level,
    required super.indices,
  });

  /// Value of this key
  final String? value;

  @override
  bool operator ==(Object other) =>
      other is Key && other.value == value && super._isSameLevel(other);

  @override
  int get hashCode => Object.hashAll([super.level, super.indices, value]);

  @override
  String toString() => value ?? '';
}
