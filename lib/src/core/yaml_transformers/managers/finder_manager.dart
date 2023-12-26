part of 'manager.dart';

enum FinderType { byValue, bySearch, both }

typedef FindManagerOutput = ({
  int currentFile,
  MatchedNodeData data,
});

class FinderManager extends TransformerManager {
  FinderManager._({
    required super.files,
    required super.aggregator,
    required super.printer,
  });

  factory FinderManager.fullSetup({
    required List<FileOutput> files,
    required Aggregator aggregator,
    required ConsolePrinter printer,
    required FinderType finderType,
    required KeysToFind? keysToFind,
    required ValuesToFind? valuesToFind,
    required PairsToFind? pairsToFind,
  }) {
    /// Save history when, [!applyToEachFile && applyToEachArg] is false
    final saveCounterHistory =
        !(!aggregator.applyToEachFile && aggregator.applyToEachArg);

    _finder = _setUpFinder(
      files.first.fileAsMap,
      saveCounterToHistory: saveCounterHistory,
      finderType: finderType,
      keysToFind: keysToFind,
      valuesToFind: valuesToFind,
      pairsToFind: pairsToFind,
    );

    return FinderManager._(
      files: files,
      aggregator: aggregator,
      printer: printer,
    );
  }

  factory FinderManager.findValues({
    required List<FileOutput> files,
    required Aggregator aggregator,
    required ConsolePrinter printer,
    required ValuesToFind valuesToFind,
  }) {
    return FinderManager.fullSetup(
      files: files,
      aggregator: aggregator,
      printer: printer,
      keysToFind: null,
      valuesToFind: valuesToFind,
      pairsToFind: null,
      finderType: FinderType.byValue,
    );
  }

  factory FinderManager.findKeys({
    required List<FileOutput> files,
    required Aggregator aggregator,
    required ConsolePrinter printer,
    required KeysToFind keysToFind,
  }) {
    return FinderManager.fullSetup(
      files: files,
      aggregator: aggregator,
      printer: printer,
      finderType: FinderType.byValue,
      keysToFind: keysToFind,
      valuesToFind: null,
      pairsToFind: null,
    );
  }

  /// Indicates a finder used by this manager to generate matches.
  /// 
  /// This manager just queues file based on some conditions.
  static late Finder _finder;

  /// Accesses the counter used by the finder in this [FinderManager].
  /// 
  /// Accessing this before ever calling [Finder.find] may result in a 
  /// null exception being thrown.
  MatchCounter get matchCounter => _finder.counter!;

  ///
  Iterable<FinderOutput> _internalGenerator() {
    return _finder.find(
      aggregateType: aggregator.type,
      applyToEach: aggregator.applyToEachArg,
      count: aggregator.count,
    );
  }

  @override
  Future<void> transform() async {
    // Loop all matches and add to printer
    for (final output in generate()) {
      _printer.addValuesFound(output.currentFile, output.data);
    }
  }

  Iterable<FindManagerOutput> generate() sync* {
    final applyToEachFile = super._aggregator.applyToEachFile;
    final applyToEachArg = super._aggregator.applyToEachArg;
    final count = super._aggregator.count;

    /// Finding values is the hardest part.
    ///
    /// Rules for each condition of the [Aggregator] based on:
    ///   * [applyToEachFile] - applies conditions to each file
    ///   * [applyToEachArg] - applies to each argument to find. This is
    ///      handled seamlessly by the [Finder] itself
    ///
    /// This manager handles [applyToEachFile].
    ///
    /// When [applyToEachFile] is [false] and :
    ///
    ///   * [applyToEachArg] is [false] - Always peek the count of values
    ///     obtained so far for each file at the end of the loop iteration and
    ///     terminate when count is reached for surety. [Finder] ensures we
    ///     never exceed count for each argument but may return less which will
    ///     require us to look in the next file.
    ///
    ///   * [applyToEachArg] is [true] - Arguments get a wildcard.
    ///     Only condition that never uses [CounterWithHistory] functionality
    ///     of [Finder]. Each argument gets an equal chance to get to specified
    ///     count when not [AggregateType.all]. Even if we have to index
    ///     every file & check!
    ///
    /// When [applyToEachFile] is [true] and :
    ///
    ///   * [applyToEachArg] is [false] - for each file we take a
    ///     specified count when not [AggregateType.all]. [Finder] handles the
    ///     trivial `!applyToEach` which guarantees exact or less based on
    ///     file passed.
    ///
    ///   * [applyToEachArg] is [true] - Files get a wildcard. Each
    ///     file gets equal chance to reach the count of each argument when
    ///     not [AggregateType.all]. Even if we have to index the whole file!

    final numOfFiles = yamlQueue.length;
    final localQueue = QueueList.from(yamlQueue); // Local editable queue

    /// Keep track of file index to use as a cursor. We use it to reset the
    /// last counter state to history. For easy access by [ConsolePrinter]
    var fileIndex = 0;

    /// Label for our loop queueing file for [Finder]
    fileLooper:
    do {
      fileIndex = numOfFiles - localQueue.length; // File index
      final yamlMap = localQueue.removeFirst(); // Current file

      // Add yaml if we are not starting. Finder always has the first file
      if (fileIndex != 0) {
        // Swap and use previous file.
        _finder.swapMap(yamlMap, cursor: fileIndex - 1);
      }

      // Loop all matches
      for (final output in _internalGenerator()) {
        // Yield value first before checking conditions.
        yield (currentFile: fileIndex, data: output.data);

        super._incrementFileIndex(fileIndex);

        /// If we are finding all, just increment file count and continue.
        ///
        /// [Finder] handles everything if each file gets equal chance when
        /// [applyToEachFile] is [true]
        ///
        if (aggregator.type == AggregateType.all || applyToEachFile) continue;

        ///
        /// When [applyToEachFile] is [false], we break loop only when:
        ///
        /// * [applyToEach] is [true] and output limit was reached since
        ///   the counter state is never reset. [MatchCounter] unknowingly
        ///   returns true while still matching a new file.
        ///
        /// * [applyToEach] is [false] just uses the file counter for this
        ///   [FindManager] which tracks how many values where found in each
        ///   file
        ///
        if ((applyToEachArg && output.reachedLimit) ||
            (!applyToEachArg && _managerCounter.getSumOfCount() == count)) {
          break fileLooper;
        }
      }
    } while (localQueue.isNotEmpty);

    /// Reset counter with current file index to history.
    ///
    /// This index denotes the file whose counter is active. No need to
    /// subtract "1" to go back to previous file.
    _finder.counter!.reset(cursor: fileIndex);
  }
}

F _setUpFinder<F extends Finder>(
  YamlMap yamlMap, {
  required FinderType finderType,
  required bool saveCounterToHistory,
  KeysToFind? keysToFind,
  ValuesToFind? valuesToFind,
  PairsToFind? pairsToFind,
}) {
  return switch (finderType) {
    _ => ValueFinder.findInYaml(
        yamlMap,
        saveCounterToHistory: saveCounterToHistory,
        keysToFind: keysToFind,
        valuesToFind: valuesToFind,
        pairsToFind: pairsToFind,
      ) as F,
  };
}
