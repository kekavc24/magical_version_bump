part of 'custom_pair_type.dart';

/// A key in a custom key/value definition
final class Key extends PairType {
  Key({required super.value, required super.indices})
      : assert(
          isTerminal(value),
          'A type of ${value.runtimeType} cannot be a key',
        );
}

/// A value in a custom key/value definition
final class Value extends PairType {
  Value({required super.value, required super.indices});
}
