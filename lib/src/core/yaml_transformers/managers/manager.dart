import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/managers/tranform_tracker/transform_tracker.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:yaml/yaml.dart';

part 'finder_manager.dart';
part 'replacer_manager.dart';

typedef PrefillData = ({List<dynamic> keys, Origin? origin});

abstract class TransformerManager {
  TransformerManager({
    required List<FileOutput> files,
    required Aggregator aggregator,
  })  : _aggregator = aggregator,
        _yamlQueue = QueueList.from(files.map((e) => e.fileAsMap)),
        _tracker = TransformTracker(limit: aggregator.count);

  /// A queue of all yaml maps to run a transform operation on
  final QueueList<YamlMap> _yamlQueue;

  /// A custom Aggregator for this transformer
  final Aggregator _aggregator;

  /// Tracker for keeping track of transformations made.
  final TransformTracker _tracker;

  /// Current queue with yaml files
  QueueList<YamlMap> get yamlQueue => _yamlQueue;

  /// Aggregator in use by this manager
  Aggregator get aggregator => _aggregator;

  /// Tracker in use by this manager
  TransformTracker get tracker => _tracker;

  /// Increments the count of a tracked value being transformed in the
  /// tracker using a [ String ]
  void incrementWithStrings(List<dynamic> values, {required Origin origin}) {
    _tracker.increment(values, origin: origin);
  }

  /// Increments the count of a tracked value being transformed in the
  /// tracker using a [ MatchedNodeData ] object
  ///
  /// Return true if limit is reached.
  bool incrementWithMatch(MatchedNodeData data) {
    return _tracker.incrementUsingMatch(data);
  }

  /// Get count of a value in tracker
  int getCountOfValue(dynamic value, {required Origin origin}) {
    return _tracker.getCount(value, origin: origin);
  }

  /// Resets tracker and saves current state to history
  void resetTracker() => _tracker.reset();

  /// Initializes transformer manager
  Future<void> transform();
}

/// Interface class for implementing by count. This is intended for the
/// [ FinderManager ] that does the heavy lifting (as it should). Finding
/// a match is always the tricky part!
///
/// This allows for a light & fairly straighforward implementation for
/// [ ReplacerManager ]
abstract interface class ManageByCount {
  /// Generates keys to prefill.
  ///
  /// [ FinderManager ] implements this to preset any values inside the
  /// [ TransformTracker ] ensuring we always know the count of each value
  /// instead of waiting for it to be added later.
  ///
  /// Prefilling helps tracker give the accurate status if the count needs to
  /// be within the limit.
  List<PrefillData> keysToPrefill();

  /// Transforms based a specified count of requirements.
  ///
  /// [ count ] - denotes number of values to extract
  ///
  /// [ applyToEach ] - denotes whether each unique matcher should be
  /// transformed by this count
  void transformByCount(int count, {required bool applyToEach});

  /// Transforms all
  void transformAll({required bool resetTracker});
}
