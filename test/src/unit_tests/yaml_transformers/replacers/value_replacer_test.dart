import 'package:magical_version_bump/src/core/yaml_transformers/yaml_transformer.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../../../helpers/helpers.dart';

void main() {
  final map = <String, dynamic>{
    'keyAtRoot': 'value',
    'keyWithList': ['value'],
    'keyWithListOfList': [
      {'keyInList': 'value'},
      [
        'value',
        {'keyInListOfList': 'value'},
      ],
    ],
  };

  late YamlMap yamlMap;

  /// Generated one time nodes for ease of access
  late List<NodeData> nodes;

  /// Has no notion of the underlying data. Only mutates what is presented
  /// to it
  late ValueReplacer valueReplacer;

  /// Value is the same, only predicate changes
  MatchedNodeData getMatch(bool Function(NodeData) predicate) {
    return buildMatchedNode(
      nodes,
      predicate: predicate,
      matchedValue: 'value',
    );
  }

  const defaultMapping = {'value': 'replacedValue'}; // All values are same

  setUp(() {
    yamlMap = YamlMap.wrap(map);
    nodes = MagicalIndexer.forDartMap(map).indexYaml().toList();
    valueReplacer = ValueReplacer({
      'replacedValue': ['value'],
    });
  });

  group('replaces value', () {
    test('with key at root', () {
      final match = getMatch((node) => node.precedingKeys.isEmpty);

      final output = valueReplacer.replace(yamlMap, matchedNodeData: match);

      final expectedMap = {
        'keyAtRoot': 'replacedValue',
        'keyWithList': ['value'],
        'keyWithListOfList': [
          {'keyInList': 'value'},
          [
            'value',
            {'keyInListOfList': 'value'},
          ],
        ],
      };

      expect(output.mapping, equals(defaultMapping));
      expect(output.updatedMap, equals(expectedMap));
    });

    test('in list at a key', () {
      final match = getMatch((node) => node.value.isNested());

      final output = valueReplacer.replace(yamlMap, matchedNodeData: match);

      final expectedMap = {
        'keyAtRoot': 'value',
        'keyWithList': ['replacedValue'],
        'keyWithListOfList': [
          {'keyInList': 'value'},
          [
            'value',
            {'keyInListOfList': 'value'},
          ],
        ],
      };

      expect(output.mapping, equals(defaultMapping));
      expect(output.updatedMap, equals(expectedMap));
    });

    test('with key nested in list', () {
      final match = getMatch((node) => node.key.isNested());

      final output = valueReplacer.replace(yamlMap, matchedNodeData: match);

      final expectedMap = {
        'keyAtRoot': 'value',
        'keyWithList': ['value'],
        'keyWithListOfList': [
          {'keyInList': 'replacedValue'},
          [
            'value',
            {'keyInListOfList': 'value'},
          ],
        ],
      };

      expect(output.mapping, equals(defaultMapping));
      expect(output.updatedMap, equals(expectedMap));
    });

    test('in sublist of a list at a key', () {
      final match = getMatch((node) => node.value.indices.length > 1);

      final output = valueReplacer.replace(yamlMap, matchedNodeData: match);

      final expectedMap = {
        'keyAtRoot': 'value',
        'keyWithList': ['value'],
        'keyWithListOfList': [
          {'keyInList': 'value'},
          [
            'replacedValue',
            {'keyInListOfList': 'value'},
          ],
        ],
      };

      expect(output.mapping, equals(defaultMapping));
      expect(output.updatedMap, equals(expectedMap));
    });

    test('with key nested in sublist of list', () {
      final match = getMatch((node) => node.key.indices.length > 1);

      final output = valueReplacer.replace(yamlMap, matchedNodeData: match);

      final expectedMap = {
        'keyAtRoot': 'value',
        'keyWithList': ['value'],
        'keyWithListOfList': [
          {'keyInList': 'value'},
          [
            'value',
            {'keyInListOfList': 'replacedValue'},
          ],
        ],
      };

      expect(output.mapping, equals(defaultMapping));
      expect(output.updatedMap, equals(expectedMap));
    });
  });
}
