import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/counter/transform_counter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:mason_logger/mason_logger.dart';

part 'printer_util.dart';

typedef TrackedValue = TrackerKey<String>;
typedef DualTrackedValue = DualTrackerKey<String, String>;

/// The `key` in this map denotes the value found/replaced in yaml/json
/// based on its origin.
///
/// An `origin` is defined as where this value was found i.e. at a key/value/
/// as a pair of 2 keys or a key & value.
///
/// The `value` of this map denotes the full path from root key to a terminal
/// value where it was found/replaced.
///
/// For values found, a [TrackedValue] is used with one path whereas a
/// [DualTrackedValue] is used for values replaced to store the old path
/// and new path after value was replaced.
typedef AggregatedFileInfo = Map<TrackedValue, List<TrackedValue>>;

/// Each file name reconciled with its logs for easy display in console
typedef ReconciledLogs = Map<String, List<String>>;

base class ConsolePrinter {
  ConsolePrinter({
    ConsoleViewFormat? format,
    Logger? logger,
  })  : _format = format ?? ConsoleViewFormat.grouped,
        _logger = logger ?? Logger();

  /// How to print values found to console
  final ConsoleViewFormat _format;

  /// Logger to use to print to console
  final Logger _logger;

  /// Stores the [AggregatedFileInfo] for each file based on index.
  final Map<int, AggregatedFileInfo> _fileInfos = {};

  /// Save values to tracker based on file index
  void _saveToTracker(int index, List<TrackedValue> keys, TrackedValue value) {
    // If console view format is live, print directly
    if (_format == ConsoleViewFormat.live) {
      _printToConsole(index, keys, value);
    }

    // Get from file info, if missing add
    final aggregatedInfo = _fileInfos[index] ?? {};

    for (final key in keys) {
      aggregatedInfo.update(
        key,
        (existing) => [...existing, value],
        ifAbsent: () => [value],
      );
    }

    _fileInfos[index] = aggregatedInfo; // Direct update
  }

  void addValuesFound(int index, MatchedNodeData data) {
    // Remove duplication before highlighting
    final matches = <String>{
      ...data.matchedKeys,
      data.matchedValue,
      ...data.matchedPairs.entries.map((e) => [e.key, e.value]).flattened,
    }.toList();

    // Wrap with ansicodes
    final pathToTrack = wrapMatches(path: data.toString(), matches: matches);
    final trackedPath = TrackedValue(key: pathToTrack, origin: Origin.custom);

    // Get all keys that where found at this path
    final trackerKeys = _getKeysFromMatch(data);

    // Save to tracker based on file index
    _saveToTracker(index, trackerKeys, trackedPath);
  }

  void addValuesReplaced(
    int index, {
    required Origin origin,
    required Map<String, String> replacements,
    required String oldPath,
  }) {
    // Replace and wrap path with codes
    final wrapped = replaceAndWrap(
      path: oldPath,
      replacedKeys: origin == Origin.key,
      replacements: replacements,
    );

    // Create tracker keys from replacement values
    final keys = _extractKey<List<TrackedValue>>(
      origin: origin,
      value: replacements.keys,
      isReplacement: true,
    );

    final trackedPaths = DualTrackedValue.fromValue(
      key: wrapped.oldPath,
      otherKey: wrapped.updatedPath,
    );

    // Save all
    _saveToTracker(index, keys, trackedPaths);
  }

  void _printToConsole(int index, List<TrackedValue> keys, TrackedValue value) {
    // Print direct to console with index since file names aren't reconciled yet
    final consoleBuffer = StringBuffer(
      createHeader(format: _format, fileInfo: index),
    );

    // Loop all keys and append tracked value
    for (final key in keys) {
      final keyInfo = formatInfo(
        key: key.toString(),
        trackedValues: [value],
        foundCount: 1,
      );

      consoleBuffer.write(keyInfo);
    }

    _logger.info(consoleBuffer.toString()); // Print to console
  }

  ReconciledLogs _getLogs({
    required bool useHistory,
    required List<String> fileNames,
    
    required MatchCounter matchCounter,
    required bool isReplace,
  }) {
    final fileLogs = <int, List<String>>{}; // Logs for each file

    // Loop each file entry with logs to be formatted
    for (final fileEntry in _fileInfos.entries) {
      final fileIndex = fileEntry.key;
      final formattedLogs = <String>[];

      // Loop entries linked to a file number
      for (final logEntry in fileEntry.value.entries) {
        final logKey = logEntry.key;
        final logValue = logEntry.value;

        int? foundCount;

        if (isReplace) {
          foundCount = matchCounter.getCountFromHistory(
            fileIndex,
            logKey.key,
            logKey.origin,
          );
        } else {
          foundCount = logValue.length;
        }

        final log = formatInfo(
          key: logKey.toString(),
          trackedValues: logValue,
          foundCount: foundCount ?? 0,
          replacedCount: isReplace ? logValue.length : null,
        );

        formattedLogs.add(log);
      }

      // Add logs using file index
      fileLogs[fileIndex] = formattedLogs;
    }

    /// File names will have all files unlike our logs.
    ///
    /// Sometimes a file may not have values we are searching for and may never
    /// be stored in this aggregator which only tracks values found/replaced
    return fileNames.foldIndexed({}, (index, previous, element) {
      previous.addAll({element: fileLogs[index] ?? []});
      return previous;
    });
  }

  void aggregateInfo(
    Aggregator aggregator, {
    required List<String> fileNames,
    required ManagerCounter managerCounter,
    required MatchCounter matchCounter,
    required bool isReplace,
  }) {
    // Aggregated info buffer
    final aggregateBuffer = StringBuffer();

    /// Only use history for trackers that were reset.
    ///
    /// In `!applyToEachFile` && `applyToEach`, we never reset the tracker,
    /// since we terminate once all our arguments each reach specified count
    ///
    /// Thus we use history when not in above condition
    final useHistory =
        !(!aggregator.applyToEachFile && aggregator.applyToEachArg);

    final linkedLogs = _getLogs(
      useHistory: useHistory,
      fileNames: fileNames,
      matchCounter: matchCounter,
      isReplace: isReplace,
    );

    // Loop all logs linked to a file
    for (final (index, log) in linkedLogs.entries.indexed) {
      final header = createHeader(
        format: _format,
        fileInfo: log.key,
        fileMatches: managerCounter.getCount(index, origin: Origin.custom),
      );

      // Add to buffer
      aggregateBuffer
        ..write(header)
        ..write(log.value.join());
    }

    // Print to console
    _logger.info(aggregateBuffer.toString());
  }
}
