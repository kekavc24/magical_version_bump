import 'package:magical_version_bump/src/core/yaml_transformers/data/pair_definition/custom_pair_type.dart';
import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('indexer for map', () {
    test('index map with one key and value', () {
      final map = {'key': 'value'};

      // Index it
      final node = MagicalIndexer.forDartMap(map).index().first;

      expect(node.toString(), 'key/value');
    });

    test('index map with multiple keys', () {
      final map = {'key': 'value', 'anotherKey': 'value'};

      // Index & get paths
      final nodes = MagicalIndexer.forDartMap(map)
          .index()
          .toList()
          .map((node) => node.toString());

      expect(nodes, equals(['key/value', 'anotherKey/value']));
    });

    test('index map with map nested at a key', () {
      final map = {
        'key': {'nestedKey': 'value'},
      };

      // Index it
      final node = MagicalIndexer.forDartMap(map).index().first;

      expect(node.toString(), 'key/nestedKey/value');
    });

    test('index map with map nested at multiple keys', () {
      final map = {
        'key': {'nestedKey': 'value'},
        'anotherKey': {'nestedKey': 'value'},
      };

      // Index it
      final nodes = MagicalIndexer.forDartMap(map)
          .index()
          .toList()
          .map((node) => node.toString());

      expect(
        nodes,
        equals(['key/nestedKey/value', 'anotherKey/nestedKey/value']),
      );
    });
  });

  group('indexer for map with list', () {
    test('index map with list with correct indices for terminal nodes', () {
      final map = {
        'key': ['value', 'anotherValue'],
      };

      final nodes = MagicalIndexer.forDartMap(map).index().toList();

      // Expected nodes
      final expectedNodes = [
        NodeData.skeleton(
          precedingKeys: const [],
          key: createPair<Key>(value: 'key'),
          value: createPair<Value>(value: 'value', indices: [0]),
        ),
        NodeData.skeleton(
          precedingKeys: const [],
          key: createPair<Key>(value: 'key'),
          value: createPair<Value>(value: 'anotherValue', indices: [1]),
        ),
      ];

      expect(nodes, equals(expectedNodes));
    });

    test('index map in list with correct indices for terminal nodes', () {
      final map = {
        'key': [
          {'nestedKey': 'value'},
        ],
      };

      final node = MagicalIndexer.forDartMap(map).index().first;

      // Key will be at index 0. Index goes to key rather than value
      final expectedNode = NodeData.skeleton(
        precedingKeys: [createPair<Key>(value: 'key')],
        key: createPair<Key>(value: 'nestedKey', indices: [0]),
        value: createPair<Value>(value: 'value'),
      );

      expect(node, equals(expectedNode));
    });

    test('index list in list with correct indices for terminal nodes', () {
      final map = {
        'key': [
          ['value'],
        ],
      };

      final node = MagicalIndexer.forDartMap(map).index().first;

      // Index goes to value rather than key
      final expectedNode = NodeData.skeleton(
        precedingKeys: const [],
        key: createPair<Key>(value: 'key'),

        // Will be 2 indices deep from nearest key
        value: createPair<Value>(value: 'value', indices: [0, 0]),
      );

      expect(node, equals(expectedNode));
    });

    test('index anything encountered in list with correct indices ', () {
      final map = {
        'key': [
          'value',
          [
            {'nested': 'value'},
            'nestedValue',
            ['deeplyNestedValue'],
          ],
        ],
      };

      final rootKey = createPair<Key>(value: 'key');

      final nodes = MagicalIndexer.forDartMap(map).index().toList();

      // Expected nodes
      final expectedNodes = [
        NodeData.skeleton(
          precedingKeys: const [],
          key: rootKey,
          value: createPair<Value>(value: 'value', indices: [0]),
        ),

        // Nested list at index 1, key at index 0. Inherits index from list
        NodeData.skeleton(
          precedingKeys: [rootKey],
          key: createPair<Key>(value: 'nested', indices: [1, 0]),
          value: createPair<Value>(value: 'value'),
        ),

        // Nested list index = 1, value at index 1.
        // Nearest key is the root key
        NodeData.skeleton(
          precedingKeys: const [],
          key: rootKey,
          value: createPair<Value>(value: 'nestedValue', indices: [1, 1]),
        ),

        // Nested list index = 1, next list index = 2, value at index 0.
        // Nearest key is the root key. Also inherits index of list
        NodeData.skeleton(
          precedingKeys: const [],
          key: rootKey,
          value: createPair<Value>(
            value: 'deeplyNestedValue',
            indices: [1, 2, 0],
          ),
        ),
      ];

      expect(nodes, equals(expectedNodes));
    });
  });

  group('indexer for yaml', () {
    test('indexes simple yaml string', () {
      const yaml = 'key: value';

      final node = MagicalIndexer.forDynamicValue(
        loadYaml(yaml),
      ).index().toList().first;

      expect(node.toString(), 'key/value');
    });

    test('indexes fairly complex yaml string', () {
      const yaml = '''
        root: value
        key:
          - first
          - second:
              - deep
              - deeper
          - third
      ''';

      final nodePaths = MagicalIndexer.forDynamicValue(
        loadYaml(yaml),
      ).index().toList().map((e) => e.toString());

      final expectedPaths = [
        'root/value',
        'key/first',
        'key/second/deep',
        'key/second/deeper',
        'key/third',
      ];

      expect(nodePaths, equals(expectedPaths));
    });
  });
}
