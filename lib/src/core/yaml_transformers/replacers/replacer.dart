import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/map_extensions.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

part 'key_replacer.dart';
part 'value_replacer.dart';

/// Abstract class for rename keys/replacing values
///
/// [MagicalReplacer] & [MagicalRenamer] extend this
abstract class Replacer {
  Replacer({
    required List<ReplacementTargets> targets,
  }) {
    _replacementsToFind = normalizeReplacements(targets);
  }

  /// Targets to find and their replacements as keys
  late ReplacementsToFind _replacementsToFind;

  /// Join all targets that need to be replaced for a `Finder` to find
  @protected
  T generateTargets<T>({
    required bool areKeys,
  }) {
    // Get values
    final values = _replacementsToFind.values;

    // Get all keys with no duplicates
    final targets = <String>{for (final value in values) ...value}.toList();
    if (areKeys) {
      return (areGrouped: false, strictOrder: false, keys: targets) as T;
    }
    return targets as T;
  }

  /// Transforms replacement targets to `Map` where the replacement is the
  /// key while targets are the value
  @protected
  ReplacementsToFind normalizeReplacements(
    List<ReplacementTargets> targets,
  ) {
    final entries = targets.map((e) => MapEntry(e.replacement, e.targets));
    return <String, List<String>>{}..addEntries(entries);
  }

  /// Gets the matching replacements for a matched node.
  ///
  /// Key takeaway, if a key has another replacement candidate. By default,
  /// the first replacement will count. However, the last occuring will be used
  /// if specified by user.
  ///
  /// For keys, we will return a `Map<String, String>`, pairs, of key and its
  /// replacement.
  /// For values we just return the replacement.
  @protected
  T getReplacement<T>(
    MatchedNodeData matchedNodeData, {
    required bool checkForKey,
    bool useFirst = true,
  }) {
    // For keys, we need to loop all matched keys
    if (checkForKey) {
      final replacementPairs = <String, String>{};

      for (final matchedKey in matchedNodeData.matchedKeys) {
        final candidateReplacement = _getReplacementCandidate(
          matchedKey,
          useFirst: useFirst,
        );

        // Add key to be replaced as key, while its replacement as its value
        replacementPairs.addAll({matchedKey: candidateReplacement});
      }
      return replacementPairs as T;
    }

    // Just return the value instead as a string
    return _getReplacementCandidate(
      matchedNodeData.nodeData.data as String,
      useFirst: useFirst,
    ) as T;
  }

  /// Gets first replament based on requirement.
  String _getReplacementCandidate(
    String matcher, {
    required bool useFirst,
  }) {
    // Get all matches
    final candidates = _replacementsToFind.entries.where(
      (element) => element.value.contains(matcher),
    );

    // If using first add first value, if not use last replacement candidate
    return useFirst ? candidates.first.key : candidates.last.key;
  }

  /// Gets the corresponding targets for all subclasses of this type
  void getTargets();

  /// Replaces a matched node in a yaml map and returns an updated yaml map
  YamlMap replace(YamlMap yamlMap, {required MatchedNodeData matchedNodeData});
}
