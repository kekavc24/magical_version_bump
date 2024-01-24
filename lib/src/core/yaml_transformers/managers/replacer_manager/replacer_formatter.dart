import 'package:magical_version_bump/src/core/yaml_transformers/formatter/formatter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/managers/replacer_manager/replacer_manager.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';

final class ReplacerFormatter extends NodePathFormatter<
    DualTrackerKey<String, String>, ReplaceManagerOutput> {
  ReplacerFormatter({super.tracker});

  @override
  ({
    List<TrackerKey<String>> keys,
    DualTrackerKey<String, String> path,
  }) extractFrom(
    ReplaceManagerOutput input,
  ) {
    // Replace and wrap path with codes
    final wrapped = replaceAndWrap(
      path: input.oldPath,
      replacedKeys: input.origin == Origin.key,
      replacements: input.mapping,
    );

    return (
      keys: extractKey<List<TrackerKey<String>>>(
        origin: input.origin,
        value: input.mapping.keys,
        isReplacement: true,
      ),
      path: DualTrackerKey<String, String>.fromValue(
        key: wrapped.oldPath,
        otherKey: wrapped.updatedPath,
      ),
    );
  }
}
