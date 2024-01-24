import 'package:magical_version_bump/src/core/yaml_transformers/trackers/counter/generic_counter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

part 'custom_tracker.dart';
part 'format_util.dart';

abstract base class NodePathFormatter<FormatT extends TrackerKey<String>,
    InputT> {
  NodePathFormatter({
    FormatterTracker<FormatT>? tracker,
  }) : tracker = tracker ?? FormatterTracker<FormatT>();

  /// Stores the info for this formatter for easy access
  final FormatterTracker<FormatT> tracker;

  @protected
  ({List<TrackerKey<String>> keys, FormatT path}) extractFrom(InputT input);

  /// Each `TransformerManager` adds a value differently. See fine grained
  /// implementations for each.
  void add(int fileIndex, List<InputT> inputs) {
    for (final input in inputs) {
      final info = extractFrom(input);
      tracker.add(fileIndex: fileIndex, keys: info.keys, value: info.path);
    }
  }

  /// Each `TransformerManager` adds values differently. differently. See fine
  /// grained implementations for each.
  void addAll(List<(int fileIndex, List<InputT> inputs)> fileInputs) {
    for (final (fileIndex, outputs) in fileInputs) {
      add(fileIndex, outputs);
    }
  }

  String format({
    required bool isReplaceMode,
    required List<String> fileNames,
    required Counter<int, int> finderFileCounter,
    Counter<int, int>? replacerFileCounter,
  }) =>
      aggregateInfo(
        isReplaceMode: isReplaceMode,
        formatter: this,
        fileNames: fileNames,
        finderFileCounter: finderFileCounter,
        replacerFileCounter: replacerFileCounter,
      );
}
