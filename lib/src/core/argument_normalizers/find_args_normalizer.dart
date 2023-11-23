part of 'arg_normalizer.dart';

final class FindArgumentsNormalizer extends ArgumentsNormalizer {
  FindArgumentsNormalizer({required super.argResults});

  late ValuesToFind _keys;
  late ValuesToFind _valuesToFind;
  late PairsToFind _pairsToFind;

  @override
  ({bool isValid, InvalidReason? reason}) customValidate() {
    final keys = extractKeyOrValue(argResults!, extractKeys: true);
    final values = extractKeyOrValue(argResults!, extractKeys: false);
    final pairs = extractPairs(argResults!);

    if (keys.isEmpty && values.isEmpty && pairs.isEmpty) {
      return (
        isValid: false,
        reason: const InvalidReason(
          'Missing arguments',
          'You need to provide at least a key/value/key-value pair to be found',
        ),
      );
    }

    setCandidates(keys, values, pairs);
    return super.customValidate();
  }

  @override
  ({
    Aggregator aggregator,
    KeysToFind keysToFind,
    ValuesToFind valuesToFind,
    PairsToFind pairsToFind,
  }) prepArgs() {
    return (
      aggregator: argResults!.getAggregator(),
      keysToFind: (keys: _keys, orderType: argResults!.keyOrder),
      valuesToFind: _valuesToFind,
      pairsToFind: _pairsToFind,
    );
  }

  /// Extracts keys/value in argument results
  List<String> extractKeyOrValue(
    ArgResults argResults, {
    required bool extractKeys,
  }) {
    // Remove duplicates
    return (extractKeys
            ? argResults.mapKeys.toSet()
            : argResults.mapValues.toSet())
        .toList();
  }

  /// Extracts pairs.
  ///
  /// Throws error when a pair is not complete
  PairsToFind extractPairs(ArgResults argResults) {
    final listOfValues = argResults.mapPairs;

    if (listOfValues.isEmpty) return {};

    // Join all lists
    final joinedPairs = listOfValues.reduce(
      (value, element) => [...value, ...element],
    );

    final pairsToFind = <String, String>{};

    // No pair should have a missing partner, throw error if so
    for (final pair in joinedPairs) {
      final keyAndPair = pair.splitAndTrim(':'); // Separated by ":"

      if (keyAndPair.length != 2) {
        throw MagicalException(
          violation: 'Invalid pair parsed and found at $pair ',
        );
      }

      pairsToFind.addAll({keyAndPair.first: keyAndPair.last});
    }
    return pairsToFind;
  }

  void setCandidates(
    ValuesToFind keys,
    ValuesToFind values,
    PairsToFind pairs,
  ) {
    _keys = keys;
    _valuesToFind = values;
    _pairsToFind = pairs;
  }
}
