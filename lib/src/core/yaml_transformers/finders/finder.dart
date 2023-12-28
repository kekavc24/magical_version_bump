import 'package:magical_version_bump/src/core/yaml_transformers/counter/transform_counter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

part 'custom_tracker.dart';
part 'value_finder.dart';

typedef FinderOutput = ({bool reachedLimit, MatchedNodeData data});

/// Abstract class for looking for values in yaml maps
///
/// Both [ValueFinder] & ValueSearcher will extend this
abstract base class Finder {
  Finder({
    required this.indexer,
    bool? saveCounterToHistory,
  }) : _saveCounterToHistory = saveCounterToHistory ?? true;

  /// An indexer that recurses through the map and spits out terminal
  /// values sequentially.
  MagicalIndexer indexer;

  /// Indicates whether to save the current counter to history when a
  /// map to be indexed is swapped
  final bool _saveCounterToHistory;

  /// A tracker to keep track of aggregated values. May be null if not
  /// initialized yet.
  MatchCounter? counter;

  /// Adds limit to [MatchCounter] only when [Finder.findAllSync] or
  /// [Finder.findByCountSync] is called.
  ///
  /// Will always be called if this finder's `saveCounterToHistory` was set
  /// to false. And is reused to by swapping map via [Finder.swapMap].
  void _setUpCounter(int? count) {
    // If history was false, setup again to ensure count accuracy.
    if (counter == null || counter != null && !_saveCounterToHistory) {
      counter = MatchCounter(limit: count);
    }
  }

  /// Prefill counter with values to find for accurate counting
  ///
  /// All subclasses must override this method.
  void _prefillCounter();

  /// Swaps the map currently being indexed by the [MagicalIndexer] tied to
  /// this [Finder] and returns the current counter state. Throws an error if
  /// [MatchCounter] is still null when swapping.
  ///
  /// May be null if [Finder.find] or [Finder.findByCountSync] or
  /// [Finder.findAllSync] were never called at all.
  ///
  /// Try swapping manually or calling the methods specified above if you want
  /// to avoid the error.
  MatchCounter? swapMap(Map<dynamic, dynamic> map, {int? cursor}) {
    indexer.map = map;

    /// If [_saveCounterToHistory] is true, a cursor must be provided
    if (_saveCounterToHistory) {
      if (cursor == null || counter == null) {
        throw MagicalException(
          violation: 'Neither cursor/counter should be null',
        );
      }
      counter!.reset(cursor: cursor);
    }

    return counter;
  }

  /// An on-demand generator that is indexing a map.
  Iterable<NodeData> get _generator => indexer.indexYaml();

  /// Default entry point for finding values. Finds values based on
  /// [AggregateType] specified.
  ///
  /// Internally uses [Finder.findByCountSync] & [Finder.findAllSync] based on
  /// [AggregateType].
  ///
  /// If [AggregateType.all], count is ignored. For any other [AggregateType],
  /// count `MUST` be specified.
  ///
  Iterable<FinderOutput> find({
    required AggregateType aggregateType,
    required bool applyToEach,
    int? count,
  }) sync* {
    // For AggregateType.all
    if (aggregateType == AggregateType.all) {
      yield* findAllSync();
    } else {
      // Count must be valid going forward.
      if (count == null || count < 0) {
        throw MagicalException(
          violation: 'Count must be a value equal/greater than 1',
        );
      }

      yield* findByCountSync(
        count,
        applyToEach: applyToEach,
      );
    }
  }

  /// Find by count synchronously, value by value
  Iterable<FinderOutput> findByCountSync(
    int count, {
    required bool applyToEach,
  }) sync* {
    /// Incase this method is called directly instead of [Finder.find]
    _setUpCounter(count);

    // Prefill tracker with everything being tracked.
    _prefillCounter();

    /// If we are not applying to each argument. Take count as is
    if (!applyToEach) {
      yield* findAllSync(prefilledCounter: true).take(count);
    }

    /// If not take as until limit is reached
    else {
      FinderOutput? lastValue;

      yield* findAllSync(prefilledCounter: true).takeWhile(
        (value) {
          /// Last value may be ignored. Last value itself causes the limit
          /// to be reached. The limit is never reaches before.
          if (value.reachedLimit) lastValue = value;
          return !value.reachedLimit;
        },
      );

      if (lastValue != null) yield lastValue!;
    }
  }

  /// Find all values
  List<MatchedNodeData> findAll() =>
      findAllSync().toList().map((output) => output.data).toList();

  /// Find all matches synchronously
  Iterable<FinderOutput> findAllSync({bool prefilledCounter = false}) sync* {
    /// Incase this method is called indirectly via [Finder.find]
    ///
    /// [Finder.findByCount] always prefills the counter thus always
    /// sets up the [MatchCounter]
    if (!prefilledCounter) _setUpCounter(null);

    for (final nodeData in _generator) {
      // Generate matched node data
      final matchedNodeData = generateMatch(nodeData);

      // We only yield it if it is valid
      if (matchedNodeData.isValidMatch()) {
        yield (
          data: matchedNodeData,
          reachedLimit: counter!.incrementUsingMatch(matchedNodeData),
        );
      }
    }
  }

  /// Generates a matched based on internal functionality
  MatchedNodeData generateMatch(NodeData nodeData);
}
