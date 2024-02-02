import 'package:magical_version_bump/src/core/yaml_transformers/managers/replacer_manager/replacer_formatter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/counter/generic_counter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:mason_logger/mason_logger.dart';

part 'replacer_tracker.dart';

typedef ReplaceManagerOutput = ({
  Origin origin,
  Map<String, String> mapping,
  String oldPath,
});

typedef ModifiedFiles = ({int fileIndex, Map<dynamic, dynamic> modifiedFile});

class ReplacerManager extends TransformerManager<ReplaceManagerOutput> {
  ReplacerManager._({
    required super.fileQueue,
    required super.aggregator,
    required super.logger,
    required this.commandType,
    required Map<String, List<String>> substituteToMatchers,
  })  : assert(!commandType.isFinder, 'Find command not allowed'),
        super(formatter: ReplacerFormatter()) {
    // Replacer based on replace mode
    _replacer = switch (commandType) {
      WalkSubCommandType.rename => KeySwapper(substituteToMatchers),
      _ => ValueReplacer(substituteToMatchers),
    };

    _finderManager = commandType == WalkSubCommandType.rename
        ? FinderManager.findKeys(
            fileQueue: fileQueue,
            aggregator: aggregator,
            keysToFind: _replacer.getTargets<KeysToFind>(),
          )
        : FinderManager.findValues(
            fileQueue: fileQueue,
            aggregator: aggregator,
            valuesToFind: _replacer.getTargets<ValuesToFind>(),
          );
  }

  ReplacerManager.defaultSetup({
    required WalkSubCommandType commandType,
    required List<Map<dynamic, dynamic>> fileQueue,
    required Aggregator aggregator,
    required Logger logger,
    required Map<String, List<String>> substituteToMatchers,
  }) : this._(
          fileQueue: fileQueue,
          aggregator: aggregator,
          logger: logger,
          commandType: commandType,
          substituteToMatchers: substituteToMatchers,
        );

  /// Indicates the command that using this manager. Accepts only
  /// [WalkSubCommandType.rename] or [WalkSubCommandType.replace] for now.
  final WalkSubCommandType commandType;

  /// Generates [MatchedNodeData] objects using a [Finder] for replacement
  late FinderManager _finderManager;

  /// Represents a replacer used by this manager to rename keys or replace
  /// values.
  late Replacer _replacer;

  Iterable<ModifiedFiles>? modifiedFiles;

  /// Obtains the counter used by the [FinderManager] used to manage the
  /// finding of matches in different files
  Counter<int, int> get finderManagerCounter => _finderManager.managerCounter;

  @override
  Future<void> transform() async {
    final finderProgress = showProgress(
      ManagerProgress.findingMatches,
      info: 'Finding matches to replace',
    );

    // Modifiable queue we can read and swap modifiable values back and forth
    final localQueue = [...fileQueue];

    /// Accumulate all matches from [FinderManager]
    final matches = _finderManager.generate().toList();

    if (matches.isEmpty) {
      finderProgress.fail('No matches found');
      return;
    }

    finderProgress.complete();

    final replacerProgress = showProgress(ManagerProgress.replacingValues);

    var targets = <TrackerOutput>[];

    if (commandType == WalkSubCommandType.rename) {
      final tracker = ReplacerTracker()..addAll(matches);

      targets.addAll(tracker.getMatches());
    } else {
      targets = matches
          .fold(<int, List<MatchedNodeData>>{}, (previousValue, element) {
            previousValue.update(
              element.currentFile,
              (value) => [...value, element.data],
              ifAbsent: () => [element.data],
            );
            return previousValue;
          })
          .entries
          .map((e) => (fileNumber: e.key, matches: e.value))
          .toList();
    }

    final accumulator = <int, List<ReplaceManagerOutput>>{};

    for (final target in targets) {
      var file = localQueue[target.fileNumber]; // File to edit

      for (final match in target.matches) {
        final modifiedFile = _replacer.replace(file, matchedNodeData: match);

        file = modifiedFile.updatedMap;

        final output = (
          origin: commandType == WalkSubCommandType.rename
              ? Origin.key
              : Origin.value,
          mapping: modifiedFile.mapping,
          oldPath: match.toString(),
        );

        accumulator.update(
          target.fileNumber,
          (current) => [...current, output],
          ifAbsent: () => [output],
        );

        // Track current count of replacements for each file
        super.incrementFileIndex(target.fileNumber);
      }

      localQueue[target.fileNumber] = file; // Swap with updated
    }

    formatter.addAll(
      accumulator.entries
          .map((element) => (element.key, element.value))
          .toList(),
    );

    // Add modified files
    modifiedFiles = accumulator.keys.map(
      (element) => (fileIndex: element, modifiedFile: localQueue[element]),
    );

    replacerProgress.complete(
      'Replaced matches in ${accumulator.length} file(s)',
    );
  }
}
