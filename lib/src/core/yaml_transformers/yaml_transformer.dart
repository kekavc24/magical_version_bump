import 'package:magical_version_bump/src/utils/exceptions/command_exceptions.dart';
import 'package:magical_version_bump/src/utils/extensions/extensions.dart';
import 'package:magical_version_bump/src/utils/typedefs/typedefs.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

part 'yaml_indexer.dart';
part 'yaml_finder.dart';
part 'data/matched_node_data.dart';
part 'data/node_data.dart';

/// Interface class to find by count
abstract interface class Finder {
  /// Find first value
  MatchedNodeData? findFirst();

  /// Find by count. May find a number less than that provided
  List<MatchedNodeData> findByCount(int count);

  /// Find by count synchronously, value by value
  Iterable<MatchedNodeData> findByCountSync(int count);

  /// Find all values
  List<MatchedNodeData> findAll();

  /// Find all synchronously, value by value
  Iterable<MatchedNodeData> findAllSync();
}

/// Interface class to replace a value in a yaml/json file
abstract interface class Replacer {
  /// Replace first matching value
  void replaceFirst();

  /// Replace based on provided count. May replace a number less than that
  /// provided
  void replaceByCount(int count);

  /// Replace all values
  void replaceAll();
}
