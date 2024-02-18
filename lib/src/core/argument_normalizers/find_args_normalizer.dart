part of 'arg_normalizer.dart';

final class FindArgumentsNormalizer extends ArgumentsNormalizer {
  FindArgumentsNormalizer({required super.argResults});

  late ValuesToFind _keysToFind;
  late ValuesToFind _valuesToFind;
  late PairsToFind _pairsToFind;

  @override
  (bool isValid, InvalidReason? reason) customValidate() {
    _keysToFind = _extractKeyOrValue(argResults!, extractKeys: true);
    _valuesToFind = _extractKeyOrValue(argResults!, extractKeys: false);
    _pairsToFind = _extractPairs(argResults!);

    if (_keysToFind.isEmpty && _valuesToFind.isEmpty && _pairsToFind.isEmpty) {
      return (
        false,
        const InvalidReason(
          'Missing arguments',
          'You need to provide at least a key/value/key-value pair to be found',
        ),
      );
    }
    return super.customValidate();
  }

  @override
  (
    Aggregator aggregator,
    KeysToFind keysToFind,
    ValuesToFind valuesToFind,
    PairsToFind pairsToFind,
  ) prepArgs() {
    return (
      argResults!.getAggregator(),
      (keys: _keysToFind, orderType: argResults!.keyOrder),
       _valuesToFind,
      _pairsToFind,
    );
  }

  /// Extracts keys/value in argument results
  List<String> _extractKeyOrValue(
    ArgResults argResults, {
    required bool extractKeys,
  }) {
    // Remove duplicates
    return Set<String>.from(
      extractKeys ? argResults.mapKeys : argResults.mapValues,
    ).toList();
  }

  /// Extracts pairs.
  ///
  /// Throws error when a pair is not complete
  PairsToFind _extractPairs(ArgResults argResults) {
    final listOfPairs = argResults.mapPairs.flattened;

    if (listOfPairs.isEmpty) return {};

    final pairsToFind = <String, String>{};

    // No pair should have a missing partner, throw error if so
    for (final pair in listOfPairs) {
      final keyAndPair = pair.splitAndTrim(':'); // Separated by ":"

      if (keyAndPair.length != 2) {
        throw MagicalException(
          message: 'Invalid pair parsed and found at $pair ',
        );
      }

      pairsToFind.addAll({keyAndPair.first: keyAndPair.last});
    }
    return pairsToFind;
  }
}
