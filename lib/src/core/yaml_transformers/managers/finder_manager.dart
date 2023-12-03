part of 'manager.dart';

enum FinderType { byValue, bySearch, both }

typedef FindManagerOutput = ({
  int currentFile,
  MatchedNodeData data,
  bool reachedLimit,
});

class FinderManager extends TransformerManager implements ManageByCount {
  FinderManager._({
    required super.files,
    required super.aggregator,
    required KeysToFind keysToFind,
    required ValuesToFind valuesToFind,
    required PairsToFind pairsToFind,
    required FinderType finderType,
  })  : _finderType = finderType,
        _keysToFind = keysToFind,
        _valuesToFind = valuesToFind,
        _pairsToFind = pairsToFind;

  factory FinderManager.forFinder({
    required List<FileOutput> files,
    required Aggregator aggregator,
    required KeysToFind keysToFind,
    required ValuesToFind valuesToFind,
    required PairsToFind pairsToFind,
    FinderType? finderType,
  }) {
    return FinderManager._(
      files: files,
      aggregator: aggregator,
      finderType: finderType ?? FinderType.byValue,
      keysToFind: keysToFind,
      valuesToFind: valuesToFind,
      pairsToFind: pairsToFind,
    );
  }

  factory FinderManager.findValues({
    required List<FileOutput> files,
    required Aggregator aggregator,
    required ValuesToFind valuesToFind,
  }) {
    return FinderManager._(
      files: files,
      aggregator: aggregator,
      keysToFind: (keys: [], orderType: OrderType.loose),
      valuesToFind: valuesToFind,
      pairsToFind: {},
      finderType: FinderType.byValue,
    );
  }

  factory FinderManager.findeKeys({
    required List<FileOutput> files,
    required Aggregator aggregator,
    required KeysToFind keysToFind,
  }) {
    return FinderManager._(
      files: files,
      aggregator: aggregator,
      keysToFind: keysToFind,
      valuesToFind: [],
      pairsToFind: {},
      finderType: FinderType.byValue,
    );
  }

  late FinderType _finderType;

  late KeysToFind _keysToFind;
  late ValuesToFind _valuesToFind;
  late PairsToFind _pairsToFind;

  /// Obtains the current generator to be used/ currently in use by
  /// this manager
  Iterable<FindManagerOutput> getGenerator() {
    return aggregator.type == AggregateType.all
        ? transformAll(resetTracker: true)
        : transformByCount(
            aggregator.count!,
            applyToEach: aggregator.applyToEach,
          );
  }

  /// Prefills the tracker with keys for accurate value tracking
  void _prefillTracker() {
    for (final data in keysToPrefill()) {
      _tracker.prefill(data.keys, origin: data.origin);
    }
  }

  @override
  Future<void> transform() async {
    
    // TODO: Add match formatter/aggregator
    for (final match in getGenerator()) {}
  }

  @override
  Iterable<FindManagerOutput> transformByCount(
    int count, {
    required bool applyToEach,
    bool applyToEachFile = true,
  }) sync* {
    // Prefill tracker
    _prefillTracker();

    /// If we are not applying to each file and neither are we applying to
    /// to each argument. Return just count
    if (!applyToEachFile && !applyToEach) {
      yield* transformAll(resetTracker: true).take(count);
    }

    ///
    /// For remaining conditions:
    /// * `applyToEachFile` && `!applyToEach` - for each file we take
    ///    the specified count
    ///
    /// * `!applyToEachFile` && `applyToEach` - we never reset the tracker,
    ///   and we terminate once all our arguments each reach specified count
    ///
    /// * `applyToEachFile` && `applyToEach` - each file gets equal chance to
    ///   reach the number of specified args even if we end up recursing the
    ///   whole file!
    ///

    // we never reset the tracker, terminate once arg conditions are met
    else if (!applyToEachFile && applyToEach) {
      yield* transformAll(resetTracker: false).takeWhile(
        (value) => !value.reachedLimit,
      );
    }

    ///
    /// All conditions below fall under `applyToEachFile`
    ///
    /// When `applyToEachFile` is true, it is imperative to optimize
    /// transformations, saving on "time", even some few milliseconds.
    ///
    /// We interrupt current transformation and skip to next file manually.
    ///
    else if (applyToEachFile) {
      /// When `applyToEach` argument is false, we keep count per file
      var countForEachFile = <int, int>{};

      /// When `applyToEach` argument is true, we track current active file &
      /// whether we reach the limit for count for each argument and yielded the
      /// last value that triggered the match
      var currentFile = 0;

      /// We create our custom queue with all files
      var customQueue = QueueList.from(yamlQueue);

      // Setup all our variables for tracking exiting current transformation
      if (!applyToEach) {
        countForEachFile = yamlQueue.asMap().keys.fold(
          <int, int>{},
          (previousValue, element) {
            previousValue.addAll({element: 0});
            return previousValue;
          },
        );
      }

      /// Our queue will act as the reference for controlling the loop
      while (customQueue.isNotEmpty) {
        final generator = transformAll(
          resetTracker: true,
          customQueue: customQueue,
        );

        // Start transformation
        for (final match in generator) {
          ///
          /// When `applyToEach` argument is false, we break loop if count for
          /// matches generated for this file has been reached
          if (!applyToEach) {
            if (countForEachFile[match.currentFile] == count) break;

            // Increment its count if loop wasn't broken
            countForEachFile.update(match.currentFile, (value) => value + 1);
          }

          ///
          /// When `applyToEach` argument is true, we break loop if current
          /// file limit has been reached for all arguments
          else {
            if (currentFile == match.currentFile && match.reachedLimit) {
              // Yield match that triggered limit and break
              yield match;
              break;
            }
          }

          /// If generator moved on to another file, update current file.
          ///
          /// This occurs when the file has not met the threshold for any of
          /// the above conditions
          ///
          /// OR
          ///
          /// It did, and the generator continued. A generator just generates!
          if (currentFile != match.currentFile) {
            currentFile = match.currentFile;
          }

          // Always yield match
          yield match;
        }

        /// If loop was terminated, we modify custom queue and skip files
        /// that were touched. This given by:
        ///
        /// currentFile + 1, which will be our start index
        ///
        /// If by chance the loop just ended, then we'll skip all elements. This
        /// renders our custom queue empty thus controller loop will be
        /// terminated!
        ///
        currentFile += 1;

        customQueue = QueueList.from(yamlQueue.skip(currentFile));
      }
    }
  }

  @override
  Iterable<FindManagerOutput> transformAll({
    required bool resetTracker,
    QueueList<YamlMap>? customQueue,
  }) sync* {
    final localQueue = customQueue ?? QueueList.from(yamlQueue);

    do {
      // Index of current file
      final currentFile = yamlQueue.length - localQueue.length;

      // Reset tracker if not first run, since we havent completed it.
      if (localQueue.length != yamlQueue.length && resetTracker) {
        super.resetTracker();
      }

      final yamlMap = localQueue.removeFirst(); // Get file, remove from list

      /// If first run, use current yaml map to initialize.
      ///
      /// New files just set a new yaml indexer
      final finder = _setUpFinder(yamlMap); // Get finder

      // Now generate, and append current file number
      for (final match in finder.findAllSync()) {
        yield (
          currentFile: currentFile,
          data: match,
          reachedLimit: super.incrementWithMatch(match),
        );
      }
    } while (localQueue.isNotEmpty);
  }

  @override
  List<PrefillData> keysToPrefill() {
    final keys = <PrefillData>[];

    if (_keysToFind.keys.isNotEmpty) {
      keys.add((keys: _keysToFind.keys, origin: Origin.key));
    }
    if (_valuesToFind.isNotEmpty) {
      keys.add((keys: _valuesToFind, origin: Origin.value));
    }
    if (_pairsToFind.isNotEmpty) {
      keys.add((keys: _pairsToFind.entries.toList(), origin: null));
    }

    return keys;
  }

  /// Get finder for this manager
  Finder _setUpFinder(YamlMap yamlMap) {
    /// Currently just returns only the [MagicalFinder] for now
    return switch (_finderType) {
      _ => MagicalFinder.findInYaml(
          yamlMap,
          keysToFind: _keysToFind,
          valuesToFind: _valuesToFind,
          pairsToFind: _pairsToFind,
        ),
    };
  }
}
