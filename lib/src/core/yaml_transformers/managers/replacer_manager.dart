part of 'manager.dart';

class ReplacerManager extends TransformerManager {
  ReplacerManager._({
    required super.files,
    required super.aggregator,
    required this.commandType,
    required this.replacer,
    required this.generator,
  });

  factory ReplacerManager.create({
    required WalkSubCommandType commandType,
    required List<FileOutput> files,
    required Aggregator aggregator,
    required List<ReplacementTargets> targets,
    Iterable<FindManagerOutput>? generator,
    Replacer? replacer,
  }) {
    assert(
      !commandType.isFinder,
      'Only replace and rename commands are supported for now',
    );

    final replacerForManager = replacer ??
        _getReplacer(
          commandType,
          targets: targets,
        );

    return ReplacerManager._(
      files: files,
      aggregator: aggregator,
      commandType: commandType,
      replacer: replacerForManager,
      generator: generator ??
          _getGenerator(
            commandType,
            files: files,
            aggregator: aggregator,
            replacer: replacerForManager,
          ),
    );
  }

  final WalkSubCommandType commandType;

  final Iterable<FindManagerOutput> generator;

  final Replacer replacer;

  @override
  Future<void> transform() async {
    // Modifiable queue we can read and swap modifiable values back and forth
    final localQueue = QueueList.from(yamlQueue);

    for (final output in generator) {
      var file = localQueue[output.currentFile]; // Get yaml file

      // Prevents unnecessary replacement for deeply nested keys
      var canReplace = true;

      ///
      /// For key rename, we check to prevent any unnecessary recursion on
      /// keys already renamed! Caveat of indexing to terminal value
      if (commandType == WalkSubCommandType.rename) {
        final keyPath = (replacer as MagicalRenamer).replaceDryRun(
          output.data,
        );

        /// Store file number and key path. Guarantees some level of uniqueness
        /// and also ties it to a file
        final keyInTracker = '${output.currentFile},$keyPath';

        // Make sure the key path has just 1 of it
        if (getCountOfValue(keyInTracker, origin: Origin.key) == 1) {
          canReplace = false;
        } else {
          incrementWithStrings([keyInTracker], origin: Origin.key);
        }
      }

      // Replace if current value is not being tracked.
      if (canReplace) {
        file = replacer.replace(file, matchedNodeData: output.data);

        // Swap old file in queue with new one
        localQueue.replaceRange(
          output.currentFile,
          output.currentFile,
          [file],
        );
      }
    }

    // TODO: Swap the old yaml map in file saved with new yaml map
    // TODO: Add match formatter/aggregator
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

Iterable<FindManagerOutput> _getGenerator(
  WalkSubCommandType commandType, {
  required List<FileOutput> files,
  required Aggregator aggregator,
  required Replacer replacer,
}) {
  final manager = commandType == WalkSubCommandType.rename
      ? FinderManager.findeKeys(
          files: files,
          aggregator: aggregator,
          keysToFind: (replacer as MagicalRenamer).getTargets(),
        )
      : FinderManager.findValues(
          files: files,
          aggregator: aggregator,
          valuesToFind: (replacer as MagicalReplacer).getTargets(),
        );

  return manager.getGenerator();
}
