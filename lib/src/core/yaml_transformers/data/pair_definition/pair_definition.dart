import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:meta/meta.dart';

part 'key.dart';
part 'value.dart';

/// Level of a key/value in a map
enum Level {
  /// Direct value of a key
  normal,

  /// Nested in a list
  nested
}

/// Forms the base class for a key/value in a map
abstract base class PairType {
  PairType({required this.level, required this.indices});

  /// Level in based on parent key
  final Level level;

  /// List of indices in order of nested level
  final List<int> indices;

  /// Checks whether this key is nested
  bool isNested() => level == Level.nested;

  /// Checks whether they are on the same level
  bool _isSameLevel(PairType other) =>
      level == other.level && collectionsMatch(indices, other.indices);
}
