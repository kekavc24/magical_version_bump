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

    if (contains('build-number')) targets.add('build-number');

    return targets;
  }
}
