part of 'yaml_transformer.dart';

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
  MagicalIndexer(this._yamlMap);

  /// Instantiate with yaml
  factory MagicalIndexer.forYaml(YamlMap yamlMap) => MagicalIndexer(yamlMap);

  /// Yaml map to search and index
  final YamlMap _yamlMap;

  /// Trigger for indexing to start
  Iterable<NodeData> indexYaml() sync* {
    for (final entry in _yamlMap.entries) {
      final setUpData = NodeData.fromYaml(
        entry.key as String,
        const [],
        entry.value,
      );

      yield* _recursiveIndex(setUpData);
    }
  }

  /// Entry point for indexing a node. Can be called recursively.
  Iterable<NodeData> _recursiveIndex(NodeData dataInYaml) sync* {
    if (!_isTerminal(dataInYaml.data)) {
      final indexingStream = dataInYaml.data is Map<dynamic, dynamic>
          ? _indexMap(dataInYaml, dataInYaml.data as Map<dynamic, dynamic>)
          : _indexNestedInList(dataInYaml, dataInYaml.data as List);

      yield* indexingStream;
    } else {
      yield dataInYaml;
    }
  }

  /// Recursively index a map and yield any terminal value found.
  Iterable<NodeData> _indexMap(
    NodeData parent,
    Map<dynamic, dynamic> nestedMap,
  ) sync* {
    // Loop all keys and values
    for (final entry in nestedMap.entries) {
      // Create new object
      final nestedData = NodeData.entryFromPreceding(entry, parent);

      /// If terminal, we add it to the stream
      if (_isTerminal(nestedData.data)) {
        yield nestedData;
      }

      /// If not, the data is either a list or map.
      ///
      /// For a map, we just call this function again
      ///
      /// For a list, we index the list value by value
      else if (entry.value is List) {
        yield* _indexNestedInList(
          nestedData,
          entry.value as List,
        );
      }

      // We just use this recursive function as stream
      else {
        yield* _recursiveIndex(nestedData);
      }
    }
  }

  /// Recursively index nested list and yield any terminal values found.
  Iterable<NodeData> _indexNestedInList(
    NodeData parent,
    List<dynamic> nestedChildren,
  ) sync* {
    for (final child in nestedChildren) {
      if (child is String) {
        yield NodeData.terminalEntry(child, parent);
        continue;
      }

      // For json, we may encounter a list nested within a list
      if (child is List) {
        // Use current parent as list
        for (final indexedChild in _indexNestedInList(parent, child)) {
          yield NodeData.markAsNested(indexedChild);
        }
        continue;
      }

      // If not, we index it further
      for (final entry in (child as YamlMap).entries) {
        // Create an object,
        final nested = NodeData.entryFromPreceding(entry, parent);

        // We recursively index it further
        yield* _recursiveIndex(nested);
      }
    }
  }

  /// Check if a value is terminal. A terminal value can ONLY be null or a
  /// string.
  bool _isTerminal(dynamic data) => data is String || data == null;
}
