import 'package:magical_version_bump/src/core/yaml_transformers/formatter/formatter.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/trackers/counter/generic_counter.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

export 'finder_manager/finder_manager.dart';
export 'replacer_manager/replacer_manager.dart';

enum ManagerProgress { findingMatches, replacingValues }

abstract class TransformerManager<FormatterOutputT> {
  TransformerManager({
    required this.fileQueue,
    required this.aggregator,
    required this.formatter,
    required this.logger,
  });

  /// A queue of all yaml/ordinary maps to run a transform operation on
  final List<Map<dynamic, dynamic>> fileQueue;

  /// A custom Aggregator for this transformer
  final Aggregator aggregator;

  /// Tracker for keeping track of transformations made for each file
  final managerCounter = Counter<int, int>();

  /// Path formatter for tree like format
  final NodePathFormatter<FormatterOutputT> formatter;

  final Logger? logger;

  /// Adds a specified file index to a [Counter] in this manager
  @protected
  void incrementFileIndex(int fileIndex) {
    return managerCounter.increment([fileIndex], origin: Origin.custom);
  }

  @protected
  Progress showProgress(ManagerProgress managerProgress, {String? info}) {
    return switch (managerProgress) {
      ManagerProgress.findingMatches => logger!.progress(
          info ?? 'Finding matches',
        ),
      ManagerProgress.replacingValues => logger!.progress('Replacing matches')
    };
  }

  /// Initializes transformer manager
  Future<void> transform();
}
