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

  /// Output list of values for dictionary based on match count
  dynamic splitBasedOnMatch() {
    const pattern = '->';

    final matchCount = checkMatchCount(pattern);

    // If all are maps, return an enclosed map of values
    if (matchCount == MatchCount.all) {
      return fold(
        <String, String>{},
        (previousValue, element) {
          final map = element.splitAndTrim(pattern);
          previousValue.update(
            map.first,
            (value) => map.last.isEmpty ? 'null' : map.last,
            ifAbsent: () => map.last.isEmpty ? 'null' : map.last,
          );
          return previousValue;
        },
      );
    }

    // If mixed with some strings, split individually
    if (matchCount == MatchCount.some) {
      return fold(
        <dynamic>[],
        (previousValue, element) {
          // Extract map and add it
          if (element.contains(pattern)) {
            final map = element.splitAndTrim(pattern);
            previousValue.add(
              {map.first: map.last.isEmpty ? 'null' : map.last},
            );
          } else {
            previousValue.add(element);
          }

          return previousValue;
        },
      );
    }

    // Just return "as-is" if none
    return this;
  }

  /// Has all values found in another list
  bool hasAll(Iterable<String> other) {
    return every(other.contains) && (length == other.length);
  }
}
