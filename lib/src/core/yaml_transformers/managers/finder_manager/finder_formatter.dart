import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/formatter/formatter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';

final class FinderFormatter
    extends NodePathFormatter<TrackerKey<String>, MatchedNodeData> {
  FinderFormatter({super.tracker});

  @override
  ({List<TrackerKey<String>> keys, TrackerKey<String> path}) extractFrom(
    MatchedNodeData input,
  ) {
    // Remove duplicates before highlighting
    final matches = <String>{
      ...input.matchedKeys,
      input.matchedValue,
      ...input.matchedPairs.entries.map((e) => [e.key, e.value]).flattened,
    }.toList();

    // Wrap with ansicodes
    final pathToTrack = wrapMatches(path: input.toString(), matches: matches);

    return (
      keys: getKeysFromMatch(input),
      path: TrackerKey(key: pathToTrack, origin: Origin.custom),
    );
  }
}
