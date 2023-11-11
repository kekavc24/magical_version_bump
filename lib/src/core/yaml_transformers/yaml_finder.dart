part of 'yaml_transformer.dart';

/// Find the first value matching a condition
class MagicalFinder extends Finder {
  MagicalFinder({
    required super.indexer,
    super.keysToFind,
    super.valuesToFind,
    super.pairsToFind,
  });

  /// Setup everything that may need to found
  factory MagicalFinder.setUp(
    YamlMap yamlMap, {
    KeysToFind? keysToFind,
    ValuesToFind? valuesToFind,
    PairsToFind? pairsToFind,
  }) {
    return MagicalFinder(
      indexer: MagicalIndexer.forYaml(yamlMap),
      keysToFind: keysToFind,
      valuesToFind: valuesToFind,
      pairsToFind: pairsToFind,
    );
  }

  @override
  Iterable<MatchedNodeData> findByCountSync(int count) sync* {
    if (count < 1) {
      throw MagicalException(
        violation: 'Count must be a value equal/greater than 1',
      );
    }

    yield* findAllSync().take(count);
  }

  @override
  MatchedNodeData generateMatch(NodeData nodeData) {
    return MatchedNodeData.fromFinder(
      nodeData: nodeData,
      matchedKeys: getMatchingKeys(nodeData),
      matchedValue: getFirstMachingValue(nodeData),
      matchedPairs: getMatchingPairs(nodeData),
    );
  }

  /// Check if keys contain a value
  @protected
  List<String> getMatchingKeys(NodeData nodeData) {
    // If empty, just return null, as we can't match for it
    if (keysToFind == null || _keysToFind.keys.isEmpty) return [];

    // Get all nodes keys together in order
    final nodeKeys = [...nodeData.precedingKeys, nodeData.key];

    // If not grouped, we check if any key we are searching for is present
    if (!_keysToFind.areGrouped) {
      return nodeKeys.where(_keysToFind.keys.contains).toList();
    }

    ///
    /// If grouped:
    ///   * We first check if all keys in the set we have, are contained in
    ///      the node keys
    ///
    /// If key-order is strict:
    ///   * We check if indexes are in sequence

    // Check every element is there
    var hasAll = nodeKeys.hasAll(_keysToFind.keys);

    // If key order is strict, check if all elements are present in order
    if (_keysToFind.strictOrder && hasAll) {
      // Create a map of all possible indexes
      final mapOfPossibleIndexes = nodeKeys.indexed.fold(
        <String, List<int>>{},
        (previousValue, element) {
          // Just ignore if not present
          if (!_keysToFind.keys.contains(element.$2)) return previousValue;

          // Attempt to read the value
          final nullableValue = previousValue[element];

          // Update
          previousValue.update(
            element.$2,
            (value) => [...nullableValue!, element.$1],
            ifAbsent: () => [element.$1],
          );

          return previousValue;
        },
      );

      // Re-validate this check to mean has all and in sequence/order
      hasAll = mapOfPossibleIndexes.values.satisfiesSequence();
    }

    return hasAll ? nodeKeys : [];
  }

  /// Check if any values are a match
  @protected
  String getFirstMachingValue(NodeData nodeData) {
    // No need to check if empty
    if (valuesToFind == null || _valuesToFind.isEmpty) return '';

    return _valuesToFind.firstWhere(
      (element) => element == nodeData.data,
      orElse: () => '',
    );
  }

  /// Check if any pairs are a match. Returns all pairs that are in this node.
  /// Uses its path and terminal key & value
  @protected
  Map<String, String> getMatchingPairs(NodeData nodeData) {
    // No need to check if empty
    if (pairsToFind == null || _pairsToFind.isEmpty) return {};

    // Format the data to matching data type
    final nodeDataAsPairs = nodeData.transformToPairs();

    ///
    /// The quirk about indexing every node in the yaml/json file and returning
    /// the terminal value, we can just check for pairs with 1-1 relationship.
    ///
    /// Additionally, the arguments are parsed elegantly guaranteeing we have
    /// this down the line.
    ///
    return _pairsToFind.entries.fold(
      <String, String>{},
      (previousValue, foldedValue) {
        // Check if a match
        final canAdd = nodeDataAsPairs.entries.any(
          (element) =>
              element.key == foldedValue.key &&
              element.value == foldedValue.value,
        );

        if (canAdd) previousValue.addEntries([foldedValue]);

        return previousValue;
      },
    );
  }
}

extension _CheckStrictOrderCandidate on Iterable<List<int>> {
  /// Check if a map satisfies a sequence based on available indexes.
  ///
  /// A sequence differs just by one. The deeper we go, the smaller the list
  /// to match becomes or not.
  ///
  /// A list can only be a sequence candidate if and only if any of its values
  /// differ by based on preceding list. This rule excludes the first element.
  bool satisfiesSequence() {
    // Get the value at first index, since it determines the start
    final startingValue = first;

    // Get all remaining entries
    final tailValues = skip(1).toList();

    var previousListToMatch = startingValue;

    // Loop all and look for any that dont satisfy sequence
    for (final tail in tailValues) {
      final matchCandidate = tail.where(
        (element) => previousListToMatch.any(
          (matcher) => element - matcher == 1,
        ),
      );

      // If none is available, always false
      if (matchCandidate.isEmpty) return false;

      // If not, swap array for next element
      previousListToMatch = matchCandidate.toList();
    }

    // Will always be true if the last element ended up being a candidate too
    return true;
  }
}
