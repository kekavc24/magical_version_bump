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
}
