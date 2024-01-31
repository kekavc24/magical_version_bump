import 'package:magical_version_bump/src/core/yaml_transformers/formatter/formatter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/managers/replacer_manager/replacer_manager.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';

final class ReplacerFormatter extends NodePathFormatter<ReplaceManagerOutput> {
  ReplacerFormatter({super.tracker});

  @override
  ({List<TrackerKey<String>> keys, FormattedPathInfo pathInfo}) extractFrom(
    ReplaceManagerOutput input,
  ) {
    return (
      keys: extractKey<List<TrackerKey<String>>>(
        origin: input.origin,
        value: input.mapping.keys,
        isReplacement: true,
      ),
      pathInfo: replaceAndWrap(
        path: input.oldPath,
        replacedKeys: input.origin == Origin.key,
        replacements: input.mapping,
      ),
    );
  }
}
