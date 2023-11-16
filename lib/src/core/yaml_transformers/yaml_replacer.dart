part of 'yaml_transformer.dart';

/// Find and Replace.
class MagicalReplacer {
  MagicalReplacer({
    required Finder finder,
    required YamlMap yamlMap,
    required ReplacementsToFind keyReplacements,
    required ReplacementsToFind valueReplacements,
  })  : _finder = finder,
        _targetMap = yamlMap,
        _keyReplacements = keyReplacements,
        _valueReplacements = valueReplacements;

  ///
  factory MagicalReplacer.withDefaultFinder(
    YamlMap yamlMap, {
    required List<ReplacementTargets> targets,
  }) {
    final replacements = _splitTargets(targets);

    return MagicalReplacer(
      finder: MagicalFinder.setUp(
        yamlMap,
        keysToFind: _generateTargets<KeysToFind>(
          replacements.withKeys.values,
          areKeys: true,
        ),
        valuesToFind: _generateTargets<ValuesToFind>(
          replacements.withValues.values,
          areKeys: false,
        ),
      ),
      yamlMap: yamlMap,
      keyReplacements: replacements.withKeys,
      valueReplacements: replacements.withValues,
    );
  }

  /// Reusable map to be updated
  final YamlMap _targetMap;

  /// A list of replacements with targets
  final ReplacementsToFind _keyReplacements;
  final ReplacementsToFind _valueReplacements;

  /// A finder that returns spits out values synchronously if any are found.
  ///
  /// For now, we are just using the [ MagicalFinder ] which finds based on
  /// value.
  ///
  /// Later, we may include search functionality.
  final Finder _finder;

  /// Finder generator. Depending on needs.
  Iterable<MatchedNodeData> getFinderGenerator({
    required bool ignoreCount,
    int? count,
  }) {
    if (ignoreCount) return _finder.findAllSync();

    // If count is null, just return 1 value
    return _finder.findByCount(count ?? 1);
  }

  /// Join all keys that need to be replaced for [ MagicalFinder ] to find
  static T _generateTargets<T>(
    Iterable<List<String>> values, {
    required bool areKeys,
  }) {
    // Get all keys with no duplicates
    final targets = <String>{for (final value in values) ...value}.toList();
    if (areKeys) {
      return (areGrouped: false, strictOrder: false, keys: targets) as T;
    }
    return targets as T;
  }

  /// Splits and creates 2 maps. One with keys to be replaced, other with values
  static ({
    ReplacementsToFind withKeys,
    ReplacementsToFind withValues,
  }) _splitTargets(
    List<ReplacementTargets> targets,
  ) {
    final withKeys = <String, List<String>>{};
    final withValues = <String, List<String>>{};

    // Loop all add to relevant map
    for (final target in targets) {
      if (target.areKeys) {
        withKeys.addAll({target.replacement: target.targets});
      } else {
        withValues.addAll({target.replacement: target.targets});
      }
    }

    return (withKeys: withKeys, withValues: withValues);
  }

  ReplacementInfo replace({required bool ignoreCount, int? count}) {
    // Our modifiable map
    var modifiableMap = {..._targetMap};

    // Get generator
    final generator = getFinderGenerator(
      ignoreCount: ignoreCount,
      count: count,
    );

    // Keep track of all replacements. All are ignored until they are removed
    final ignoredReplacements = [
      ..._keyReplacements.keys,
      ..._valueReplacements.keys,
    ];

    final successfulReplaments = <String>[];

    // Now start generator to get matched nodes
    for (final matchedNode in generator) {
      // Get replacement for keys
      final keyPairReplacement = matchedNode.matchedKeys.isEmpty
          ? <String, String>{}
          : getReplacementKeys<KeyAndReplacement>(
              matchedNode,
              checkForKey: true,
              useFirst: true,
            );

      // Get replacement for value
      final valueReplacement = matchedNode.matchedValue.isEmpty
          ? null
          : getReplacementKeys<String>(matchedNode, useFirst: true);

      // Recursively update map
      final updatedMap = modifiableMap.recursivelyUpdate(
        valueReplacement,
        target: matchedNode.nodeData.key,
        path: matchedNode.nodeData.precedingKeys,
        updateMode: UpdateMode.replace,
        keyAndReplacement: keyPairReplacement,
        valueToReplace: valueReplacement == null
            ? null
            : matchedNode.nodeData.data as String,
      );

      modifiableMap = updatedMap; // Swap

      // Update tracker
      final replacementsToRemove = <String>[];

      if (keyPairReplacement.isNotEmpty) {
        replacementsToRemove.addAll(keyPairReplacement.values);
      }

      if (valueReplacement != null) replacementsToRemove.add(valueReplacement);

      ignoredReplacements.removeWhere(replacementsToRemove.contains);
      successfulReplaments.addAll(replacementsToRemove.toSet());
    }

    return (
      replacedAll: ignoredReplacements.isEmpty,
      updatedMap: YamlMap.wrap(modifiableMap),
      infoStats: (
        successful: successfulReplaments,
        failed: ignoredReplacements,
      ),
    );
  }

  /// Get the matching replacements for a matched node.
  ///
  /// Key takeaway, if a key has another replacement candidate. By default,
  /// the first replacement will count. However, the last occuring will be used
  /// if specified by user.
  ///
  /// For keys, we will return a `Map<String, String>`, pairs, of key and its
  /// replacement.
  /// For values we just return the replacement.
  T getReplacementKeys<T>(
    MatchedNodeData matchedNodeData, {
    bool checkForKey = false,
    required bool useFirst,
  }) {
    // For keys, we need to loop all matched keys
    if (checkForKey) {
      final replacementPairs = <String, String>{};

      for (final matchedKey in matchedNodeData.matchedKeys) {
        final candidateReplacement = _getReplacementCandidate(
          matchedKey,
          checkForKey: true,
          useFirst: useFirst,
        );

        replacementPairs.addAll({matchedKey: candidateReplacement});
      }
      return replacementPairs as T;
    }

    return _getReplacementCandidate(
      matchedNodeData.nodeData.data as String,
      useFirst: false,
    ) as T;
  }

  /// Get first replament based on requirement.
  String _getReplacementCandidate(
    String matcher, {
    bool checkForKey = false,
    required bool useFirst,
  }) {
    final iterable =
        checkForKey ? _keyReplacements.entries : _valueReplacements.entries;

    // Get all keys that match the key
    final candidates = iterable.where(
      (element) => element.value.contains(matcher),
    );

    // If using first add first value, if not use last replacement candidate
    return useFirst ? candidates.first.key : candidates.last.key;
  }
}
