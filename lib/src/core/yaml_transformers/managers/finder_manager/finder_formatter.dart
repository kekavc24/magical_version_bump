import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/formatter/formatter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';

final class FinderFormatter extends NodePathFormatter<MatchedNodeData> {
  FinderFormatter({super.tracker});

  @override
  ({List<TrackerKey<String>> keys, FormattedPathInfo pathInfo}) extractFrom(
    MatchedNodeData input,
  ) {
    // Remove duplicates before highlighting
    final matches = <String>{
      ...input.matchedKeys,
      input.matchedValue,
      ...input.matchedPairs.entries.map((e) => [e.key, e.value]).flattened,
    }.toList();

    return (
      keys: getKeysFromMatch(input),
      pathInfo: wrapMatches(path: input.toString(), matches: matches),
    );
  }
}
