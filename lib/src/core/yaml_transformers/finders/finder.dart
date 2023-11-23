import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:magical_version_bump/src/utils/enums/enums.dart';
import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

part 'value_finder.dart';

/// Abstract class for looking for values in yaml maps
///
/// Both [MagicalFinder] & MagicalSearcher will extend this
abstract class Finder {
  Finder({
    required this.indexer,
    this.keysToFind,
    this.valuesToFind,
    this.pairsToFind,
  });

  /// An indexer that recurses through the [ YamlMap ] and spits out terminal
  /// values sequentially.
  final MagicalIndexer? indexer;

  final KeysToFind? keysToFind;

  final ValuesToFind? valuesToFind;

  final PairsToFind? pairsToFind;

  // Non-nullable values
  KeysToFind get _keysToFind => keysToFind!;
  ValuesToFind get _valuesToFind => valuesToFind!;
  PairsToFind get _pairsToFind => pairsToFind!;

  /// An on-demand generator that is indexing the file
  Iterable<NodeData> get _generator {
    if (indexer == null) {
      throw MagicalException(violation: 'Magical Indexer cannot be null');
    }

    return indexer!.indexYaml();
  }

  /// Find first value
  MatchedNodeData? findFirst() => findByCount(1).firstOrNull;

  /// Find by count. May find a number less than that provided
  List<MatchedNodeData> findByCount(int count) =>
      findByCountSync(count).toList();

  /// Find by count synchronously, value by value
  Iterable<MatchedNodeData> findByCountSync(int count) sync* {
    if (count < 1) {
      throw MagicalException(
        violation: 'Count must be a value equal/greater than 1',
      );
    }

    yield* findAllSync().take(count);
  }

  /// Find all values
  List<MatchedNodeData> findAll() => findAllSync().toList();

  /// Find all synchronously, value by value
  Iterable<MatchedNodeData> findAllSync() sync* {
    for (final nodeData in _generator) {
      // Generate matched node data
      final matchedNodeData = generateMatch(nodeData);

      // We only yield it if it is valid
      if (matchedNodeData.isValidMatch()) {
        yield matchedNodeData;
      }
    }
  }

  /// Generates a based on internal functionality
  MatchedNodeData generateMatch(NodeData nodeData);
}
