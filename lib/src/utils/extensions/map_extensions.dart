import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';

/// Extension to help read nested values
extension MapUtility on Map<dynamic, dynamic> {
  /// Read nested values recursively
  T? recursiveRead<T>({
    required List<dynamic> path,
    required dynamic target,
  }) {
    if (path.isEmpty) {
      return this[target] as T?;
    }
    final currentKey = path.first;

    if (!containsKey(currentKey)) return null;

    final currentValue = this[currentKey];

    if (currentValue is! Map<dynamic, dynamic>) return null;

    final modifiedPath = [...path]..removeAt(0);

    return currentValue.recursiveRead(
      path: modifiedPath,
      target: target,
    ) as T?;
  }

  /// Recursively update a [target] key specified based on the [path] of 
  /// preceding keys.
  /// 
  /// `append` is boolean which specifies whether to add to existing values if
  /// `true` or overwriting any existing values if `false`.
  /// 
  /// `update` is dynamic and allows any data type support by `Dart`. With
  /// this package, the value will either be a `String`, `List<String>` or
  /// `Map<String, String>`
  ///  
  Map<dynamic, dynamic> recursivelyUpdate(
    dynamic update, {
    required String target,
    required List<String> path,
    required bool append,
  }) {
    // Base condition for our function
    if (path.isEmpty) {
      // Read current value at the end
      final targetKeyValue = this[target];
      final targetValIsNull = targetKeyValue == null;

      if (append && targetValIsNull || !append) {
        final directUpdate = update is String && !append
            ? update
            : update is String && append
                ? <String>[update]
                : update is List<String>
                    ? <String>[...update]
                    : update as Map<String, String>;

        this.update(
          target,
          (value) => directUpdate,
          ifAbsent: () => directUpdate,
        );

        return this;
      }

      // Due to many checks
      dynamic valueToAppend;

      // Check for mismatch when target value is not null
      if ((targetKeyValue is String || targetKeyValue is List) &&
          (update is! String && update is! List<String>)) {
        throw MagicalException(
          violation: 'Cannot append new values at $target',
        );
      } else if (targetKeyValue is Map && update is! Map<String, String>) {
        throw MagicalException(
          violation: 'Cannot append new mapped values at $target',
        );
      }

      // Convert all strings to list of strings
      if (targetKeyValue is String) {
        valueToAppend = update is String
            ? <String>[targetKeyValue, update]
            : <String>[targetKeyValue, ...update as List<String>];
      } else if (targetKeyValue is List) {
        valueToAppend = update is String
            ? [...targetKeyValue, update]
            : [...targetKeyValue, ...update as List<String>];
      } else {
        valueToAppend = <dynamic, dynamic>{}
          ..addAll(targetKeyValue as Map)
          ..addAll(update as Map<String, String>);
      }

      this.update(target, (value) => valueToAppend);

      return this;
    }

    /// If path is not empty, just read the next key in sequence and do
    /// another update recursively!
    final currentKey = path.first;

    final valueAtKey = this[currentKey];

    /// Since we have not exhausted all keys in this path, the value must
    /// either be a `Map<dynamic, dynamic>` or `null` or `append` is false
    ///
    /// For `null`, we will create missing key as this was a guarantee for
    /// updating the yaml file, a guaranteed fallback.
    ///
    /// However, if `append` is `false`, means we are overwriting the whole
    /// path.
    if (valueAtKey != null && valueAtKey is! Map<dynamic, dynamic> && append) {
      throw MagicalException(
        violation: 'Cannot append new values at $currentKey',
      );
    }

    // Update path, as this key will be updated
    final updatedPath = [...path]..removeAt(0);

    /// If value is `null` OR `append` is false
    if (valueAtKey == null) {
      this[currentKey] = <dynamic, dynamic>{}.recursivelyUpdate(
        update,
        target: target,
        path: updatedPath,
        append: append,
      );

      return this;
    }
    // Current value as is
    final castedValueAtKey = <dynamic, dynamic>{
      ...valueAtKey as Map<dynamic, dynamic>,
    };

    this[currentKey] = castedValueAtKey.recursivelyUpdate(
      update,
      target: target,
      path: updatedPath,
      append: append,
    );

    return this;
  }
}
