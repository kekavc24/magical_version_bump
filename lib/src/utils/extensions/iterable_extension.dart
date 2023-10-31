import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/string_extensions.dart';

extension Operations on Iterable<String> {
  /// Get target that will be used to update whole version relative to its
  /// position. Affinity/preference in descending order is:
  ///
  /// major > minor > patch
  ///
  List<String> getRelative() {
    final targets = <String>[];

    // Assign weights
    final weighted = fold(<String, int>{}, (previousValue, element) {
      final score = element == 'major'
          ? 20
          : element == 'minor'
              ? 10
              : element == 'patch'
                  ? 5
                  : 0;

      previousValue.addEntries([MapEntry(element, score)]);

      return previousValue;
    });

    final maxWeight = weighted.entries.reduce(
      (value, element) => value.value > element.value ? value : element,
    );

    targets.add(maxWeight.key);

    if (contains('build-number')) {
      targets.add('build-number');
    }

    return targets;
  }

  /// Retain non-empty values
  List<String> retainNonEmpty() {
    final retainedList = [...this]..retainWhere(
        (element) => element.isNotEmpty,
      );
    return retainedList;
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
}
