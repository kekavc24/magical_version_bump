import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/console_printer/console_printer.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/counter/generic_counter.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

export 'finder_manager/finder_manager.dart';
export 'replacer_manager/replacer_manager.dart';

abstract class TransformerManager {
  TransformerManager({
    required List<FileOutput> files,
    required Aggregator aggregator,
    ConsolePrinter? printer,
  })  : _aggregator = aggregator,
        _printer = printer ?? ConsolePrinter(format: aggregator.viewFormat),
        _yamlQueue = QueueList.from(files.map((e) => e.fileAsMap)),
        _managerCounter = Counter<int, int>();

  /// A queue of all yaml maps to run a transform operation on
  final QueueList<YamlMap> _yamlQueue;

  /// A custom Aggregator for this transformer
  final Aggregator _aggregator;

  /// A console printer for each manager that will is called by each
  /// command's handler to print to console all aggregated info
  final ConsolePrinter _printer;

  /// Tracker for keeping track of transformations made for each file
  final Counter<int, int> _managerCounter;

  /// Current queue with yaml files
  QueueList<YamlMap> get yamlQueue => _yamlQueue;

  /// Aggregator in use by this manager
  Aggregator get aggregator => _aggregator;

  /// Tracker in use by this manager
  Counter<int, int> get counter => _managerCounter;

  ConsolePrinter get printer => _printer;

  /// Adds a specified file index to a [Counter] in this manager
  @protected
  void incrementFileIndex(int fileIndex) {
    return _managerCounter.increment([fileIndex], origin: Origin.custom);
  }

  /// Initializes transformer manager
  Future<void> transform();
}
