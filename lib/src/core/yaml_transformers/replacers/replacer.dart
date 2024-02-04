import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/extensions/map_extensions.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

part 'key_swapper.dart';
part 'value_replacer.dart';

typedef ReplacementOutput = ({
  YamlMap updatedMap,
  Map<String, String> mapping,
});

/// Abstract class for renaming keys/replacing values
///
/// [ValueReplacer] & [KeySwapper] extend this.
abstract class Replacer {
  Replacer(this.substituteToMatchers);

  /// Targets to find and their replacements as keys
  final Map<String, List<String>> substituteToMatchers;

  /// Join all targets that need to be replaced for a `Finder` to find
  @protected
  T generateTargets<T>({
    required bool areKeys,
  }) {
    // Get values
    final values = substituteToMatchers.values;

    // Get all keys with no duplicates
    final targets = <String>{for (final value in values) ...value}.toList();
    if (areKeys) {
      return (keys: targets, orderType: OrderType.loose) as T;
    }
    return targets as T;
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
      matchedNodeData.data,
      useFirst: useFirst,
    ) as T;
  }

  /// Gets first replament based on requirement.
  String _getReplacementCandidate(
    String matcher, {
    required bool useFirst,
  }) {
    // Get all matches
    final candidates = substituteToMatchers.entries.where(
      (element) => element.value.contains(matcher),
    );

    // If using first add first value, if not use last replacement candidate
    return useFirst ? candidates.first.key : candidates.last.key;
  }

  /// Gets the corresponding targets for all subclasses of this type
  T getTargets<T>();

  /// Replaces a matched node in a yaml map and returns an updated yaml map
  ReplacementOutput replace(
    Map<dynamic, dynamic> map, {
    required MatchedNodeData matchedNodeData,
  });
}
