part of 'manager.dart';

class ReplacerManager extends TransformerManager {
  ReplacerManager._({
    required super.files,
    required super.aggregator,
    required super.printer,
    required this.commandType,
    required this.replacer,
    required this.manager,
  }) : assert(
          !commandType.isFinder,
          'Only replace and rename commands are allowed',
        );

  factory ReplacerManager.create({
    required WalkSubCommandType commandType,
    required List<FileOutput> files,
    required Aggregator aggregator,
    required ConsolePrinter printer,
    required List<ReplacementTargets> targets,
  }) {
    final replacer = _getReplacer(commandType, targets: targets);

    return ReplacerManager._(
      files: files,
      aggregator: aggregator,
      printer: printer,
      commandType: commandType,
      replacer: replacer,
      manager: _getManager(
        commandType,
        files: files,
        aggregator: aggregator,
        printer: printer,
        replacer: replacer,
      ),
    );
  }

  final WalkSubCommandType commandType;

  final FinderManager manager;

  final Replacer replacer;

  TransformTracker get finderTracker => manager.tracker;

  @override
  Future<void> transform() async {
    // Modifiable queue we can read and swap modifiable values back and forth
    final localQueue = QueueList.from(yamlQueue);

    for (final match in manager.getGenerator()) {
      var file = localQueue[match.currentFile]; // Get yaml file

      // Prevents unnecessary replacement for deeply nested keys
      var canReplace = true;

      ///
      /// For key rename, we check to prevent any unnecessary recursion on
      /// keys already renamed! Caveat of indexing to terminal value
      if (commandType == WalkSubCommandType.rename) {
        final keyPath = (replacer as MagicalRenamer).replaceDryRun(
          match.data,
        );

        /// Store file number and key path. Guarantees some level of uniqueness
        /// and also ties it to a file
        final keyInTracker = '${match.currentFile},$keyPath';

        // Make sure the key path has just 1 of it
        if (getCountOfValue(keyInTracker, origin: Origin.key) == 1) {
          canReplace = false;
        } else {
          incrementWithStrings([keyInTracker], origin: Origin.key);
        }
      }

      // Replace if current value is not being tracked.
      if (canReplace) {
        final output = replacer.replace(file, matchedNodeData: match.data);

        // Swap old file in queue with new one
        localQueue.replaceRange(
          match.currentFile,
          match.currentFile,
          [output.updatedMap],
        );

        // Add to printer
        _printer.addValuesReplaced(
          match.currentFile,
          origin: commandType == WalkSubCommandType.rename
              ? Origin.key
              : Origin.value,
          replacements: output.mapping,
          oldPath: match.data.toString(),
        );
      }
    }
  }
}

Replacer _getReplacer(
  WalkSubCommandType commandType, {
  required List<ReplacementTargets> targets,
}) {
  return switch (commandType) {
    WalkSubCommandType.rename => MagicalRenamer(targets),
    _ => MagicalReplacer(targets),
  };
}

FinderManager _getManager(
  WalkSubCommandType commandType, {
  required List<FileOutput> files,
  required Aggregator aggregator,
  required ConsolePrinter printer,
  required Replacer replacer,
}) {
  final manager = commandType == WalkSubCommandType.rename
      ? FinderManager.findKeys(
          files: files,
          aggregator: aggregator,
          printer: printer,
          keysToFind: (replacer as MagicalRenamer).getTargets(),
        )
      : FinderManager.findValues(
          files: files,
          aggregator: aggregator,
          printer: printer,
          valuesToFind: (replacer as MagicalReplacer).getTargets(),
        );

  return manager;
}
