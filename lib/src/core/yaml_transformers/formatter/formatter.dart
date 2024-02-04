import 'package:magical_version_bump/src/core/yaml_transformers/trackers/counter/generic_counter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:mason_logger/mason_logger.dart';

part 'custom_tracker.dart';
part 'formatter_util.dart';

/// Formats info for each node based on matches found/replaced.
abstract base class NodePathFormatter<InputT> {
  NodePathFormatter({
    FormatterTracker? tracker,
  }) : tracker = tracker ?? FormatterTracker();

  /// Stores the info for this formatter for easy access
  final FormatterTracker tracker;

  /// Each `TransformerManager` extracts values differently. See fine grained
  /// implementations for each.
  ({List<TrackerKey<String>> keys, FormattedPathInfo pathInfo}) extractFrom(
    InputT input,
  );

  /// Adds inputs from a single file based on its index to this formatter's
  /// tracker.
  void add(int fileIndex, List<InputT> inputs) {
    for (final input in inputs) {
      final info = extractFrom(input);
      tracker.add(
        fileIndex: fileIndex,
        keys: info.keys,
        pathInfo: info.pathInfo,
      );
    }
  }

  /// Adds inputs from multiple files based on their index to this formatter's
  /// tracker.
  void addAll(List<(int fileIndex, List<InputT> inputs)> fileInputs) {
    for (final (fileIndex, outputs) in fileInputs) {
      add(fileIndex, outputs);
    }
  }

  /// Formats & aggregates all info linked to each file based on info stored
  /// in this formatter's tracker.
  String format({
    required bool isReplaceMode,
    required List<String> fileNames,
    required Counter<int, int> finderFileCounter,
    Counter<int, int>? replacerFileCounter,
  }) {
    if (isReplaceMode) {
      assert(
        replacerFileCounter != null,
        'Missing counter from replace manager!',
      );
    }

    final aggregateBuffer = StringBuffer();

    // Reset the last tracker to ease access from history
    tracker.reset(cursor: tracker.currentCursor);

    // Use index to access each file info, order is always maintained
    for (final (index, fileName) in fileNames.indexed) {
      final infoToAggregate = tracker.getFromHistory(index);

      // Add top level header with info about
      aggregateBuffer.write(
        createHeader(
          isReplaceMode: isReplaceMode,
          fileName: fileName,
          countOfMatches: finderFileCounter.getCount(
            index,
            origin: Origin.custom,
          ),
          countOfReplacements: replacerFileCounter?.getCount(
            index,
            origin: Origin.custom,
          ),
        ),
      );

      if (infoToAggregate == null) continue;

      // Loop all files and create their tree-like string
      for (final entry in infoToAggregate.entries) {
        final formattedInfo = formatInfo(
          isReplaceMode: isReplaceMode,
          key: entry.key.key, // weird?
          formattedPaths: entry.value,
        );

        aggregateBuffer.write(formattedInfo);
      }
    }

    return aggregateBuffer.toString();
  }
}
