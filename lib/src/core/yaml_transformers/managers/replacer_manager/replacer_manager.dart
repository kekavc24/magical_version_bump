import 'package:magical_version_bump/src/core/yaml_transformers/console_printer/console_printer.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/tracker.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';

part 'replacer_tracker.dart';

class ReplacerManager extends TransformerManager {
  ReplacerManager._({
    required super.files,
    required super.aggregator,
    super.printer,
    required this.commandType,
  }) : assert(
          !commandType.isFinder,
          'Only replace and rename commands are allowed',
        );

  factory ReplacerManager.create({
    required WalkSubCommandType commandType,
    required List<FileOutput> files,
    required Aggregator aggregator,
    ConsolePrinter? printer,
    required List<ReplacementTargets> targets,
  }) {
    _replacer = _getReplacer(commandType, targets: targets);

    _manager = _getManager(
      commandType,
      files: files,
      aggregator: aggregator,
      printer: printer,
      replacer: _replacer,
    );

    return ReplacerManager._(
      files: files,
      aggregator: aggregator,
      printer: printer,
      commandType: commandType,
    );
  }

  /// Indicates the command that using this manager. Accepts only
  /// [WalkSubCommandType.rename] or [WalkSubCommandType.replace] for now.
  final WalkSubCommandType commandType;

  /// Generates [MatchedNodeData] objects using a [Finder] for replacement
  static late FinderManager _manager;

  /// Represents a replacer used by this manager to rename keys or replace
  /// values.
  static late Replacer _replacer;

  /// Accesses the [MatchCounter] used by the [FinderManager] generating
  /// matches for this [ReplacerManager]
  MatchCounter get finderCounter => _manager.matchCounter;

  @override
  Future<void> transform() async {
    // Modifiable queue we can read and swap modifiable values back and forth
    final localQueue = [...yamlQueue];

    /// Accumulate all matches from [FinderManager]
    final matches = _manager.generate().toList();

    // TODO: Add implementations if matches are missing
    if (matches.isEmpty) {}

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

    for (final target in targets) {
      var file = localQueue[target.fileNumber]; // File to edit

      for (final match in target.matches) {
        final modifiedFile = _replacer.replace(file, matchedNodeData: match);

        file = modifiedFile.updatedMap;

        // TODO: Add to console format
        printer.addValuesReplaced(
          target.fileNumber,
          origin: commandType == WalkSubCommandType.rename
              ? Origin.key
              : Origin.value,
          replacements: modifiedFile.mapping,
          oldPath: match.toString(),
        );

        // Track current count of replacements
        super.incrementFileIndex(target.fileNumber);
      }

      localQueue[target.fileNumber] = file; // Swap with updated
    }
  }
}

Replacer _getReplacer(
  WalkSubCommandType commandType, {
  required List<ReplacementTargets> targets,
}) {
  return switch (commandType) {
    WalkSubCommandType.rename => KeySwapper(targets),
    _ => ValueReplacer(targets),
  };
}

FinderManager _getManager(
  WalkSubCommandType commandType, {
  required List<FileOutput> files,
  required Aggregator aggregator,
  ConsolePrinter? printer,
  required Replacer replacer,
}) {
  final manager = commandType == WalkSubCommandType.rename
      ? FinderManager.findKeys(
          files: files,
          aggregator: aggregator,
          printer: printer,
          keysToFind: replacer.getTargets() as KeysToFind,
        )
      : FinderManager.findValues(
          files: files,
          aggregator: aggregator,
          printer: printer,
          valuesToFind: replacer.getTargets() as ValuesToFind,
        );

  return manager;
}
