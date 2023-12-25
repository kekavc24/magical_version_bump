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
  Finder({required MagicalIndexer? indexer}) : _indexer = indexer;

  /// An indexer that recurses through the [ YamlMap ] and spits out terminal
  /// values sequentially.
  final MagicalIndexer? _indexer;

  /// A tracker to keep track of aggregated values. May be null if not
  /// initialized yet.
  MatchCounter? counter;

  /// Adds limit to [MatchCounter] only when [Finder.find] is called
  void _setUp(int? count) {
    counter = MatchCounter(limit: count);
  }

  /// Prefill counter with values to find for accurate counting
  ///
  /// All subclasses must override this method.
  void _prefillCounter();

  /// An on-demand generator that is indexing the file.
  Iterable<NodeData> get _generator {
    if (_indexer == null) {
      throw MagicalException(violation: 'Magical Indexer cannot be null');
    }

    return _indexer!.indexYaml();
  }

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
    _setUp(count); // Set up counter ready for use

    // For AggregateType.all
    if (aggregateType == AggregateType.all) {
      yield* findAllSync();
    }

    // Count must be valid going forward. First &
    if (count == null || count < 0) {
      throw MagicalException(
        violation: 'Count must be a value equal/greater than 1',
      );
    }

    yield* findByCountSync(count, applyToEach: applyToEach);
  }

  /// Find by count synchronously, value by value
  Iterable<FinderOutput> findByCountSync(
    int count, {
    required bool applyToEach,
  }) sync* {
    /// Incase this method is called directly instead of [Finder.find]
    if (counter == null) _setUp(count);

    // Prefill tracker with everything being tracked.
    _prefillCounter();

    /// If we are not applying to each argument. Take count as is
    if (!applyToEach) {
      yield* findAllSync().take(count);
    }

    /// If not take as until limit is reached
    else {
      yield* findAllSync().takeWhile((value) => !value.reachedLimit);
    }
  }

  /// Find all values
  List<MatchedNodeData> findAll() =>
      findAllSync().toList().map((output) => output.data).toList();

  /// Find all matches synchronously
  Iterable<FinderOutput> findAllSync() sync* {
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
