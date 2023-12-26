import 'package:collection/collection.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/console_printer/console_printer.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/counter/transform_counter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:yaml/yaml.dart';

part 'finder_manager.dart';
part 'replacer_manager.dart';
part 'custom_tracker.dart';

typedef ManagerCounter = Counter<int>;

abstract class TransformerManager {
  TransformerManager({
    required List<FileOutput> files,
    required Aggregator aggregator,
    ConsolePrinter? printer,
  })  : _aggregator = aggregator,
        _printer = printer ?? ConsolePrinter(format: aggregator.viewFormat),
        _yamlQueue = QueueList.from(files.map((e) => e.fileAsMap)),
        _managerCounter = ManagerCounter();

  /// A queue of all yaml maps to run a transform operation on
  final QueueList<YamlMap> _yamlQueue;

  /// A custom Aggregator for this transformer
  final Aggregator _aggregator;

  /// A console printer for each manager that will is called by each
  /// command's handler to print to console all aggregated info
  final ConsolePrinter _printer;

  /// Tracker for keeping track of transformations made.
  final ManagerCounter _managerCounter;

  /// Current queue with yaml files
  QueueList<YamlMap> get yamlQueue => _yamlQueue;

  /// Aggregator in use by this manager
  Aggregator get aggregator => _aggregator;

  /// Tracker in use by this manager
  ManagerCounter get counter => _managerCounter;


  ConsolePrinter get printer => _printer;

  /// Adds a specified file index to a [Counter] in this manager
  void _incrementFileIndex(int fileIndex) {
    return _managerCounter.increment([fileIndex], origin: Origin.custom);
  }

  /// Initializes transformer manager
  Future<void> transform();
}
