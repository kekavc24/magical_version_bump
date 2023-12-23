part of '../yaml_transformer.dart';

/// This class holds methods for indexing a yaml file down to a terminal value
/// i.e the value marking the end of a key path
///
/// Example for json:
/// ```json
/// {
///   "myRoot" : {
///      "nested" : "myValue"
///   }
/// }
/// ```
///
/// The valid Node data for this is :
///   * path (in order from root) = [ "myRoot" ]
///   * key for value = "nested"
///   * value for the key = "myValue"
///
/// Same applies for yaml file that mimics the json file as shown below :
/// ```yaml
/// myRoot:
///   nested: myValue
/// ```
///
/// All values in a list are valid terminal end points. Nested keys will be
/// marked as nested. See [ NodeData ]
///
class MagicalIndexer {
  MagicalIndexer._(this._map);

  /// Instantiate with yaml map
  MagicalIndexer.forYaml(YamlMap yamlMap) : this._(yamlMap);

  /// Instantiate with dart map
  MagicalIndexer.forDartMap(Map<dynamic, dynamic> map) : this._(map);

  /// Yaml map to search and index
  final Map<dynamic, dynamic> _map;

  Iterable<NodeData> indexYaml() sync* {
    for (final entry in _map.entries) {
      final setUpData = NodeData.fromRoot(
        key: entry.key as String,
        value: entry.value,
      );

      yield* _recursiveIndex(setUpData);
    }
  }

  /// Entry point for indexing a node. Can be called recursively.
  Iterable<NodeData> _recursiveIndex(NodeData parent) sync* {
    if (isTerminal(parent.value.rawValue)) {
      yield parent;
    } else if (parent.value.rawValue is Map<dynamic, dynamic>) {
      yield* _indexNestedMap(
        parent: parent,
        child: parent.value.rawValue as Map<dynamic, dynamic>,
        indices: [],
      );
    } else {
      yield* _indexNestedList(
        parent: parent,
        children: parent.value.rawValue as List,
        indices: [],
      );
    }
  }

  /// Recursively index a map and yield any terminal values found.
  ///
  /// A recursion on the map always resets the list of indices for any further
  /// recursive calls we may make as we are no longer in a list but a map.
  ///
  Iterable<NodeData> _indexNestedMap({
    required NodeData parent,
    required Map<dynamic, dynamic> child,
    required List<int> indices,
  }) sync* {
    // Loop all keys and values
    for (final entry in child.entries) {
      // Create new object
      final nestedData = NodeData.fromMapEntry(
        parent: parent,
        current: entry,
        indices: indices,
      );

      /// If terminal, we return it as is
      if (isTerminal(nestedData.value.rawValue)) {
        yield nestedData;
      }

      /// If not, the data is either a list or map
      ///
      /// For a list, we index the list value by value.
      ///
      else if (entry.value is List) {
        yield* _indexNestedList(
          parent: nestedData,
          children: entry.value as List,
          indices: [],
        );
      }

      // We just use this recursive function
      else {
        yield* _indexNestedMap(
          parent: nestedData,
          child: nestedData.value.rawValue as Map<dynamic, dynamic>,
          indices: [],
        );
      }
    }
  }

  /// Recursively index nested list and yield any terminal values found.
  ///
  /// A list will always generate new indices for a key, value or map,
  /// forcing all [ NodeData ] key/value to be marked as nested with indices
  /// in order from root list.
  ///
  Iterable<NodeData> _indexNestedList({
    required NodeData parent,
    required List<dynamic> children,
    required List<int> indices,
  }) sync* {
    // Loop nested children with all indexed
    for (final (index, child) in children.indexed) {
      // Update indices we have so far
      final updatedIndices = [...indices, index];

      // If we reached the end, we yield a terminal value
      if (isTerminal(child)) {
        yield NodeData.atRootTerminal(
          parent: parent,
          terminalValue: child.toString(),
          indices: updatedIndices,
        );
        continue;
      }

      // For another list, we recurse with function
      else if (child is List) {
        yield* _indexNestedList(
          parent: parent,
          children: child,
          indices: updatedIndices,
        );
        continue;
      }

      // If map, we call recursive map indexer
      yield* _indexNestedMap(
        parent: parent,
        child: child as Map<dynamic, dynamic>,
        indices: updatedIndices,
      );
    }
  }
}
