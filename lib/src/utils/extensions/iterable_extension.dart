part of 'extensions.dart';

extension IterableOperations on Iterable<String> {
  /// Get target that will be used to update whole version relative to its
  /// position. Affinity/preference in descending order is:
  ///
  /// major > minor > patch
  ///
  List<String> getRelative() {
    // Sort aphabetically to order them naturally/ascending order
    final targets = <String>[
      ...where((element) => element != 'build-number'),
    ]..sort();

    return [
      if (targets.isNotEmpty) targets.first,
      if (contains('build-number')) 'build-number',
    ];
  }

  /// Retain non-empty values
  List<String> retainNonEmpty() {
    return where((element) => element.isNotEmpty).toList();
  }

  /// Check how many values match a condition of search string
  MatchCount checkMatchCount(String pattern) {
    if (every((element) => element.contains(pattern))) {
      return MatchCount.all;
    }

    if (any((element) => element.contains(pattern))) {
      return MatchCount.some;
    }

    return MatchCount.none;
  }

  /// Has all values found in another list
  bool hasAll(Iterable<String> other) {
    return every(other.contains) && (length == other.length);
  }
}
